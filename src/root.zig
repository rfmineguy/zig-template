//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
pub const Template = @import("template.zig").Template;

test {
    @import("std").testing.refAllDecls(@This());
}
