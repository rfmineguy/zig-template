//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
pub const Template = @import("template.zig").Template;
pub const TemplateStore = @import("template.zig").TemplateStore;

test {
    @import("std").testing.refAllDecls(@This());
}
