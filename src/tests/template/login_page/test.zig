const std = @import("std");
const testing = std.testing;
const zt = @import("zt");
const TestCtxFn = @import("tests").TestCtx;

const TestCtx = TestCtxFn("template/login_page");
test "generate" {
    var ctx = try TestCtx.init(std.testing.io, "load");
    defer ctx.deinit();
    var logger = try ctx.logger();

    {
        try TestCtx.begin(&logger, "fill out template (login.htpl)");
        defer TestCtx.end(&logger) catch {};
        var tpl = try zt.Template.load(@embedFile("./login.htpl"), testing.io, testing.allocator);
        defer tpl.unload();

        try tpl.set(".username", .{ .String = "rfmineguy" });
        try tpl.set(".roomid", .{ .Number = 134 });

        var buf: [1024]u8 = undefined;
        var writer = try ctx.file("login.generated.html", &buf);
        defer writer.file.close(testing.io);
        defer writer.flush() catch {};

        var it = tpl.slots_map.iterator();
        while (it.next()) |slot| {
            try TestCtx.log(&logger, "{s}: {any}\n", .{slot.key_ptr.*, slot.value_ptr.*});
        }

        try tpl.generate(&writer.interface);
    }
}
