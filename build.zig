const std = @import("std");

const TestCreateOptions = struct {
    path: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    zt_mod: *std.Build.Module,
    test_mod: *std.Build.Module,
};

fn create_test(b: *std.Build, options: TestCreateOptions) *std.Build.Step.Compile {
    return b.addTest(.{
        .root_module = b.createModule(.{
        .root_source_file = b.path(options.path),
        .target = options.target,
        .optimize = options.optimize,
        .imports = &.{
            .{
                .name = "zt",
                .module = options.zt_mod,
            },
            .{
                .name = "tests",
                .module = options.test_mod,
            }
        },
    })});
}

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

    const tests = create_test(b, .{
        .path = "src/tests/tests.zig",
        .test_mod = test_mod,
        .zt_mod = mod,
        .optimize = optimize,
        .target = target,
    });
    tests.root_module.addIncludePath(b.path("src/tests/basic"));
    const run_tests = b.addRunArtifact(tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_tests.step);
}
