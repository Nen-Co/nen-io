// Nen IO Library - Main Entry Point
// High-performance, zero-allocation I/O operations with static memory pools
// All critical functions are inline for maximum performance

// Core IO modules
pub const streaming = @import("streaming.zig");
pub const file = @import("file.zig");
pub const network = @import("network.zig");
pub const memory_mapped = @import("memory_mapped.zig");
pub const performance = @import("performance.zig");

// Re-export main types for convenience
pub const StreamingJsonParser = streaming.StreamingJsonParser;
pub const JsonFile = file.JsonFile;
pub const JsonNetwork = network.JsonNetwork;
pub const JsonMemoryMapped = memory_mapped.JsonMemoryMapped;
pub const JsonPerformance = performance.JsonPerformance;
// Validation module temporarily removed due to compilation issues

// Configuration and constants
pub const config = @import("config.zig");

// Error types
pub const IoError = error{
    FileNotFound,
    FileTooLarge,
    BufferTooSmall,
    InvalidFormat,
    NetworkError,
    MemoryError,
    ParseError,
    ValidationError,
    StreamingError,
    ChunkError,
};

// Version information
pub const VERSION = "0.1.0";
pub const VERSION_STRING = "Nen IO v" ++ VERSION;

// Feature flags
pub const FEATURES = struct {
    pub const static_memory = true;        // Zero dynamic allocation
    pub const inline_functions = true;     // Critical operations are inline
    pub const streaming = true;            // Streaming support for large files
    pub const memory_mapping = true;       // Memory-mapped file support
    pub const network = true;              // Network operations support
    pub const performance_monitoring = true; // Built-in performance tracking
    pub const error_context = true;        // Rich error information
    pub const zero_copy = true;            // Minimize memory copying
};

// Performance targets
pub const PERFORMANCE_TARGETS = struct {
    pub const parse_speed_gb_s: f64 = 2.0;        // Target: 2 GB/s parsing speed
    pub const memory_overhead_percent: f64 = 5.0; // Target: <5% memory overhead
    pub const startup_time_ms: u64 = 10;          // Target: <10ms startup time
    pub const buffer_utilization: f64 = 0.8;      // Target: >80% buffer utilization
    pub const streaming_latency_ms: u64 = 1;      // Target: <1ms streaming latency
};

// Convenience functions for common operations
pub const io = struct {
    /// Read JSON from file with static memory
    pub inline fn readJson(file_path: []const u8) ![]const u8 {
        return JsonFile.readStatic(file_path);
    }
    
    /// Write JSON to file
    pub inline fn writeJson(file_path: []const u8, json_string: []const u8) !void {
        return JsonFile.writeStatic(file_path, json_string);
    }
    
    /// Validate JSON file without parsing to memory
    pub inline fn validateJson(file_path: []const u8) !void {
        return JsonFile.validateFile(file_path);
    }
    
    /// Stream parse large JSON file
    pub inline fn streamParseJson(file_path: []const u8) !StreamingJsonParser.Stats {
        var parser = StreamingJsonParser.init();
        defer parser.deinit();
        
        try parser.openFile(file_path);
        try parser.parseFile();
        
        return parser.getStats();
    }
    
    /// Parse JSON from HTTP response
    pub inline fn parseHttpJson(response: []const u8) ![]const u8 {
        return JsonNetwork.parseHttpResponse(response);
    }
    
    /// Create HTTP response with JSON
    pub inline fn createHttpJsonResponse(json_body: []const u8, status_code: u16) ![]const u8 {
        return JsonNetwork.createHttpResponse(json_body, status_code);
    }
    
    /// Parse JSON from memory-mapped file
    pub inline fn parseMappedJson(file_handle: std.fs.File) ![]const u8 {
        return JsonMemoryMapped.parseMappedFile(file_handle);
    }
    
    /// Monitor JSON parsing performance
    pub inline fn monitorJsonParsing(comptime operation: []const u8, comptime callback: fn() anyerror!void) !void {
        return JsonPerformance.monitorParsing(operation, callback);
    }
    
    /// Benchmark JSON operations
    pub inline fn benchmarkJson(comptime operation: []const u8, iterations: u32, comptime callback: fn() anyerror!void) !performance.BenchmarkResult {
        return JsonPerformance.benchmark(operation, iterations, callback);
    }
    
    /// Log JSON parsing errors with context
    pub inline fn logJsonError(err: anyerror, context: []const u8, file_path: ?[]const u8) !void {
        // Simple error logging for now
        const stderr = std.io.getStdErr().writer();
        try stderr.print("JSON Error in {s}: {s}", .{ context, @errorName(err) });
        if (file_path) |path| {
            try stderr.print(" (file: {s})", .{path});
        }
        try stderr.print("\n", .{});
    }
    
    /// Get file statistics
    pub inline fn getFileStats(file_path: []const u8) !file.FileStats {
        return JsonFile.getFileStats(file_path);
    }
};

const std = @import("std");

// Compile-time assertions for configuration
comptime {
    // Ensure buffer sizes are reasonable
    if (config.default_buffer_size < 1024) {
        @compileError("Default buffer size must be at least 1KB");
    }
    
    if (config.large_buffer_size < config.default_buffer_size) {
        @compileError("Large buffer size must be greater than default buffer size");
    }
    
    if (config.huge_buffer_size < config.large_buffer_size) {
        @compileError("Huge buffer size must be greater than large buffer size");
    }
    
    // Ensure chunk sizes are reasonable
    if (config.default_chunk_size < 1024) {
        @compileError("Default chunk size must be at least 1KB");
    }
    
    if (config.streaming_chunk_size < config.default_chunk_size) {
        @compileError("Streaming chunk size must be greater than default chunk size");
    }
    
    // Ensure limits are reasonable
    if (config.max_file_size < 1048576) {
        @compileError("Max file size must be at least 1MB");
    }
    
    if (config.max_nesting_depth < 16) {
        @compileError("Max nesting depth must be at least 16");
    }
    
    if (config.max_line_length < 1024) {
        @compileError("Max line length must be at least 1KB");
    }
}
