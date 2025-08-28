// Nen IO Library - Batching Module
// Implements batching patterns from nen-db for I/O operations
// All functions are inline for maximum performance

const std = @import("std");
const config = @import("config.zig");

// Generic batch operation structure
pub const BatchOp = struct {
    id: u64,
    data: []const u8,
    timestamp: u64,
    priority: u8,
    
    pub inline fn init(id: u64, data: []const u8, priority: u8) @This() {
        return @This(){
            .id = id,
            .data = data,
            .timestamp = std.time.nanoTimestamp(),
            .priority = priority,
        };
    }
};

// File I/O batching (following nen-db WAL patterns)
pub const FileBatch = struct {
    const Self = @This();
    
    // Static allocation like your nen-db pools
    pending_writes: [config.batching.file_batch_size]BatchOp = undefined,
    write_count: u32 = 0,
    writes_since_sync: u32 = 0,
    
    // Pre-allocated buffers (like your entry_buf)
    write_buffer: [config.batching.file_message_size_max * config.batching.file_batch_size]u8 = undefined,
    buffer_pos: usize = 0,
    
    pub inline fn init() Self {
        return Self{};
    }
    
    pub inline fn addWrite(self: *Self, data: []const u8, priority: u8) !void {
        if (self.write_count >= config.batching.file_batch_size) {
            return error.BatchFull;
        }
        
        const op = BatchOp.init(self.write_count, data, priority);
        self.pending_writes[self.write_count] = op;
        self.write_count += 1;
        
        // Copy data to pre-allocated buffer
        if (self.buffer_pos + data.len <= self.write_buffer.len) {
            @memcpy(self.write_buffer[self.buffer_pos..][0..data.len], data);
            self.buffer_pos += data.len;
        }
    }
    
    pub inline fn shouldSync(self: Self) bool {
        return self.writes_since_sync >= config.batching.file_sync_interval;
    }
    
    pub inline fn markSynced(self: *Self) void {
        self.writes_since_sync = 0;
        self.write_count = 0;
        self.buffer_pos = 0;
    }
    
    pub inline fn getBatchData(self: Self) []const u8 {
        return self.write_buffer[0..self.buffer_pos];
    }
    
    pub inline fn getBatchSize(self: Self) u32 {
        return self.write_count;
    }
    
    pub inline fn isEmpty(self: Self) bool {
        return self.write_count == 0;
    }
    
    pub inline fn isFull(self: Self) bool {
        return self.write_count >= config.batching.file_batch_size;
    }
    
    pub inline fn getUtilization(self: Self) f64 {
        return @as(f64, @floatFromInt(self.write_count)) / 
               @as(f64, @floatFromInt(config.batching.file_batch_size));
    }
};

// Network batching for HTTP operations
pub const NetworkBatch = struct {
    const Self = @This();
    
    // Static allocation for network operations
    pending_requests: [config.batching.network_batch_size]BatchOp = undefined,
    request_count: u32 = 0,
    requests_since_sync: u32 = 0,
    
    // Pre-allocated network buffers
    request_buffer: [config.batching.network_buffer_size]u8 = undefined,
    response_buffer: [config.batching.network_buffer_size]u8 = undefined,
    
    pub inline fn init() Self {
        return Self{};
    }
    
    pub inline fn addRequest(self: *Self, data: []const u8, priority: u8) !void {
        if (self.request_count >= config.batching.network_batch_size) {
            return error.BatchFull;
        }
        
        const op = BatchOp.init(self.request_count, data, priority);
        self.pending_requests[self.request_count] = op;
        self.request_count += 1;
    }
    
    pub inline fn shouldSync(self: Self) bool {
        return self.requests_since_sync >= config.batching.network_sync_interval;
    }
    
    pub inline fn markSynced(self: *Self) void {
        self.requests_since_sync = 0;
        self.request_count = 0;
    }
    
    pub inline fn getBatchSize(self: Self) u32 {
        return self.request_count;
    }
    
    pub inline fn isEmpty(self: Self) bool {
        return self.request_count == 0;
    }
    
    pub inline fn isFull(self: Self) bool {
        return self.request_count >= config.batching.network_batch_size;
    }
};

// Memory operation batching
pub const MemoryBatch = struct {
    const Self = @This();
    
    // Static allocation for memory operations
    pending_ops: [config.batching.memory_batch_size]BatchOp = undefined,
    op_count: u32 = 0,
    ops_since_sync: u32 = 0,
    
    pub inline fn init() Self {
        return Self{};
    }
    
    pub inline fn addOperation(self: *Self, data: []const u8, priority: u8) !void {
        if (self.op_count >= config.batching.memory_batch_size) {
            return error.BatchFull;
        }
        
        const op = BatchOp.init(self.op_count, data, priority);
        self.pending_ops[self.op_count] = op;
        self.op_count += 1;
    }
    
    pub inline fn shouldSync(self: Self) bool {
        return self.ops_since_sync >= config.batching.memory_sync_interval;
    }
    
    pub inline fn markSynced(self: *Self) void {
        self.ops_since_sync = 0;
        self.op_count = 0;
    }
    
    pub inline fn getBatchSize(self: Self) u32 {
        return self.op_count;
    }
};

