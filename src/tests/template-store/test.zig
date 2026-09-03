const std = @import("std");
const testing = std.testing;
const zt = @import("zt");
const TestCtxFn = @import("tests").TestCtx;

const TestCtx = TestCtxFn("template-store");
test "load into store" {
    var ctx = try TestCtx.init(std.testing.io, "load into store");
    defer ctx.deinit();
    var logger = try ctx.logger();
    var store = zt.TemplateStore.init(std.testing.io, std.testing.allocator);
    defer store.deinit();

    {
        try TestCtx.begin(&logger, "load templates into store");
        defer TestCtx.end(&logger) catch {};

        _ = try store.load(@embedFile("./data_template.htpl"), "data_template");
        try TestCtx.log(&logger, "  loaded ./data_template.htpl as 'data_template'", .{});

        _ = try store.load(@embedFile("./index.htpl")        , "index");
        try TestCtx.log(&logger, "  loaded ./index.htpl as 'index'", .{});

        _ = try store.load(@embedFile("./login.htpl")        , "login");
        try TestCtx.log(&logger, "  loaded ./login.htpl as 'login'", .{});
    }

    {
        try TestCtx.begin(&logger, "check store for loaded templates");
        defer TestCtx.end(&logger) catch {};

        try testing.expect(store.get("data_template") != null);
        try TestCtx.log(&logger, "  found 'data_template'", .{});

        try testing.expect(store.get("index") != null);
        try TestCtx.log(&logger, "  found 'index'", .{});

        try testing.expect(store.get("login") != null);
        try TestCtx.log(&logger, "  found 'login'", .{});
    }
}
