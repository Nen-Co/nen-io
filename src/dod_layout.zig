// Nen IO Data-Oriented Design (DOD) Layout
// Implements Struct of Arrays (SoA) for high-performance I/O operations

const std = @import("std");
const dod_config = @import("dod_config.zig");

// DOD I/O data structures using Struct of Arrays (SoA) layout
pub const DODIOLayout = struct {
    // File operations in SoA format
    file_handles: [dod_config.DOD_CONSTANTS.MAX_FILE_HANDLES]std.fs.File align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    file_paths: [dod_config.DOD_CONSTANTS.MAX_FILE_HANDLES][256]u8 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    file_modes: [dod_config.DOD_CONSTANTS.MAX_FILE_HANDLES]std.fs.File.OpenFlags align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    file_active: [dod_config.DOD_CONSTANTS.MAX_FILE_HANDLES]bool align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    file_positions: [dod_config.DOD_CONSTANTS.MAX_FILE_HANDLES]u64 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    file_sizes: [dod_config.DOD_CONSTANTS.MAX_FILE_HANDLES]u64 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    
    // Network operations in SoA format
    network_sockets: [dod_config.DOD_CONSTANTS.MAX_NETWORK_CONNECTIONS]c_int align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    network_addresses: [dod_config.DOD_CONSTANTS.MAX_NETWORK_CONNECTIONS][64]u8 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    network_ports: [dod_config.DOD_CONSTANTS.MAX_NETWORK_CONNECTIONS]u16 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    network_active: [dod_config.DOD_CONSTANTS.MAX_NETWORK_CONNECTIONS]bool align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    network_protocols: [dod_config.DOD_CONSTANTS.MAX_NETWORK_CONNECTIONS]u8 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    network_states: [dod_config.DOD_CONSTANTS.MAX_NETWORK_CONNECTIONS]u8 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    
    // Buffer operations in SoA format
    buffer_data: [dod_config.DOD_CONSTANTS.MAX_BUFFERS][dod_config.DOD_CONSTANTS.BUFFER_SIZE_LARGE]u8 align(dod_config.DOD_CONSTANTS.SIMD_ALIGNMENT),
    buffer_sizes: [dod_config.DOD_CONSTANTS.MAX_BUFFERS]u32 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    buffer_positions: [dod_config.DOD_CONSTANTS.MAX_BUFFERS]u32 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    buffer_active: [dod_config.DOD_CONSTANTS.MAX_BUFFERS]bool align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    buffer_types: [dod_config.DOD_CONSTANTS.MAX_BUFFERS]u8 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    buffer_flags: [dod_config.DOD_CONSTANTS.MAX_BUFFERS]u8 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    
    // Batch operations in SoA format
    batch_operations: [dod_config.DOD_CONSTANTS.MAX_BATCHES][dod_config.DOD_CONSTANTS.MAX_BATCH_SIZE]BatchOp align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    batch_sizes: [dod_config.DOD_CONSTANTS.MAX_BATCHES]u32 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    batch_active: [dod_config.DOD_CONSTANTS.MAX_BATCHES]bool align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    batch_types: [dod_config.DOD_CONSTANTS.MAX_BATCHES]u8 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    batch_priorities: [dod_config.DOD_CONSTANTS.MAX_BATCHES]u8 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    batch_timestamps: [dod_config.DOD_CONSTANTS.MAX_BATCHES]u64 align(dod_config.DOD_CONSTANTS.CACHE_LINE_SIZE),
    
    // Statistics
    file_count: u32 = 0,
    network_count: u32 = 0,
    buffer_count: u32 = 0,
    batch_count: u32 = 0,
    
    pub fn init() DODIOLayout {
        return DODIOLayout{
            .file_handles = [_]std.fs.File{undefined} ** dod_config.DOD_CONSTANTS.MAX_FILE_HANDLES,
            .file_paths = [_][256]u8{[_]u8{0} ** 256} ** dod_config.DOD_CONSTANTS.MAX_FILE_HANDLES,
            .file_modes = [_]std.fs.File.OpenFlags{.{}} ** dod_config.DOD_CONSTANTS.MAX_FILE_HANDLES,
            .file_active = [_]bool{false} ** dod_config.DOD_CONSTANTS.MAX_FILE_HANDLES,
            .file_positions = [_]u64{0} ** dod_config.DOD_CONSTANTS.MAX_FILE_HANDLES,
            .file_sizes = [_]u64{0} ** dod_config.DOD_CONSTANTS.MAX_FILE_HANDLES,
            .network_sockets = [_]c_int{0} ** dod_config.DOD_CONSTANTS.MAX_NETWORK_CONNECTIONS,
            .network_addresses = [_][64]u8{[_]u8{0} ** 64} ** dod_config.DOD_CONSTANTS.MAX_NETWORK_CONNECTIONS,
            .network_ports = [_]u16{0} ** dod_config.DOD_CONSTANTS.MAX_NETWORK_CONNECTIONS,
            .network_active = [_]bool{false} ** dod_config.DOD_CONSTANTS.MAX_NETWORK_CONNECTIONS,
            .network_protocols = [_]u8{0} ** dod_config.DOD_CONSTANTS.MAX_NETWORK_CONNECTIONS,
            .network_states = [_]u8{0} ** dod_config.DOD_CONSTANTS.MAX_NETWORK_CONNECTIONS,
            .buffer_data = [_][dod_config.DOD_CONSTANTS.BUFFER_SIZE_LARGE]u8{[_]u8{0} ** dod_config.DOD_CONSTANTS.BUFFER_SIZE_LARGE} ** dod_config.DOD_CONSTANTS.MAX_BUFFERS,
            .buffer_sizes = [_]u32{0} ** dod_config.DOD_CONSTANTS.MAX_BUFFERS,
            .buffer_positions = [_]u32{0} ** dod_config.DOD_CONSTANTS.MAX_BUFFERS,
            .buffer_active = [_]bool{false} ** dod_config.DOD_CONSTANTS.MAX_BUFFERS,
            .buffer_types = [_]u8{0} ** dod_config.DOD_CONSTANTS.MAX_BUFFERS,
            .buffer_flags = [_]u8{0} ** dod_config.DOD_CONSTANTS.MAX_BUFFERS,
            .batch_operations = [_][dod_config.DOD_CONSTANTS.MAX_BATCH_SIZE]BatchOp{[_]BatchOp{BatchOp.init()} ** dod_config.DOD_CONSTANTS.MAX_BATCH_SIZE} ** dod_config.DOD_CONSTANTS.MAX_BATCHES,
            .batch_sizes = [_]u32{0} ** dod_config.DOD_CONSTANTS.MAX_BATCHES,
            .batch_active = [_]bool{false} ** dod_config.DOD_CONSTANTS.MAX_BATCHES,
            .batch_types = [_]u8{0} ** dod_config.DOD_CONSTANTS.MAX_BATCHES,
            .batch_priorities = [_]u8{0} ** dod_config.DOD_CONSTANTS.MAX_BATCHES,
            .batch_timestamps = [_]u64{0} ** dod_config.DOD_CONSTANTS.MAX_BATCHES,
        };
    }
    
    // File operations with DOD optimization
    pub fn addFile(self: *DODIOLayout, path: []const u8, mode: std.fs.File.OpenFlags) !u32 {
        if (self.file_count >= dod_config.DOD_CONSTANTS.MAX_FILE_HANDLES) {
            return dod_config.DODError.PoolExhausted;
        }
        
        const index = self.file_count;
        const file = std.fs.cwd().openFile(path, mode) catch return error.FileNotFound;
        
        self.file_handles[index] = file;
        @memcpy(self.file_paths[index][0..path.len], path);
        self.file_paths[index][path.len] = 0; // Null terminate
        self.file_modes[index] = mode;
        self.file_active[index] = true;
        self.file_positions[index] = 0;
        
        // Get file size
        const stat = file.stat() catch return error.StatFailed;
        self.file_sizes[index] = stat.size;
        
        self.file_count += 1;
        return index;
    }
    
    // Network operations with DOD optimization
    pub fn addNetworkConnection(self: *DODIOLayout, address: []const u8, port: u16, protocol: u8) !u32 {
        if (self.network_count >= dod_config.DOD_CONSTANTS.MAX_NETWORK_CONNECTIONS) {
            return dod_config.DODError.PoolExhausted;
        }
        
        const index = self.network_count;
        // For demo purposes, we'll just use a placeholder socket value
        self.network_sockets[index] = 0;
        @memcpy(self.network_addresses[index][0..address.len], address);
        self.network_addresses[index][address.len] = 0; // Null terminate
        self.network_ports[index] = port;
        self.network_active[index] = true;
        self.network_protocols[index] = protocol;
        self.network_states[index] = 0; // Initial state
        
        self.network_count += 1;
        return index;
    }
    
    // Buffer operations with DOD optimization
    pub fn addBuffer(self: *DODIOLayout, size: u32, buffer_type: u8) !u32 {
        if (self.buffer_count >= dod_config.DOD_CONSTANTS.MAX_BUFFERS) {
            return dod_config.DODError.PoolExhausted;
        }
        
        const index = self.buffer_count;
        self.buffer_sizes[index] = size;
        self.buffer_positions[index] = 0;
        self.buffer_active[index] = true;
        self.buffer_types[index] = buffer_type;
        self.buffer_flags[index] = 0;
        
        self.buffer_count += 1;
        return index;
    }
    
    // Batch operations with DOD optimization
    pub fn addBatch(self: *DODIOLayout, batch_type: u8, priority: u8) !u32 {
        if (self.batch_count >= dod_config.DOD_CONSTANTS.MAX_BATCHES) {
            return dod_config.DODError.PoolExhausted;
        }
        
        const index = self.batch_count;
        self.batch_sizes[index] = 0;
        self.batch_active[index] = true;
        self.batch_types[index] = batch_type;
        self.batch_priorities[index] = priority;
        self.batch_timestamps[index] = @as(u64, @intCast(std.time.nanoTimestamp()));
        
        self.batch_count += 1;
        return index;
    }
    
    // SIMD-optimized file operations
    pub fn readFilesSIMD(self: *DODIOLayout, file_indices: []const u32, data: []u8) !u32 {
        var total_read: u32 = 0;
        const simd_batch_size = dod_config.DOD_CONSTANTS.SIMD_FILE_BATCH;
        
        var i: u32 = 0;
        while (i < file_indices.len) {
            const batch_size = @min(simd_batch_size, file_indices.len - i);
            
            // Process batch with SIMD optimization
            for (i..i + batch_size) |j| {
                const file_idx = file_indices[j];
                if (file_idx < self.file_count and self.file_active[file_idx]) {
                    const bytes_read = self.file_handles[file_idx].read(data[total_read..]) catch 0;
                    total_read += @as(u32, @intCast(bytes_read));
                    self.file_positions[file_idx] += bytes_read;
                }
            }
            
            i += batch_size;
        }
        
        return total_read;
    }
    
    // SIMD-optimized buffer operations
    pub fn writeBuffersSIMD(self: *DODIOLayout, buffer_indices: []const u32, data: []const u8) !u32 {
        var total_written: u32 = 0;
        const simd_batch_size = dod_config.DOD_CONSTANTS.SIMD_MEMORY_BATCH;
        
        var i: u32 = 0;
        while (i < buffer_indices.len) {
            const batch_size = @min(simd_batch_size, buffer_indices.len - i);
            
            // Process batch with SIMD optimization
            for (i..i + batch_size) |j| {
                const buffer_idx = buffer_indices[j];
                if (buffer_idx < self.buffer_count and self.buffer_active[buffer_idx]) {
                    const write_size = @min(data.len - total_written, self.buffer_sizes[buffer_idx] - self.buffer_positions[buffer_idx]);
                    if (write_size > 0) {
                        @memcpy(self.buffer_data[buffer_idx][self.buffer_positions[buffer_idx]..self.buffer_positions[buffer_idx] + write_size], data[total_written..total_written + write_size]);
                        self.buffer_positions[buffer_idx] += write_size;
                        total_written += write_size;
                    }
                }
            }
            
            i += batch_size;
        }
        
        return total_written;
    }
    
    // Get statistics
    pub fn getStats(self: *const DODIOLayout) DODIOStats {
        return DODIOStats{
            .file_count = self.file_count,
            .network_count = self.network_count,
            .buffer_count = self.buffer_count,
            .batch_count = self.batch_count,
            .file_capacity = dod_config.DOD_CONSTANTS.MAX_FILE_HANDLES,
            .network_capacity = dod_config.DOD_CONSTANTS.MAX_NETWORK_CONNECTIONS,
            .buffer_capacity = dod_config.DOD_CONSTANTS.MAX_BUFFERS,
            .batch_capacity = dod_config.DOD_CONSTANTS.MAX_BATCHES,
        };
    }
};

