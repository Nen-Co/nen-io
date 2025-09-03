// Nen IO Library - Performance Tests
// Tests the performance impact of validation-first approach

const std = @import("std");
const io = @import("nen-io");

test "Performance - validation overhead measurement" {
    const iterations = 1000; // Reduced for faster tests
    const test_json = "{\"name\":\"test\",\"value\":42,\"array\":[1,2,3,4,5]}";

    // Test without validation
    const start_time = std.time.nanoTimestamp();
    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        // Simulate processing without validation - just count characters
        var sum: u64 = 0;
        for (test_json) |char| {
            sum += char;
        }
        // Use sum to avoid unused variable warning
        if (sum == 0) unreachable;
    }
    const no_validation_time = @as(u64, @intCast(std.time.nanoTimestamp() - start_time));

    // Test with validation
    const start_time2 = std.time.nanoTimestamp();
    i = 0;
    while (i < iterations) : (i += 1) {
        const result = io.JsonValidator.validateInput(test_json);
        _ = result; // Use result to avoid unused variable warning
    }
    const with_validation_time = @as(u64, @intCast(std.time.nanoTimestamp() - start_time2));

    const overhead_percent = @as(f64, @floatFromInt(with_validation_time - no_validation_time)) / @as(f64, @floatFromInt(no_validation_time)) * 100.0;

    std.debug.print("Validation overhead: {d:.2}% ({d}ns vs {d}ns)\n", .{ overhead_percent, with_validation_time, no_validation_time });

    // Validation overhead should be reasonable (<300% for this simple test)
    try std.testing.expect(overhead_percent < 300.0);
}

test "Performance - basic validation throughput" {
    const iterations = 1000;
    const test_json = "{\"name\":\"test\",\"value\":42}";

    const start_time = std.time.nanoTimestamp();

    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        const result = io.JsonValidator.validateInput(test_json);
        _ = result; // Use result to avoid unused variable warning
    }

    const end_time = std.time.nanoTimestamp();
    const total_time_ns = @as(u64, @intCast(end_time - start_time));
    const avg_time_ns = total_time_ns / iterations;

    std.debug.print("Basic validation: {d} iterations in {d}ms, avg {d}ns per validation\n", .{ iterations, total_time_ns / 1_000_000, avg_time_ns });

    // Should be reasonably fast (<1000ns per validation)
    try std.testing.expect(avg_time_ns < 1000);
}

test "Performance - edge case validation" {
    const edge_cases = [_][]const u8{
        "{}",
        "[]",
        "\"\"",
        "null",
        "true",
        "false",
        "42",
        "3.14",
        "{\"key\":\"value\"}",
        "[1,2,3]",
    };

    const start_time = std.time.nanoTimestamp();

    for (edge_cases) |edge_case| {
        const result = io.JsonValidator.validateInput(edge_case);
        _ = result; // Use result to avoid unused variable warning
    }

    const end_time = std.time.nanoTimestamp();
    const total_time_ns = @as(u64, @intCast(end_time - start_time));
    const avg_time_ns = total_time_ns / edge_cases.len;

    std.debug.print("Edge case validation: {d} cases in {d}ns, avg {d}ns per case\n", .{ edge_cases.len, total_time_ns, avg_time_ns });

    // Should be reasonably fast (<1000ns per case)
    try std.testing.expect(avg_time_ns < 1000);
}

test "Performance - concurrent validation simulation" {
    const concurrent_count = 10;
    const iterations_per_thread = 100;
    const test_json = "{\"test\":\"data\"}";

    const start_time = std.time.nanoTimestamp();

    // Simulate concurrent validation (sequential for simplicity)
    var thread_i: usize = 0;
    while (thread_i < concurrent_count) : (thread_i += 1) {
        var i: usize = 0;
        while (i < iterations_per_thread) : (i += 1) {
            const result = io.JsonValidator.validateInput(test_json);
            _ = result; // Use result to avoid unused variable warning
        }
    }

    const end_time = std.time.nanoTimestamp();
    const total_time_ns = @as(u64, @intCast(end_time - start_time));
    const total_operations = concurrent_count * iterations_per_thread;
    const avg_time_ns = total_time_ns / total_operations;

    std.debug.print("Concurrent validation simulation: {d} operations in {d}ms, avg {d}ns per operation\n", .{ total_operations, total_time_ns / 1_000_000, avg_time_ns });

    // Should be reasonably fast (<1000ns per operation)
    try std.testing.expect(avg_time_ns < 1000);
}
