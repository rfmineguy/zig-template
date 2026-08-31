const std = @import("std");
const Io = std.Io;

const Template = @import("template.zig").Template;

const zig_template = @import("zig_template");

pub fn main(init: std.process.Init) !void {
    // const row = @embedFile("./examples/row.htpl");
    // const row_t = try Template.load(row, init.io, init.arena.allocator());

    const User = struct {
        name: []const u8,
        age: u32,
    };

    const user: User = .{
        .name = "Someone",
        .age = 13,
    };
    const index = @embedFile("./templates/index.htpl");
    var index_t = try Template.load(index, init.io, init.gpa);
    defer index_t.unload();

    const login = @embedFile("./templates/login.htpl");
    var login_t = try Template.load(login, init.io, init.gpa);
    defer login_t.unload();

    try login_t.set(".username", .{ .String = user.name });
    try login_t.set(".age",      .{ .Number = user.age });
    try index_t.set(".rows",     .{ .Embed = &login_t });

    var buf: [1024]u8 = undefined;
    var writer = std.Io.File.stdout().writer(init.io, &buf);
    try index_t.generate(&writer.interface);
    try writer.flush();

    // try row_t.set(".something", .{ .String = "blooger" });
}
