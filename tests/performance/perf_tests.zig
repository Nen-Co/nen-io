// Nen IO Library - Performance Tests
// Tests the performance impact of validation-first approach

const std = @import("std");
const io = @import("../../src/lib.zig");

test "Performance - validation overhead measurement" {
    const iterations = 10000;
    const test_json = "{\"name\":\"test\",\"value\":42,\"array\":[1,2,3,4,5],\"nested\":{\"deep\":{\"structure\":{\"with\":{\"many\":{\"levels\":\"value\"}}}}}}";
    
    // Measure parsing without validation
    const no_validation_time = try measureParsingTime(iterations, test_json, false);
    
    // Measure parsing with validation
    const with_validation_time = try measureParsingTime(iterations, test_json, true);
    
    // Calculate overhead
    const overhead_percent = ((with_validation_time - no_validation_time) / no_validation_time) * 100.0;
    
    std.debug.print("Validation overhead: {d:.2}%\n", .{overhead_percent});
    
    // Validation overhead should be minimal (<5%)
    try std.testing.expect(overhead_percent < 5.0);
}

test "Performance - streaming parser efficiency" {
    const large_json = generateLargeJson(10000);
    defer std.testing.allocator.free(large_json);
    
    // Measure streaming parsing performance
    const start_time = std.time.nanoTimestamp();
    
    var parser = io.StreamingJsonParser.init();
    defer parser.deinit();
    
    // Create a temporary file for testing
    const test_file = "perf_test.json";
    try io.JsonFile.writeStatic(test_file, large_json);
    defer std.fs.cwd().deleteFile(test_file) catch {};
    
    try parser.openFile(test_file);
    try parser.parseFile();
    
    const end_time = std.time.nanoTimestamp();
    const parse_time_ns = @intCast(@intCast(u64, end_time - start_time));
    
    const stats = parser.getStats();
    const throughput_mb_s = stats.parse_speed_mb_s;
    
    std.debug.print("Streaming parse: {d} bytes in {d}ms, throughput: {d:.2} MB/s\n", .{
        stats.bytes_read,
        parse_time_ns / 1_000_000,
        throughput_mb_s
    });
    
    // Should achieve reasonable throughput (>100 MB/s)
    try std.testing.expect(throughput_mb_s > 100.0);
}

test "Performance - buffer utilization optimization" {
    const test_sizes = [_]usize{ 100, 1000, 10000, 100000 };
    
    for (test_sizes) |size| {
        const optimal_buffer = io.JsonValidator.getSafeBufferSize(size);
        const optimal_chunk = io.JsonValidator.getSafeChunkSize(size);
        
        // Measure memory efficiency
        const memory_efficiency = @as(f64, @floatFromInt(size)) / @as(f64, @floatFromInt(optimal_buffer));
        
        std.debug.print("Size {d}: buffer {d}, chunk {d}, efficiency {d:.2}%\n", .{
            size,
            optimal_buffer,
            optimal_chunk,
            memory_efficiency * 100.0
        });
        
        // Buffer utilization should be >80%
        try std.testing.expect(memory_efficiency > 0.8);
    }
}

test "Performance - edge case handling speed" {
    const edge_cases = [_][]const u8{
        "",                    // Empty
        "   \n\t\r  ",        // Whitespace only
        "{\"test\":\"value\"", // Unterminated
        "{\"test\":[1,2,3}",   // Unmatched
    };
    
    for (edge_cases) |edge_case| {
        const start_time = std.time.nanoTimestamp();
        
        // Validate edge case
        const result = io.JsonValidator.validateInput(edge_case);
        
        const end_time = std.time.nanoTimestamp();
        const validation_time_ns = @intCast(@intCast(u64, end_time - start_time));
        
        std.debug.print("Edge case '{s}': {d}ns, valid: {}\n", .{
            if (edge_case.len > 20) edge_case[0..20] ++ "..." else edge_case,
            validation_time_ns,
            result.isSuccess()
        });
        
        // Edge case validation should be fast (<1000ns)
        try std.testing.expect(validation_time_ns < 1000);
    }
}

