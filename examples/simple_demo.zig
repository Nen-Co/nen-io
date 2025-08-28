// Nen IO Library - Simple Demo
// Demonstrates the validation-first approach and edge case handling

const std = @import("std");

pub fn main() !void {
    std.debug.print("🚀 Nen IO Library - Validation-First Approach Demo\n", .{});
    std.debug.print("==================================================\n\n", .{});

    // Example 1: Input validation before processing
    try exampleInputValidation();
    
    // Example 2: Edge case handling
    try exampleEdgeCaseHandling();
    
    // Example 3: Performance benefits
    try examplePerformanceBenefits();
    
    std.debug.print("\n🎉 All examples completed successfully!\n", .{});
    std.debug.print("\n💡 Key Takeaways:\n", .{});
    std.debug.print("   • Validation prevents errors before they occur\n", .{});
    std.debug.print("   • Inline functions provide zero-overhead validation\n", .{});
    std.debug.print("   • Edge cases are handled gracefully\n", .{});
    std.debug.print("   • Performance overhead is minimal (<1μs per validation)\n", .{});
}

fn exampleInputValidation() !void {
    std.debug.print("📝 Example 1: Input Validation Before Processing\n", .{});
    
    const test_cases = [_]struct {
        input: []const u8,
        description: []const u8,
    }{
        .{ .input = "{\"name\":\"valid\",\"value\":42}", .description = "Valid JSON object" },
        .{ .input = "[1,2,3,4,5]", .description = "Valid JSON array" },
        .{ .input = "", .description = "Empty input" },
        .{ .input = "   \n\t\r  ", .description = "Whitespace only" },
        .{ .input = "abc{\"invalid\":123}", .description = "Invalid start character" },
        .{ .input = "123", .description = "Number (not object/array)" },
        .{ .input = "  {\"spaced\":\"properly\"}  ", .description = "Valid with surrounding whitespace" },
    };
    
    for (test_cases, 0..) |test_case, i| {
        std.debug.print("  Test case {d}: {s}\n", .{ i + 1, test_case.description });
        
        // Validate input before processing
        const is_valid = validateJsonStart(test_case.input);
        
        if (is_valid) {
            std.debug.print("    ✅ Valid - safe to process\n", .{});
        } else {
            std.debug.print("    ❌ Invalid - prevented potential error\n", .{});
        }
    }
    
    std.debug.print("  ✅ Input validation example completed\n\n", .{});
}

fn exampleEdgeCaseHandling() !void {
    std.debug.print("🔧 Example 2: Edge Case Handling\n", .{});
    
    // Handle empty input
    const empty_input = "";
    if (empty_input.len == 0) {
        const default_json = handleEmptyInput();
        std.debug.print("  📭 Empty input handled: '{s}'\n", .{default_json});
    }
    
    // Handle whitespace-only input
    const whitespace_input = "   \n\t\r  ";
    if (std.mem.trim(u8, whitespace_input, " \t\n\r").len == 0) {
        const default_json = handleWhitespaceInput();
        std.debug.print("  📄 Whitespace input handled: '{s}'\n", .{default_json});
    }
    
    // Handle oversized input simulation
    const oversized_input = "{\"very_long_key_that_exceeds_reasonable_limits\":\"and_a_very_long_value_too\"}";
    const max_size = 30;
    const truncated = truncateOversizedInput(oversized_input, max_size);
    std.debug.print("  📏 Oversized input truncated: '{s}' (limit: {d} chars)\n", .{ truncated, max_size });
    
    // Demonstrate buffer size optimization
    const test_sizes = [_]usize{ 100, 5000, 50000, 500000 };
    std.debug.print("  📊 Buffer size optimization:\n", .{});
    for (test_sizes) |size| {
        const optimal_buffer = getSafeBufferSize(size);
        const efficiency = @as(f64, @floatFromInt(size)) / @as(f64, @floatFromInt(optimal_buffer)) * 100.0;
        std.debug.print("    Input: {d:>6} bytes → Buffer: {d:>7} bytes (efficiency: {d:>5.1}%)\n", .{ size, optimal_buffer, efficiency });
    }
    
    std.debug.print("  ✅ Edge case handling example completed\n\n", .{});
}

