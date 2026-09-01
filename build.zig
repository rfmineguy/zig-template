const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("zig_template", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "zig_template",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zig_template", .module = mod },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const test_mod = b.addModule("tests", .{
        .root_source_file = b.path("src/tests/logger.zig"),
        .target = target,
        .optimize = optimize,
    });

    const basic_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/tests/basic/test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{
                    .name = "zt",
                    .module = mod,
                },
                .{
                    .name = "tests",
                    .module = test_mod,
                }
            },
        }),
    });
    
    basic_tests.root_module.addIncludePath(b.path("src/tests/basic"));
    
    const run_basic = b.addRunArtifact(basic_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_basic.step);
}
