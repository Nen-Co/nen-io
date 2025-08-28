// Nen IO Library - Simple Demo
// Demonstrates the validation-first approach

const std = @import("std");

pub fn main() !void {
    std.debug.print("🚀 Nen IO Library - Validation-First Demo\n", .{});
    std.debug.print("=========================================\n\n", .{});
    
    // Simple validation example
    const test_input = "{\"name\":\"test\",\"value\":42}";
    std.debug.print("✅ Testing input: {s}\n", .{test_input});
    
    // Simple validation logic
    if (isValidJsonStart(test_input)) {
        std.debug.print("✅ Input validated successfully!\n", .{});
    } else {
        std.debug.print("❌ Input validation failed\n", .{});
    }
    
    std.debug.print("\n🎉 Demo completed!\n", .{});
}

// Simple validation function
inline fn isValidJsonStart(input: []const u8) bool {
    if (input.len == 0) return false;
    
    // Find first non-whitespace character
    var pos: usize = 0;
    while (pos < input.len and std.ascii.isWhitespace(input[pos])) : (pos += 1) {}
    
    if (pos >= input.len) return false;
    
    const first_char = input[pos];
    return first_char == '{' or first_char == '[';
}