fn examplePerformanceBenefits() !void {
    std.debug.print("⚡ Example 3: Performance Benefits of Validation-First\n", .{});
    
    const iterations = 10000;
    const test_json = "{\"name\":\"test\",\"value\":42,\"array\":[1,2,3,4,5]}";
    
    // Measure validation overhead
    const start_time = std.time.nanoTimestamp();
    
    var valid_count: u32 = 0;
    for (0..iterations) |_| {
        if (validateJsonStart(test_json)) {
            valid_count += 1;
        }
    }
    
    const end_time = std.time.nanoTimestamp();
    const total_time_ns = @as(u64, @intCast(end_time - start_time));
    const avg_time_ns = total_time_ns / iterations;
    const avg_time_us = @as(f64, @floatFromInt(avg_time_ns)) / 1000.0;
    
    std.debug.print("  📊 Performance metrics:\n", .{});
    std.debug.print("    Iterations: {d}\n", .{iterations});
    std.debug.print("    Valid inputs: {d}\n", .{valid_count});
    std.debug.print("    Total time: {d} ms\n", .{total_time_ns / 1_000_000});
    std.debug.print("    Average time per validation: {d} ns ({d:.3} μs)\n", .{ avg_time_ns, avg_time_us });
    std.debug.print("    Throughput: {d:.1} million validations/second\n", .{1000.0 / avg_time_us});
    
    // Demonstrate that validation prevents expensive operations
    std.debug.print("  🛡️ Error prevention:\n", .{});
    const problematic_inputs = [_][]const u8{
        "",
        "   ",
        "invalid{\"json\":123}",
        "123.456",
        "true",
    };
    
    var prevented_errors: u32 = 0;
    for (problematic_inputs) |input| {
        if (!validateJsonStart(input)) {
            prevented_errors += 1;
        }
    }
    
    std.debug.print("    Problematic inputs tested: {d}\n", .{problematic_inputs.len});
    std.debug.print("    Errors prevented: {d}\n", .{prevented_errors});
    std.debug.print("    Prevention rate: {d:.1}%\n", .{@as(f64, @floatFromInt(prevented_errors)) / @as(f64, @floatFromInt(problematic_inputs.len)) * 100.0});
    
    std.debug.print("  ✅ Performance benefits example completed\n\n", .{});
}

// Validation and edge case handling functions (all inline for performance)

inline fn validateJsonStart(input: []const u8) bool {
    if (input.len == 0) return false;
    
    // Find first non-whitespace character
    var pos: usize = 0;
    while (pos < input.len and std.ascii.isWhitespace(input[pos])) : (pos += 1) {}
    
    if (pos >= input.len) return false;
    
    const first_char = input[pos];
    return first_char == '{' or first_char == '[';
}

inline fn handleEmptyInput() []const u8 {
    return "{}";
}

inline fn handleWhitespaceInput() []const u8 {
    return "{}";
}

inline fn truncateOversizedInput(input: []const u8, max_size: usize) []const u8 {
    if (input.len <= max_size) return input;
    
    // Find a safe truncation point
    var pos: usize = max_size;
    while (pos > 0) : (pos -= 1) {
        const char = input[pos];
        if (char == '}' or char == ']') {
            return input[0..pos + 1];
        }
    }
    
    return input[0..max_size];
}

inline fn getSafeBufferSize(input_size: usize) usize {
    const default_buffer_size = 4096;        // 4KB
    const large_buffer_size = 65536;         // 64KB
    const huge_buffer_size = 1048576;        // 1MB
    
    if (input_size <= default_buffer_size) {
        return default_buffer_size;
    } else if (input_size <= large_buffer_size) {
        return large_buffer_size;
    } else {
        return huge_buffer_size;
    }
}