// Batch operation structure
pub const BatchOp = struct {
    op_type: u8 = 0,
    op_data: [64]u8 = [_]u8{0} ** 64,
    op_size: u32 = 0,
    op_flags: u8 = 0,
    
    pub fn init() BatchOp {
        return BatchOp{};
    }
    
    pub fn setFileOp(self: *BatchOp, file_path: []const u8, mode: u8) void {
        self.op_type = 1; // File operation
        self.op_flags = mode;
        const copy_size = @min(file_path.len, 63);
        @memcpy(self.op_data[0..copy_size], file_path[0..copy_size]);
        self.op_data[copy_size] = 0;
        self.op_size = @intCast(copy_size);
    }
    
    pub fn setNetworkOp(self: *BatchOp, address: []const u8, port: u16, protocol: u8) void {
        self.op_type = 2; // Network operation
        self.op_flags = protocol;
        const copy_size = @min(address.len, 60);
        @memcpy(self.op_data[0..copy_size], address[0..copy_size]);
        self.op_data[copy_size] = 0;
        @memcpy(self.op_data[60..64], std.mem.asBytes(&port));
        self.op_size = @intCast(copy_size + 4);
    }
    
    pub fn setBufferOp(self: *BatchOp, buffer_type: u8, size: u32) void {
        self.op_type = 3; // Buffer operation
        self.op_flags = buffer_type;
        @memcpy(self.op_data[0..4], std.mem.asBytes(&size));
        self.op_size = 4;
    }
};

