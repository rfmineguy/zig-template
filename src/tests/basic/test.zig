const std = @import("std");
const testing = std.testing;
const zt = @import("zt");
const TestCtxFn = @import("tests").TestCtx;

const TestCtx = TestCtxFn("basic");
test "load" {
    var ctx = try TestCtx.init(std.testing.io, "load");
    defer ctx.deinit();
    var logger = try ctx.logger();

    {
        try TestCtx.begin(&logger, "load ./template.htpl");
        defer TestCtx.end(&logger) catch {};
        const tpl = @embedFile("./template.htpl");
        var tpl_ = try zt.Template.load(tpl, testing.io, testing.allocator);
        defer tpl_.unload();
        var it = tpl_.slots_map.iterator();
        while (it.next()) |v| {
            try TestCtx.log(&logger, "{s}: {any}", .{v.key_ptr.*, v.value_ptr.*});
        }
    }
}

test "set" {
    var ctx = try TestCtx.init(std.testing.io, "set");
    defer ctx.deinit();
    var logger = try ctx.logger();

    {
        try TestCtx.begin(&logger, "set missing .some-class");
        defer TestCtx.end(&logger) catch {};

        const row = @embedFile("./template.htpl");
        var index = try zt.Template.load(row, testing.io, testing.allocator);
        defer index.unload();

        try testing.expectError(error.NoSlotWithId, index.set("adf", .{ .String = "hello" }));
        try index.set(".some-class", .{ .String = "Hello" });
    }
}

test "generate" {
    var ctx = try TestCtx.init(std.testing.io, "generate");
    defer ctx.deinit();
    var logger = try ctx.logger();
    defer logger.flush() catch {};
    defer logger.file.close(std.testing.io);

    {
        const index = @embedFile("./template.htpl");
        var index_t = try zt.Template.load(index, testing.io, testing.allocator);
        defer index_t.unload();

        {
            try TestCtx.begin(&logger, "generate ./template.htpl (see output aritifact)");
            defer TestCtx.end(&logger) catch {};

            try TestCtx.log(&logger, "  generating file...\n", .{});
            defer TestCtx.log(&logger, "  generated file...\n", .{}) catch {};

            var buf: [1024]u8 = undefined;
            var writer = try ctx.file("template.generated.html", &buf);
            defer writer.file.close(testing.io);
            defer writer.flush() catch {};
            try index_t.generate(&writer.interface);
        }
    }
}

test "generate w/ data" {
    var ctx = try TestCtx.init(std.testing.io, "generate_w_data");
    defer ctx.deinit();
    var logger = try ctx.logger();
    defer logger.flush() catch {};
    defer logger.file.close(std.testing.io);

    const User = struct {
        name: []const u8,
        age: u32,
    };

    const user: User = .{
        .name = "Someone",
        .age = 13,
    };

    const index = @embedFile("./template.htpl");
    var index_t = try zt.Template.load(index, testing.io, testing.allocator);
    defer index_t.unload();

    const login = @embedFile("./data_template.htpl");
    var login_t = try zt.Template.load(login, testing.io, testing.allocator);
    defer login_t.unload();

    try login_t.set(".username", .{ .String = user.name });
    try login_t.set(".age",      .{ .Number = user.age });
    try index_t.set(".rows",     .{ .Embed = &login_t });

    try index_t.set(".header",   .{ .String = "Hello" });
    try index_t.set(".some-content", .{ .String = "Content" });
    
    try TestCtx.begin(&logger, "generate ./template.htpl with embed ./data_template.htpl (see output artifact)");
    defer TestCtx.end(&logger) catch {};

    {
        var buf: [1024]u8 = undefined;
        var writer = try ctx.file("template.actual.generate_w_data.html", &buf);
        defer writer.file.close(testing.io);
        defer writer.flush() catch {};
        try index_t.generate(&writer.interface);
    }

    try ctx.copyToTestDir("template.expected.generate_w_data.html", @embedFile("./template.expected.generate_w_data.html"));

    ctx.expectFilesEqual("template.expected.generate_w_data.html", "template.actual.generate_w_data.html") catch {
        try TestCtx.log(&logger, "  generated and expected files do not match", .{});
        return error.MismatchedOutputs;
    };
}
