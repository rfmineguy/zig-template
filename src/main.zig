const std = @import("std");
const Io = std.Io;

const Template = @import("template.zig").Template;

const zig_template = @import("zig_template");

pub fn main(init: std.process.Init) !void {
    const row = @embedFile("./examples/row.htpl");
    const row_t = try Template.load(row, init.io, init.arena.allocator());

    const login = @embedFile("./examples/row.htpl");
    var login_t = try Template.load(login, init.io, init.arena.allocator());
    try login_t.set(".username", .{ .String = "riley" });

    const index = @embedFile("./examples/index.htpl");
    var index_t = try Template.load(index, init.io, init.arena.allocator());
    try index_t.set(".header", .{ .String = "Hi" });
    try index_t.set(".rows", .{ .Embed = &login_t });
    try index_t.set(".header", .{ .String = "Header" });
    try index_t.set(".some-class", .{ .String = "card" });

    try row_t.set(".something", .{ .String = "blooger" });
}
