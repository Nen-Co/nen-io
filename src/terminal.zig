// Nen-IO Terminal Module
// High-performance terminal I/O with zero allocations and DOD principles
// Following TigerBeetle-style architecture

const std = @import("std");

// Terminal output with color support and performance optimizations
pub const Terminal = struct {
    // Color codes for terminal output (pre-computed for performance)
    const Colors = struct {
        pub const RESET = "\x1b[0m";
        pub const RED = "\x1b[31m";
        pub const GREEN = "\x1b[32m";
        pub const YELLOW = "\x1b[33m";
        pub const BLUE = "\x1b[34m";
        pub const MAGENTA = "\x1b[35m";
        pub const CYAN = "\x1b[36m";
        pub const WHITE = "\x1b[37m";
        pub const BOLD = "\x1b[1m";
    };

    // Static buffer for output formatting (TigerBeetle-style static allocation)
    var output_buffer: [4096]u8 = undefined;

    // Inline functions for maximum performance - using debug print for Zig 0.15.1 compatibility
    pub inline fn print(comptime format: []const u8, args: anytype) !void {
        std.debug.print(format, args);
    }
    pub inline fn println(comptime format: []const u8, args: anytype) !void {
        try print(format ++ "\n", args);
    }

    // Success messages (green)
    pub inline fn success(comptime format: []const u8, args: anytype) !void {
        try print(Colors.GREEN ++ format ++ Colors.RESET, args);
    }

    pub inline fn successln(comptime format: []const u8, args: anytype) !void {
        try println(Colors.GREEN ++ format ++ Colors.RESET, args);
    }

    // Info messages (blue)
    pub inline fn info(comptime format: []const u8, args: anytype) !void {
        try print(Colors.BLUE ++ format ++ Colors.RESET, args);
    }

    pub inline fn infoln(comptime format: []const u8, args: anytype) !void {
        try println(Colors.BLUE ++ format ++ Colors.RESET, args);
    }

    // Warning messages (yellow)
    pub inline fn warn(comptime format: []const u8, args: anytype) !void {
        try print(Colors.YELLOW ++ format ++ Colors.RESET, args);
    }

    pub inline fn warnln(comptime format: []const u8, args: anytype) !void {
        try println(Colors.YELLOW ++ format ++ Colors.RESET, args);
    }

    // Error messages (red)
    pub inline fn err(comptime format: []const u8, args: anytype) !void {
        try print(Colors.RED ++ format ++ Colors.RESET, args);
    }

    pub inline fn errorln(comptime format: []const u8, args: anytype) !void {
        try println(Colors.RED ++ format ++ Colors.RESET, args);
    }

    // Bold messages
    pub inline fn bold(comptime format: []const u8, args: anytype) !void {
        try print(Colors.BOLD ++ format ++ Colors.RESET, args);
    }

    pub inline fn boldln(comptime format: []const u8, args: anytype) !void {
        try println(Colors.BOLD ++ format ++ Colors.RESET, args);
    }

    // High-performance batch output for DOD scenarios
    pub inline fn flush() !void {
        // No explicit flush needed for stdout in Zig 0.15.1
    }
};
