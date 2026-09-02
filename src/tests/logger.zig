const std = @import("std");

var run_id: ?[16]u8 = null;


fn getRunId(io: std.Io) []const u8 {
    if (run_id == null) {
        const timestamp = std.Io.Clock.real.now(io).toMilliseconds();
        const hash = std.hash.Wyhash.hash(
            0,
            std.mem.asBytes(&timestamp),
        );

        var id: [16]u8 = undefined;
        _ = std.fmt.bufPrint(&id, "{x:0>16}", .{hash}) catch unreachable;

        run_id = id;
    }

    return &run_id.?;
}

pub fn TestCtx(scope: []const u8) type {
    return struct {
        io: std.Io,
        test_name: []const u8,
        dir: std.Io.Dir,

        log_buf: [1024]u8 = undefined,

        pub fn init(io: std.Io, test_name: []const u8) !@This() {
            var cwd = std.Io.Dir.cwd();
            var buf: [128]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "tests/{s}/{s}/{s}", .{getRunId(io), scope, test_name});
            try cwd.createDirPath(io, path);
            const dir = try cwd.openDir(io, path, .{});
            return @This() {
                .io = io,
                .test_name = test_name,
                .dir = dir,
            };
        }

        pub fn deinit(self: *@This()) void {
            _ = self;
        }

        pub fn logger(self: *@This()) !std.Io.File.Writer {
            return self.file("log.txt", &self.log_buf);
        }

        pub fn file(self: @This(), filename: []const u8, buf: []u8) !std.Io.File.Writer {
            var f = try self.dir.createFile(self.io, filename, .{
                .truncate = false,
                .read = true,
            });
            return f.writer(self.io, buf);
        }

        pub fn copyToTestDir(self: @This(), filename: []const u8, content: []const u8) !void {
            try self.dir.writeFile(self.io, .{
                .sub_path = filename,
                .data = content,
            });
        }

        pub fn begin(writer: *std.Io.File.Writer, group: []const u8) !void {
            try writer.interface.print("::group::{s}\n", .{group});
            try writer.interface.flush();
        }

        pub fn end(writer: *std.Io.File.Writer) !void {
            try writer.interface.print("::endgroup::\n", .{});
            try writer.interface.flush();
        }

        pub fn log(writer: *std.Io.File.Writer, comptime fmt: []const u8, args: anytype) !void {
            try writer.interface.print(fmt, args);
            try writer.interface.flush();
        }

        pub fn expectFilesEqual(self: @This(), expected: []const u8, actual: []const u8) !void {
            const expected_data = try self.dir.readFileAlloc(
                self.io,
                expected,
                std.testing.allocator,
                .unlimited,
            );
            defer std.testing.allocator.free(expected_data);

            const actual_data = try self.dir.readFileAlloc(
                self.io,
                actual,
                std.testing.allocator,
                .unlimited,
            );
            defer std.testing.allocator.free(actual_data);

            try std.testing.expectEqualStrings(expected_data, actual_data);
        }
    };
}