test "Performance - concurrent validation" {
    const test_json = "{\"test\":\"value\"}";
    const concurrent_count = 100;
    
    var threads: [concurrent_count]std.Thread = undefined;
    var results: [concurrent_count]io.validation.ValidationResult = undefined;
    
    const start_time = std.time.nanoTimestamp();
    
    // Spawn concurrent validation threads
    for (0..concurrent_count) |i| {
        threads[i] = try std.Thread.spawn(.{}, validateConcurrently, .{ test_json, &results[i] });
    }
    
    // Wait for all threads to complete
    for (threads) |thread| {
        thread.join();
    }
    
    const end_time = std.time.nanoTimestamp();
    const total_time_ns = @intCast(@intCast(u64, end_time - start_time));
    const avg_time_ns = total_time_ns / concurrent_count;
    
    std.debug.print("Concurrent validation: {d} threads, avg {d}ns per validation\n", .{
        concurrent_count,
        avg_time_ns
    });
    
    // All results should be valid
    for (results) |result| {
        try std.testing.expect(result.isSuccess());
    }
    
    // Concurrent validation should be efficient
    try std.testing.expect(avg_time_ns < 1000);
}

test "Performance - memory mapping efficiency" {
    const test_file = "mmap_test.json";
    const test_size = 1024 * 1024; // 1MB
    
    // Create a test file
    const file = try std.fs.cwd().createFile(test_file, .{});
    defer file.close();
    defer std.fs.cwd().deleteFile(test_file) catch {};
    
    // Extend file to test size
    try file.setEndPos(test_size);
    
    // Measure memory mapping performance
    const start_time = std.time.nanoTimestamp();
    
    const mapped = try std.os.mmap(
        null,
        test_size,
        std.os.PROT.READ,
        std.os.MAP.PRIVATE,
        file.handle,
        0,
    );
    defer std.os.munmap(mapped);
    
    const end_time = std.time.nanoTimestamp();
    const mmap_time_ns = @intCast(@intCast(u64, end_time - start_time));
    
    std.debug.print("Memory mapping: {d} bytes in {d}ns\n", .{ test_size, mmap_time_ns });
    
    // Memory mapping should be fast (<10000ns for 1MB)
    try std.testing.expect(mmap_time_ns < 10000);
}

// Helper functions for performance testing

fn measureParsingTime(iterations: u32, json_string: []const u8, with_validation: bool) !u64 {
    const start_time = std.time.nanoTimestamp();
    
    var i: u32 = 0;
    while (i < iterations) : (i += 1) {
        if (with_validation) {
            const result = io.JsonValidator.validateInput(json_string);
            if (!result.isSuccess()) {
                return error.ValidationFailed;
            }
        }
        
        // Simulate some parsing work
        var sum: u64 = 0;
        for (json_string) |char| {
            sum += char;
        }
        _ = sum;
    }
    
    const end_time = std.time.nanoTimestamp();
    return @intCast(@intCast(u64, end_time - start_time));
}

fn generateLargeJson(size: usize) []u8 {
    var json = std.ArrayList(u8).init(std.testing.allocator);
    
    json.appendSlice("{\n") catch {};
    json.appendSlice("  \"items\": [\n") catch {};
    
    for (0..size) |i| {
        if (i > 0) json.appendSlice(",\n") catch {};
        json.appendSlice("    {\n") catch {};
        json.appendSlice("      \"id\": ") catch {};
        json.appendSlice(try std.fmt.allocPrint(std.testing.allocator, "{d}", .{i})) catch {};
        json.appendSlice(",\n") catch {};
        json.appendSlice("      \"name\": \"Item ") catch {};
        json.appendSlice(try std.fmt.allocPrint(std.testing.allocator, "{d}", .{i})) catch {};
        json.appendSlice("\",\n") catch {};
        json.appendSlice("      \"value\": ") catch {};
        json.appendSlice(try std.fmt.allocPrint(std.testing.allocator, "{d}", .{i * 2})) catch {};
        json.appendSlice("\n") catch {};
        json.appendSlice("    }") catch {};
    }
    
    json.appendSlice("\n  ]\n") catch {};
    json.appendSlice("}\n") catch {};
    
    return json.toOwnedSlice();
}

fn validateConcurrently(json_string: []const u8, result: *io.validation.ValidationResult) void {
    result.* = io.JsonValidator.validateInput(json_string);
}
