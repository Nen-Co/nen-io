const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Main library module
    const lib = b.addStaticLibrary(.{
        .name = "nen-io",
        .root_source_file = .{ .cwd_relative = "src/lib.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Install library
    b.installArtifact(lib);

    // Main executable for testing/demo
    const exe = b.addExecutable(.{
        .name = "nen-io",
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibrary(lib);

    b.installArtifact(exe);

    // Unit tests
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "tests/unit/basic_tests.zig" },
        .target = target,
        .optimize = optimize,
    });
    unit_tests.linkLibrary(lib);

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);

    // Performance tests
    const perf_tests = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "tests/performance/perf_tests.zig" },
        .target = target,
        .optimize = optimize,
    });
    perf_tests.linkLibrary(lib);

    const run_perf_tests = b.addRunArtifact(perf_tests);
    const perf_step = b.step("test-perf", "Run performance tests");
    perf_step.dependOn(&run_perf_tests.step);

    // Examples
    const examples = b.addExecutable(.{
        .name = "examples",
        .root_source_file = .{ .cwd_relative = "examples/simple_demo.zig" },
        .target = target,
        .optimize = optimize,
    });
    examples.linkLibrary(lib);

    const run_examples = b.addRunArtifact(examples);
    const examples_step = b.step("examples", "Run examples");
    examples_step.dependOn(&run_examples.step);

    // All tests
    const all_tests = b.step("test-all", "Run all tests");
    all_tests.dependOn(test_step);
    all_tests.dependOn(perf_step);
}
