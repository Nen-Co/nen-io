// Nen IO Performance Monitoring Module
// Provides performance monitoring and benchmarking capabilities
// All functions are inline for maximum performance

const std = @import("std");
const config = @import("lib.zig").config;

// Performance monitoring with nen IO integration
pub const JsonPerformance = struct {
    // Monitor JSON parsing performance
    pub inline fn monitorParsing(comptime operation: []const u8, comptime callback: fn() anyerror!void) !void {
        const start_time = std.time.nanoTimestamp();
        
        try callback();
        
        const end_time = std.time.nanoTimestamp();
        const duration_ns = @as(u64, @intCast(end_time - start_time));
        const duration_ms = duration_ns / 1_000_000;
        
        if (!@import("builtin").is_test) {
            // Use stderr for performance logging
            const stderr = std.io.getStdErr().writer();
            try stderr.print("JSON {s} completed in {d}ms\n", .{ operation, duration_ms });
        }
    }
    
    // Benchmark JSON operations
    pub inline fn benchmark(comptime operation: []const u8, iterations: u32, comptime callback: fn() anyerror!void) !BenchmarkResult {
        const start_time = std.time.nanoTimestamp();
        
        var i: u32 = 0;
        while (i < iterations) : (i += 1) {
            try callback();
        }
        
        const end_time = std.time.nanoTimestamp();
        const total_time_ns = @as(u64, @intCast(end_time - start_time));
        const avg_time_ns = total_time_ns / iterations;
        const ops_per_second = @as(f64, @floatFromInt(iterations)) / (@as(f64, @floatFromInt(total_time_ns)) / 1_000_000_000.0);
        
        if (!@import("builtin").is_test) {
            const stderr = std.io.getStdErr().writer();
            try stderr.print("JSON {s} benchmark: {d} ops/sec (avg {d}ns)\n", .{ 
                operation, 
                @as(u64, @intFromFloat(ops_per_second)), 
                avg_time_ns 
            });
        }
        
        return BenchmarkResult{
            .total_time_ns = total_time_ns,
            .avg_time_ns = avg_time_ns,
            .operations_per_second = ops_per_second,
            .iterations = iterations,
            .operation_name = operation,
        };
    }
    
    // Measure memory usage
    pub inline fn measureMemoryUsage(comptime operation: []const u8, comptime callback: fn() anyerror!void) !MemoryUsage {
        const start_memory = getCurrentMemoryUsage();
        
        try callback();
        
        const end_memory = getCurrentMemoryUsage();
        
        return MemoryUsage{
            .operation = operation,
            .start_bytes = start_memory,
            .end_bytes = end_memory,
            .peak_bytes = @max(start_memory, end_memory),
            .delta_bytes = if (end_memory > start_memory) 
                end_memory - start_memory 
            else 
                start_memory - end_memory,
        };
    }
    
    // Performance profiler
    pub const Profiler = struct {
        const Self = @This();
        
        start_time: i64 = 0,
        checkpoints: std.ArrayList(Checkpoint),
        
        pub const Checkpoint = struct {
            name: []const u8,
            time_ns: u64,
            memory_bytes: usize,
        };
        
        pub inline fn init() Self {
            return Self{
                .checkpoints = std.ArrayList(Checkpoint).init(std.heap.page_allocator),
            };
        }
        
        pub inline fn deinit(self: *Self) void {
            self.checkpoints.deinit();
        }
        
        pub inline fn start(self: *Self) void {
            self.start_time = std.time.nanoTimestamp();
        }
        
        pub inline fn checkpoint(self: *Self, name: []const u8) !void {
            const current_time = std.time.nanoTimestamp();
            const time_ns = @as(u64, @intCast(current_time - self.start_time));
            const memory_bytes = getCurrentMemoryUsage();
            
            try self.checkpoints.append(Checkpoint{
                .name = name,
                .time_ns = time_ns,
                .memory_bytes = memory_bytes,
            });
        }
        
        pub inline fn getResults(self: *const Self) []const Checkpoint {
            return self.checkpoints.items;
        }
        
        pub inline fn printResults(self: *const Self) !void {
            const stderr = std.io.getStdErr().writer();
            try stderr.print("Performance Profile Results:\n", .{});
            
            for (self.checkpoints.items, 0..) |checkpoint_item, i| {
                const prev_time = if (i > 0) self.checkpoints.items[i - 1].time_ns else 0;
                const delta_time = checkpoint_item.time_ns - prev_time;
                const delta_ms = delta_time / 1_000_000;
                
                try stderr.print("  {s}: {d}ms (total: {d}ms, memory: {d} bytes)\n", .{
                    checkpoint_item.name,
                    delta_ms,
                    checkpoint_item.time_ns / 1_000_000,
                    checkpoint_item.memory_bytes,
                });
            }
        }
    };
    
    // Performance metrics collector
    pub const MetricsCollector = struct {
        const Self = @This();
        
        metrics: std.StringHashMap(Metric),
        
        pub const Metric = struct {
            count: u64 = 0,
            total_time_ns: u64 = 0,
            min_time_ns: u64 = std.math.maxInt(u64),
            max_time_ns: u64 = 0,
            total_memory_bytes: u64 = 0,
            
            pub inline fn addMeasurement(self: *Metric, time_ns: u64, memory_bytes: usize) void {
                self.count += 1;
                self.total_time_ns += time_ns;
                self.min_time_ns = @min(self.min_time_ns, time_ns);
                self.max_time_ns = @max(self.max_time_ns, time_ns);
                self.total_memory_bytes += memory_bytes;
            }
            
            pub inline fn getAverageTime(self: *const Metric) f64 {
                if (self.count == 0) return 0.0;
                return @as(f64, @floatFromInt(self.total_time_ns)) / @as(f64, @floatFromInt(self.count));
            }
            
            pub inline fn getAverageMemory(self: *const Metric) f64 {
                if (self.count == 0) return 0.0;
                return @as(f64, @floatFromInt(self.total_memory_bytes)) / @as(f64, @floatFromInt(self.count));
            }
            
            pub inline fn getThroughput(self: *const Metric) f64 {
                if (self.total_time_ns == 0) return 0.0;
                return @as(f64, @floatFromInt(self.count)) / (@as(f64, @floatFromInt(self.total_time_ns)) / 1_000_000_000.0);
            }
        };
        
        pub inline fn init() Self {
            return Self{
                .metrics = std.StringHashMap(Metric).init(std.heap.page_allocator),
            };
        }
        
        pub inline fn deinit(self: *Self) void {
            self.metrics.deinit();
        }
        
        pub inline fn record(self: *Self, name: []const u8, time_ns: u64, memory_bytes: usize) !void {
            var metric = self.metrics.get(name) orelse Metric{};
            metric.addMeasurement(time_ns, memory_bytes);
            try self.metrics.put(name, metric);
        }
        
        pub inline fn getMetric(self: *const Self, name: []const u8) ?Metric {
            return self.metrics.get(name);
        }
        
        pub inline fn printSummary(self: *const Self) !void {
            const stderr = std.io.getStdErr().writer();
            try stderr.print("Performance Metrics Summary:\n", .{});
            
            var iterator = self.metrics.iterator();
            while (iterator.next()) |entry| {
                const metric = entry.value_ptr;
                const avg_time_ms = metric.getAverageTime() / 1_000_000;
                const throughput = metric.getThroughput();
                
                try stderr.print("  {s}: {d} ops, avg {d:.2}ms, {d:.2} ops/sec\n", .{
                    entry.key_ptr.*,
                    metric.count,
                    avg_time_ms,
                    throughput,
                });
            }
        }
    };
};

// Benchmark result structure
pub const BenchmarkResult = struct {
    total_time_ns: u64,
    avg_time_ns: u64,
    operations_per_second: f64,
    iterations: u32,
    operation_name: []const u8,
};

// Memory usage structure
pub const MemoryUsage = struct {
    operation: []const u8,
    start_bytes: usize,
    end_bytes: usize,
    peak_bytes: usize,
    delta_bytes: usize,
};

// Get current memory usage (simplified)
inline fn getCurrentMemoryUsage() usize {
    // This is a simplified implementation
    // In a real system, you might use platform-specific APIs
    return 0;
}

// Performance error types
pub const PerformanceError = error{
    BenchmarkFailed,
    MeasurementFailed,
    ProfilerError,
    MetricsError,
};
