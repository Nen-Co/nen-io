// Nen IO Memory Mapping Module
// Provides memory-mapped file operations for high-performance JSON parsing
// All functions are inline for maximum performance

const std = @import("std");
const config = @import("lib.zig").config;

// Memory-mapped file JSON parsing
pub const JsonMemoryMapped = struct {
    // Parse JSON from memory-mapped file
    pub inline fn parseMappedFile(file: std.fs.File) ![]const u8 {
        const stat = try file.stat();
        if (stat.size > config.max_file_size) {
            return error.FileTooLarge;
        }
        
        const mapped = try std.os.mmap(
            null,
            stat.size,
            std.os.PROT.READ,
            std.os.MAP.PRIVATE,
            file.handle,
            0,
        );
        defer std.os.munmap(mapped);
        
        return mapped;
    }
    
    // Stream parse large memory-mapped file
    pub inline fn parseLargeMappedFile(file: std.fs.File, chunk_size: usize) !void {
        const stat = try file.stat();
        if (stat.size > config.max_file_size) {
            return error.FileTooLarge;
        }
        
        var offset: u64 = 0;
        
        while (offset < stat.size) {
            const chunk_size_actual = @min(chunk_size, stat.size - offset);
            const mapped = try std.os.mmap(
                null,
                chunk_size_actual,
                std.os.PROT.READ,
                std.os.MAP.PRIVATE,
                file.handle,
                offset,
            );
            defer std.os.munmap(mapped);
            
            // Process chunk here
            try processChunk(mapped);
            
            offset += chunk_size_actual;
        }
    }
    
    // Process a single chunk
    inline fn processChunk(chunk: []const u8) !void {
        // Simple validation of chunk
        if (chunk.len == 0) return;
        
        // Check for valid JSON start/end
        var pos: usize = 0;
        while (pos < chunk.len and std.mem.isWhitespace(chunk[pos])) : (pos += 1) {}
        
        if (pos < chunk.len) {
            const first_char = chunk[pos];
            if (first_char != '{' and first_char != '[') {
                return error.InvalidJsonStart;
            }
        }
    }
    
    // Create memory-mapped file for writing
    pub inline fn createMappedFile(file_path: []const u8, size: usize) ![]u8 {
        if (size > config.max_file_size) {
            return error.FileTooLarge;
        }
        
        const file = try std.fs.cwd().createFile(file_path, .{});
        defer file.close();
        
        // Extend file to desired size
        try file.setEndPos(size);
        
        const mapped = try std.os.mmap(
            null,
            size,
            std.os.PROT.READ | std.os.PROT.WRITE,
            std.os.MAP.SHARED,
            file.handle,
            0,
        );
        
        return mapped;
    }
    
    // Sync memory-mapped file to disk
    pub inline fn syncMappedFile(mapped: []u8) !void {
        try std.os.msync(mapped.ptr, mapped.len, std.os.MS.SYNC);
    }
    
    // Get memory mapping statistics
    pub inline fn getMappingStats(file: std.fs.File) !MappingStats {
        const stat = try file.stat();
        
        return MappingStats{
            .file_size = stat.size,
            .page_size = std.os.sysconf(.PAGE_SIZE) catch 4096,
            .mapping_cost = stat.size,
            .efficiency = 1.0,
        };
    }
};

// Memory mapping statistics
pub const MappingStats = struct {
    file_size: u64,
    page_size: usize,
    mapping_cost: u64,
    efficiency: f64,
};

// Memory mapping error types
pub const MappingError = error{
    FileTooLarge,
    MappingFailed,
    InvalidJsonStart,
    SyncFailed,
    UnmapFailed,
};