// Streaming operation batching
pub const StreamBatch = struct {
    const Self = @This();
    
    // Static allocation for streaming operations
    pending_chunks: [config.batching.stream_batch_size]BatchOp = undefined,
    chunk_count: u32 = 0,
    chunks_since_sync: u32 = 0,
    
    // Pre-allocated streaming buffers
    chunk_buffer: [config.batching.stream_batch_size * 1024]u8 = undefined,
    buffer_pos: usize = 0,
    
    pub inline fn init() Self {
        return Self{};
    }
    
    pub inline fn addChunk(self: *Self, data: []const u8, priority: u8) !void {
        if (self.chunk_count >= config.batching.stream_batch_size) {
            return error.BatchFull;
        }
        
        const op = BatchOp.init(self.chunk_count, data, priority);
        self.pending_chunks[self.chunk_count] = op;
        self.chunk_count += 1;
        
        // Copy chunk data to buffer
        if (self.buffer_pos + data.len <= self.chunk_buffer.len) {
            @memcpy(self.chunk_buffer[self.buffer_pos..][0..data.len], data);
            self.buffer_pos += data.len;
        }
    }
    
    pub inline fn shouldSync(self: Self) bool {
        return self.chunks_since_sync >= config.batching.stream_sync_interval;
    }
    
    pub inline fn markSynced(self: *Self) void {
        self.chunks_since_sync = 0;
        self.chunk_count = 0;
        self.buffer_pos = 0;
    }
    
    pub inline fn getBatchData(self: Self) []const u8 {
        return self.chunk_buffer[0..self.buffer_pos];
    }
    
    pub inline fn getBatchSize(self: Self) u32 {
        return self.chunk_count;
    }
};

// Performance metric batching
pub const PerformanceBatch = struct {
    const Self = @This();
    
    // Static allocation for performance metrics
    pending_metrics: [config.batching.perf_batch_size]BatchOp = undefined,
    metric_count: u32 = 0,
    metrics_since_sync: u32 = 0,
    
    pub inline fn init() Self {
        return Self{};
    }
    
    pub inline fn addMetric(self: *Self, data: []const u8, priority: u8) !void {
        if (self.metric_count >= config.batching.perf_batch_size) {
            return error.BatchFull;
        }
        
        const op = BatchOp.init(self.metric_count, data, priority);
        self.pending_metrics[self.metric_count] = op;
        self.metric_count += 1;
    }
    
    pub inline fn shouldSync(self: Self) bool {
        return self.metrics_since_sync >= config.batching.perf_sync_interval;
    }
    
    pub inline fn markSynced(self: *Self) void {
        self.metrics_since_sync = 0;
        self.metric_count = 0;
    }
    
    pub inline fn getBatchSize(self: Self) u32 {
        return self.metric_count;
    }
};

// Batch statistics and monitoring
pub const BatchStats = struct {
    total_operations: u64 = 0,
    total_batches: u64 = 0,
    avg_batch_size: f64 = 0.0,
    max_batch_size: u32 = 0,
    min_batch_size: u32 = 0,
    total_syncs: u64 = 0,
    avg_sync_interval: f64 = 0.0,
    
    pub inline fn updateStats(self: *@This(), batch_size: u32, sync_interval: u32) void {
        self.total_operations += batch_size;
        self.total_batches += 1;
        self.total_syncs += 1;
        
        // Update average batch size
        const new_total = @as(f64, @floatFromInt(self.total_operations));
        const new_count = @as(f64, @floatFromInt(self.total_batches));
        self.avg_batch_size = new_total / new_count;
        
        // Update min/max batch sizes
        if (batch_size > self.max_batch_size) {
            self.max_batch_size = batch_size;
        }
        if (self.min_batch_size == 0 or batch_size < self.min_batch_size) {
            self.min_batch_size = batch_size;
        }
        
        // Update average sync interval
        const new_sync_total = @as(f64, @floatFromInt(sync_interval));
        const new_sync_count = @as(f64, @floatFromInt(self.total_syncs));
        self.avg_sync_interval = new_sync_total / new_sync_count;
    }
    
    pub inline fn getEfficiency(self: @This()) f64 {
        if (self.avg_batch_size == 0) return 0.0;
        return self.avg_batch_size / @as(f64, @floatFromInt(config.batching.file_batch_size));
    }
    
    pub inline fn getThroughput(self: @This()) f64 {
        if (self.avg_sync_interval == 0) return 0.0;
        return self.avg_batch_size / self.avg_sync_interval;
    }
};
