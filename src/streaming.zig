// Nen IO Streaming Module
// Provides streaming JSON parsing for large files and data streams
// All functions are inline for maximum performance

const std = @import("std");
const config = @import("lib.zig").config;

// Streaming JSON parser for large files
pub const StreamingJsonParser = struct {
    const Self = @This();
    
    // File reading state
    file: ?std.fs.File = null,
    buffer: [config.default_buffer_size]u8 = undefined,
    buffer_pos: usize = 0,
    buffer_len: usize = 0,
    
    // Parsing state
    in_object: bool = false,
    in_array: bool = false,
    nesting_depth: u8 = 0,
    line_number: u32 = 1,
    column_number: u32 = 1,
    
    // Statistics
    bytes_read: u64 = 0,
    chunks_parsed: u32 = 0,
    parse_time_ns: u64 = 0,
    parse_speed_mb_s: f64 = 0.0,
    
    // Token tracking
    tokens_processed: u32 = 0,
    objects_parsed: u32 = 0,
    arrays_parsed: u32 = 0,
    strings_parsed: u32 = 0,
    numbers_parsed: u32 = 0,
    
    pub const Stats = struct {
        bytes_read: u64 = 0,
        chunks_parsed: u32 = 0,
        parse_time_ns: u64 = 0,
        parse_speed_mb_s: f64 = 0.0,
        memory_used_bytes: usize = 0,
        tokens_processed: u32 = 0,
        objects_parsed: u32 = 0,
        arrays_parsed: u32 = 0,
        strings_parsed: u32 = 0,
        numbers_parsed: u32 = 0,
    };
    
    pub inline fn init() Self {
        return Self{};
    }
    
    pub inline fn deinit(self: *Self) void {
        if (self.file) |file| {
            file.close();
        }
    }
    
    // Open file for streaming parsing
    pub inline fn openFile(self: *Self, file_path: []const u8) !void {
        self.file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_only });
        self.buffer_pos = 0;
        self.buffer_len = 0;
        self.bytes_read = 0;
        self.chunks_parsed = 0;
        self.nesting_depth = 0;
        self.line_number = 1;
        self.column_number = 1;
        self.tokens_processed = 0;
        self.objects_parsed = 0;
        self.arrays_parsed = 0;
        self.strings_parsed = 0;
        self.numbers_parsed = 0;
    }
    
    // Parse JSON file in chunks
    pub inline fn parseFile(self: *Self) !void {
        const start_time = std.time.nanoTimestamp();
        
        while (true) {
            const bytes_read = try self.readChunk();
            if (bytes_read == 0) break;
            
            try self.parseChunk();
            self.chunks_parsed += 1;
        }
        
        const end_time = std.time.nanoTimestamp();
        self.parse_time_ns = @as(u64, @intCast(end_time - start_time));
        
        if (self.parse_time_ns > 0) {
            const bytes_per_ns = @as(f64, @floatFromInt(self.bytes_read)) / @as(f64, @floatFromInt(self.parse_time_ns));
            self.parse_speed_mb_s = bytes_per_ns * 1000.0;
        }
    }
    
    // Read next chunk from file
    inline fn readChunk(self: *Self) !usize {
        if (self.file == null) return 0;
        
        const file = self.file.?;
        const bytes_read = try file.read(&self.buffer);
        self.buffer_len = bytes_read;
        self.buffer_pos = 0;
        self.bytes_read += bytes_read;
        
        return bytes_read;
    }
    
    // Parse a single chunk
    inline fn parseChunk(self: *Self) !void {
        if (self.buffer_len == 0) return;
        
        // Simple token counting for statistics
        try self.countTokensInChunk();
        
        // Update line and column numbers
        try self.updateLineColumn();
    }
    
    // Count tokens in chunk for statistics
    inline fn countTokensInChunk(self: *Self) !void {
        var pos: usize = 0;
        while (pos < self.buffer_len) : (pos += 1) {
            const char = self.buffer[pos];
            switch (char) {
                '{' => {
                    self.objects_parsed += 1;
                    self.tokens_processed += 1;
                    self.nesting_depth += 1;
                },
                '}' => {
                    self.tokens_processed += 1;
                    if (self.nesting_depth > 0) {
                        self.nesting_depth -= 1;
                    }
                },
                '[' => {
                    self.arrays_parsed += 1;
                    self.tokens_processed += 1;
                    self.nesting_depth += 1;
                },
                ']' => {
                    self.tokens_processed += 1;
                    if (self.nesting_depth > 0) {
                        self.nesting_depth -= 1;
                    }
                },
                '"' => {
                    self.strings_parsed += 1;
                    self.tokens_processed += 1;
                    // Skip to end of string
                    pos += 1;
                    while (pos < self.buffer_len and self.buffer[pos] != '"') : (pos += 1) {
                        if (self.buffer[pos] == '\\') pos += 1;
                    }
                },
                '0'...'9', '-', '+' => {
                    self.numbers_parsed += 1;
                    self.tokens_processed += 1;
                    // Skip to end of number
                    pos += 1;
                    while (pos < self.buffer_len) : (pos += 1) {
                        const c = self.buffer[pos];
                        if ((c < '0' or c > '9') and c != '.' and c != 'e' and c != 'E' and c != '+' and c != '-') {
                            break;
                        }
                    }
                    pos -= 1; // Adjust for loop increment
                },
                't' => {
                    self.tokens_processed += 1;
                    // Skip "true"
                    if (pos + 3 < self.buffer_len and 
                        self.buffer[pos + 1] == 'r' and 
                        self.buffer[pos + 2] == 'u' and 
                        self.buffer[pos + 3] == 'e') {
                        pos += 3;
                    }
                },
                'f' => {
                    self.tokens_processed += 1;
                    // Skip "false"
                    if (pos + 4 < self.buffer_len and 
                        self.buffer[pos + 1] == 'a' and 
                        self.buffer[pos + 2] == 'l' and 
                        self.buffer[pos + 3] == 's' and 
                        self.buffer[pos + 4] == 'e') {
                        pos += 4;
                    }
                },
                'n' => {
                    self.tokens_processed += 1;
                    // Skip "null"
                    if (pos + 3 < self.buffer_len and 
                        self.buffer[pos + 1] == 'u' and 
                        self.buffer[pos + 2] == 'l' and 
                        self.buffer[pos + 3] == 'l') {
                        pos += 3;
                    }
                },
                else => {
                    // Skip whitespace and other characters
                },
            }
        }
    }
    
    // Update line and column tracking
    inline fn updateLineColumn(self: *Self) !void {
        for (self.buffer[0..self.buffer_len]) |char| {
            switch (char) {
                '\n' => {
                    self.line_number += 1;
                    self.column_number = 1;
                },
                '\r' => {
                    // Handle \r\n sequence
                    self.column_number = 1;
                },
                else => {
                    self.column_number += 1;
                },
            }
        }
    }
    
    // Get parsing statistics
    pub inline fn getStats(self: *const Self) Stats {
        return Stats{
            .bytes_read = self.bytes_read,
            .chunks_parsed = self.chunks_parsed,
            .parse_time_ns = self.parse_time_ns,
            .parse_speed_mb_s = self.parse_speed_mb_s,
            .memory_used_bytes = self.buffer.len,
            .tokens_processed = self.tokens_processed,
            .objects_parsed = self.objects_parsed,
            .arrays_parsed = self.arrays_parsed,
            .strings_parsed = self.strings_parsed,
            .numbers_parsed = self.numbers_parsed,
        };
    }
    
    // Get current position information
    pub inline fn getPosition(self: *const Self) struct { line: u32, column: u32 } {
        return .{
            .line = self.line_number,
            .column = self.column_number,
        };
    }
    
    // Reset parser state
    pub inline fn reset(self: *Self) void {
        self.buffer_pos = 0;
        self.buffer_len = 0;
        self.bytes_read = 0;
        self.chunks_parsed = 0;
        self.nesting_depth = 0;
        self.line_number = 1;
        self.column_number = 1;
        self.tokens_processed = 0;
        self.objects_parsed = 0;
        self.arrays_parsed = 0;
        self.strings_parsed = 0;
        self.numbers_parsed = 0;
        self.parse_time_ns = 0;
        self.parse_speed_mb_s = 0.0;
    }
    
    // Check if parser is in a valid state
    pub inline fn isValid(self: *const Self) bool {
        return self.nesting_depth == 0 and self.file != null;
    }
    
    // Get current nesting depth
    pub inline fn getNestingDepth(self: *const Self) u8 {
        return self.nesting_depth;
    }
    
    // Check if currently parsing an object
    pub inline fn isInObject(self: *const Self) bool {
        return self.in_object;
    }
    
    // Check if currently parsing an array
    pub inline fn isInArray(self: *const Self) bool {
        return self.in_array;
    }
    
    // Get buffer utilization percentage
    pub inline fn getBufferUtilization(self: *const Self) f64 {
        if (self.buffer.len == 0) return 0.0;
        return @as(f64, @floatFromInt(self.buffer_len)) / @as(f64, @floatFromInt(self.buffer.len));
    }
    
    // Get memory efficiency (bytes per token)
    pub inline fn getMemoryEfficiency(self: *const Self) f64 {
        if (self.tokens_processed == 0) return 0.0;
        return @as(f64, @floatFromInt(self.bytes_read)) / @as(f64, @floatFromInt(self.tokens_processed));
    }
};