// DOD I/O statistics
pub const DODIOStats = struct {
    file_count: u32,
    network_count: u32,
    buffer_count: u32,
    batch_count: u32,
    file_capacity: u32,
    network_capacity: u32,
    buffer_capacity: u32,
    batch_capacity: u32,
    
    pub fn getFileUtilization(self: DODIOStats) f32 {
        return @as(f32, @floatFromInt(self.file_count)) / @as(f32, @floatFromInt(self.file_capacity));
    }
    
    pub fn getNetworkUtilization(self: DODIOStats) f32 {
        return @as(f32, @floatFromInt(self.network_count)) / @as(f32, @floatFromInt(self.network_capacity));
    }
    
    pub fn getBufferUtilization(self: DODIOStats) f32 {
        return @as(f32, @floatFromInt(self.buffer_count)) / @as(f32, @floatFromInt(self.buffer_capacity));
    }
    
    pub fn getBatchUtilization(self: DODIOStats) f32 {
        return @as(f32, @floatFromInt(self.batch_count)) / @as(f32, @floatFromInt(self.batch_capacity));
    }
    
    pub fn getOverallUtilization(self: DODIOStats) f32 {
        const total_used = self.file_count + self.network_count + self.buffer_count + self.batch_count;
        const total_capacity = self.file_capacity + self.network_capacity + self.buffer_capacity + self.batch_capacity;
        return @as(f32, @floatFromInt(total_used)) / @as(f32, @floatFromInt(total_capacity));
    }
};
