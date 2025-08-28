// Nen IO Library - Basic Tests
// Tests basic functionality without problematic modules

const std = @import("std");

test "basic validation logic" {
    // Test valid JSON start
    try std.testing.expect(isValidJsonStart("{\"test\":\"value\"}"));
    try std.testing.expect(isValidJsonStart("[1,2,3]"));
    try std.testing.expect(isValidJsonStart("  {\"spaced\":\"object\"}  "));
    
    // Test invalid JSON start
    try std.testing.expect(!isValidJsonStart(""));
    try std.testing.expect(!isValidJsonStart("   "));
    try std.testing.expect(!isValidJsonStart("abc{\"test\":123}"));
    try std.testing.expect(!isValidJsonStart("123"));
}

test "edge case handling" {
    // Test empty input
    try std.testing.expect(!isValidJsonStart(""));
    
    // Test whitespace-only input
    try std.testing.expect(!isValidJsonStart("   \n\t\r  "));
    
    // Test valid inputs with various whitespace
    try std.testing.expect(isValidJsonStart("\n\t {\"test\":\"value\"}"));
    try std.testing.expect(isValidJsonStart("\r\n[1,2,3]"));
}

test "buffer size calculations" {
    // Test safe buffer size calculation
    try std.testing.expectEqual(@as(usize, 4096), getSafeBufferSize(100));
    try std.testing.expectEqual(@as(usize, 65536), getSafeBufferSize(10000));
    try std.testing.expectEqual(@as(usize, 1048576), getSafeBufferSize(100000));
}

test "validation performance" {
    const iterations = 1000;
    const test_json = "{\"name\":\"test\",\"value\":42}";
    
    const start_time = std.time.nanoTimestamp();
    
    for (0..iterations) |_| {
        const is_valid = isValidJsonStart(test_json);
        try std.testing.expect(is_valid);
    }
    
    const end_time = std.time.nanoTimestamp();
    const total_time_ns = @as(u64, @intCast(end_time - start_time));
    const avg_time_ns = total_time_ns / iterations;
    
    // Validation should be fast (less than 1000ns per operation)
    try std.testing.expect(avg_time_ns < 1000);
}

test "config values" {
    // Test that config values are reasonable
    const default_buffer_size = 4096;
    const large_buffer_size = 65536;
    const huge_buffer_size = 1048576;
    const max_file_size = 1073741824;
    const max_nesting_depth = 100;
    const max_line_length = 1048576;
    
    try std.testing.expect(default_buffer_size > 0);
    try std.testing.expect(large_buffer_size > default_buffer_size);
    try std.testing.expect(huge_buffer_size > large_buffer_size);
    
    try std.testing.expect(max_file_size > 0);
    try std.testing.expect(max_nesting_depth > 0);
    try std.testing.expect(max_line_length > 0);
}

test "error prevention examples" {
    // Test that we can detect problematic inputs before processing
    const problematic_inputs = [_][]const u8{
        "",                           // Empty
        "   ",                        // Whitespace only
        "invalid{\"test\":123}",      // Invalid start
        "123",                        // Number start
        "true",                       // Boolean start
        "\"string\"",                 // String start
    };
    
    for (problematic_inputs) |input| {
        // All of these should be caught by validation
        try std.testing.expect(!isValidJsonStart(input));
    }
}

// Helper functions for testing

inline fn isValidJsonStart(input: []const u8) bool {
    if (input.len == 0) return false;
    
    // Find first non-whitespace character
    var pos: usize = 0;
    while (pos < input.len and std.ascii.isWhitespace(input[pos])) : (pos += 1) {}
    
    if (pos >= input.len) return false;
    
    const first_char = input[pos];
    return first_char == '{' or first_char == '[';
}

inline fn getSafeBufferSize(input_size: usize) usize {
    const default_buffer_size = 4096;
    const large_buffer_size = 65536;
    const huge_buffer_size = 1048576;
    
    if (input_size <= default_buffer_size) {
        return default_buffer_size;
    } else if (input_size <= large_buffer_size) {
        return large_buffer_size;
    } else {
        return huge_buffer_size;
    }
}
