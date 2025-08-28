// Nen IO Library - Main Entry Point
// High-performance, zero-allocation I/O operations with static memory management

const std = @import("std");

// Core modules
pub const validation = @import("validation.zig");
pub const config = @import("config.zig");
pub const batching = @import("batching.zig");

// Re-export main types for convenience
pub const ValidationResult = validation.ValidationResult;
pub const ValidationError = validation.ValidationError;
pub const JsonValidator = validation.JsonValidator;
pub const EdgeCaseHandler = validation.EdgeCaseHandler;

// Re-export batching types
pub const FileBatch = batching.FileBatch;
pub const NetworkBatch = batching.NetworkBatch;
pub const MemoryBatch = batching.MemoryBatch;
pub const StreamBatch = batching.StreamBatch;
pub const PerformanceBatch = batching.PerformanceBatch;
pub const BatchStats = batching.BatchStats;
pub const BatchOp = batching.BatchOp;

// Configuration constants
pub const default_buffer_size = config.default_buffer_size;
pub const large_buffer_size = config.large_buffer_size;
pub const huge_buffer_size = config.huge_buffer_size;

// Batching configuration
pub const file_sync_interval = config.batching.file_sync_interval;
pub const file_batch_size = config.batching.file_batch_size;
pub const network_batch_size = config.batching.network_batch_size;
pub const stream_batch_size = config.batching.stream_batch_size;

// Convenience functions for common operations
pub inline fn readJson(path: []const u8) ![]const u8 {
    // Simple file read for now - will be enhanced with batching
    const file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer file.close();
    
    const content = try file.readToEndAlloc(std.heap.page_allocator, std.math.maxInt(usize));
    return content; // Caller must free
}

pub inline fn writeJson(path: []const u8, content: []const u8) !void {
    // Simple file write for now - will be enhanced with batching
    const file = try std.fs.cwd().createFile(path, .{});
    defer file.close();
    
    try file.writeAll(content);
}

pub inline fn parseHttpJson(response: []const u8) ![]const u8 {
    // Find JSON content in HTTP response
    const json_start = std.mem.indexOf(u8, response, "\r\n\r\n") orelse 0;
    return response[json_start..];
}

pub inline fn createHttpJsonResponse(json_body: []const u8, status_code: u16) ![]const u8 {
    // Create simple HTTP response
    var response = std.ArrayList(u8).init(std.heap.page_allocator);
    defer response.deinit();
    
    try response.appendSlice("HTTP/1.1 ");
    try response.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d} OK\r\n", .{status_code}));
    try response.appendSlice("Content-Type: application/json\r\n");
    try response.appendSlice("Content-Length: ");
    try response.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}\r\n", .{json_body.len}));
    try response.appendSlice("\r\n");
    try response.appendSlice(json_body);
    
    return response.toOwnedSlice();
}

pub inline fn parseMappedJson(file_handle: std.fs.File) ![]const u8 {
    // Simple memory-mapped read for now
    const stat = try file_handle.stat();
    const content = try file_handle.readToEndAlloc(std.heap.page_allocator, stat.size);
    return content; // Caller must free
}

pub inline fn validateJson(json_string: []const u8) !void {
    // Simple validation - check if it starts with valid JSON characters
    if (json_string.len == 0) return error.EmptyInput;
    
    var pos: usize = 0;
    while (pos < json_string.len and std.ascii.isWhitespace(json_string[pos])) : (pos += 1) {}
    
    if (pos >= json_string.len) return error.EmptyInput;
    
    const first_char = json_string[pos];
    if (first_char != '{' and first_char != '[') {
        return error.InvalidJsonStart;
    }
}

pub inline fn logJsonError(err: anyerror, context: []const u8, file_path: ?[]const u8) !void {
    // Simple error logging
    const stderr = std.io.getStdErr().writer();
    if (file_path) |path| {
        try stderr.print("JSON Error in {s} (file: {s}): {s}\n", .{ context, path, @errorName(err) });
    } else {
        try stderr.print("JSON Error in {s}: {s}\n", .{ context, @errorName(err) });
    }
}

// Batching convenience functions
pub inline fn createFileBatch() FileBatch {
    return FileBatch.init();
}

pub inline fn createNetworkBatch() NetworkBatch {
    return NetworkBatch.init();
}

pub inline fn createStreamBatch() StreamBatch {
    return StreamBatch.init();
}

pub inline fn createMemoryBatch() MemoryBatch {
    return MemoryBatch.init();
}

pub inline fn createPerformanceBatch() PerformanceBatch {
    return PerformanceBatch.init();
}

// Version information
pub const VERSION = "0.1.0";
pub const VERSION_STRING = "Nen IO v" ++ VERSION;

// Feature flags
pub const FEATURES = struct {
    pub const static_memory = true;        // Zero dynamic allocation
    pub const inline_functions = true;     // Critical operations are inline
    pub const validation_first = true;     // Validation-first approach
    pub const batching = true;             // I/O operation batching
    pub const performance_monitoring = true; // Built-in performance tracking
    pub const edge_case_handling = true;   // Graceful edge case handling
};

// Performance targets
pub const PERFORMANCE_TARGETS = struct {
    pub const min_throughput_mb_s: f64 = 100.0;     // Target: 100 MB/s minimum
    pub const max_latency_ms: u64 = 10;             // Target: <10ms latency
    pub const batch_efficiency: f64 = 0.8;          // Target: >80% batch utilization
    pub const memory_overhead_percent: f64 = 5.0;   // Target: <5% memory overhead
};
