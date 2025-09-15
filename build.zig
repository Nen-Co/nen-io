const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Main library module
    const lib = b.addModule("nen-io", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Main executable for testing/demo
    const exe = b.addExecutable(.{
        .name = "nen-io",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.root_module.addImport("nen-io", lib);
    b.installArtifact(exe);

    // Unit tests
    const unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/unit/basic_tests.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    unit_tests.root_module.addImport("nen-io", lib);

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test-unit", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);

    // Performance tests
    const perf_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/performance/perf_tests.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    perf_tests.root_module.addImport("nen-io", lib);

    const run_perf_tests = b.addRunArtifact(perf_tests);
    const perf_step = b.step("test-performance", "Run performance tests");
    perf_step.dependOn(&run_perf_tests.step);

    // Examples
    const examples = b.addExecutable(.{
        .name = "examples",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/simple_demo.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    examples.root_module.addImport("nen-io", lib);

    const run_examples = b.addRunArtifact(examples);
    const examples_step = b.step("examples", "Run examples");
    examples_step.dependOn(&run_examples.step);

    // DOD Demo
    const dod_demo = b.addExecutable(.{
        .name = "dod-demo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/dod_demo.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    dod_demo.root_module.addImport("nen-io", lib);

    const run_dod_demo = b.addRunArtifact(dod_demo);
    const dod_demo_step = b.step("dod-demo", "Run Data-Oriented Design demo");
    dod_demo_step.dependOn(&run_dod_demo.step);

    // All tests
    const all_tests = b.step("test-all", "Run all tests");
    all_tests.dependOn(&run_unit_tests.step);
    all_tests.dependOn(&run_perf_tests.step);
}
