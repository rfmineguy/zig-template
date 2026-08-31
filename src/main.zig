const std = @import("std");
const Io = std.Io;

const Template = @import("template.zig").Template;

const zig_template = @import("zig_template");

pub fn main(init: std.process.Init) !void {
    const row = @embedFile("./examples/row.htpl");
    const row_t = try Template.load(row, init.io, init.arena);

    const login = @embedFile("./examples/row.htpl");
    var login_t = try Template.load(login, init.io, init.arena);
    try login_t.set("username", .{ .Value = "riley" });

    const index = @embedFile("./examples/index.htpl");
    var index_t = try Template.load(index, init.io, init.arena);
    try index_t.set("header", .{ .Value = "Hi" });
    try index_t.set("rows", .{ .Embed = login });
    try index_t.set("header", .{ .Value = "Header" });
    try index_t.set("some-class", .{ .Value = "card" });

    try row_t.set("something", .{ .Value = "blooger" });
}
