// Nen IO File Operations Module
// Provides file-based JSON operations with static memory
// All functions are inline for maximum performance

const std = @import("std");
const config = @import("lib.zig").config;

// File-based JSON operations
pub const JsonFile = struct {
    // Read JSON from file with static memory
    pub inline fn readStatic(file_path: []const u8) ![]const u8 {
        const file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_only });
        defer file.close();
        
        const stat = try file.stat();
        if (stat.size > config.max_file_size) {
            return error.FileTooLarge;
        }
        
        var reader = file.reader();
        var buffer: [config.default_buffer_size]u8 = undefined;
        var json_string = std.ArrayList(u8).init(std.heap.page_allocator);
        defer json_string.deinit();
        
        while (true) {
            const bytes_read = try reader.read(&buffer);
            if (bytes_read == 0) break;
            try json_string.appendSlice(buffer[0..bytes_read]);
        }
        
        return json_string.toOwnedSlice();
    }
    
    // Write JSON to file
    pub inline fn writeStatic(file_path: []const u8, json_string: []const u8) !void {
        const file = try std.fs.cwd().createFile(file_path, .{});
        defer file.close();
        
        try file.writeAll(json_string);
    }
    
    // Validate JSON file without parsing to memory
    pub inline fn validateFile(file_path: []const u8) !void {
        const file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_only });
        defer file.close();
        
        const stat = try file.stat();
        if (stat.size > config.max_file_size) {
            return error.FileTooLarge;
        }
        
        var reader = file.reader();
        var buffer: [config.default_buffer_size]u8 = undefined;
        
        var nesting_depth: u8 = 0;
        var in_string: bool = false;
        var escape_next: bool = false;
        var line_number: u32 = 1;
        var column_number: u32 = 1;
        
        while (true) {
            const bytes_read = try reader.read(&buffer);
            if (bytes_read == 0) break;
            
            for (buffer[0..bytes_read]) |char| {
                if (escape_next) {
                    escape_next = false;
                    column_number += 1;
                    continue;
                }
                
                switch (char) {
                    '"' => {
                        in_string = !in_string;
                        column_number += 1;
                    },
                    '\\' => {
                        if (in_string) {
                            escape_next = true;
                        }
                        column_number += 1;
                    },
                    '{' => {
                        if (!in_string) {
                            nesting_depth += 1;
                            if (nesting_depth > config.max_nesting_depth) {
                                return error.NestingTooDeep;
                            }
                        }
                        column_number += 1;
                    },
                    '}' => {
                        if (!in_string) {
                            if (nesting_depth == 0) {
                                return error.UnexpectedClosingBrace;
                            }
                            nesting_depth -= 1;
                        }
                        column_number += 1;
                    },
                    '[' => {
                        if (!in_string) {
                            nesting_depth += 1;
                            if (nesting_depth > config.max_nesting_depth) {
                                return error.NestingTooDeep;
                            }
                        }
                        column_number += 1;
                    },
                    ']' => {
                        if (!in_string) {
                            if (nesting_depth == 0) {
                                return error.UnexpectedClosingBracket;
                            }
                            nesting_depth -= 1;
                        }
                        column_number += 1;
                    },
                    '\n' => {
                        line_number += 1;
                        column_number = 1;
                    },
                    '\r' => {
                        column_number = 1;
                    },
                    else => {
                        column_number += 1;
                    },
                }
            }
        }
        
        if (in_string) {
            return error.UnterminatedString;
        }
        
        if (nesting_depth != 0) {
            return error.UnmatchedBrackets;
        }
    }
    
    // Get file statistics
    pub inline fn getFileStats(file_path: []const u8) !FileStats {
        const file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_only });
        defer file.close();
        
        const stat = try file.stat();
        const start_time = std.time.nanoTimestamp();
        
        var reader = file.reader();
        var buffer: [config.default_buffer_size]u8 = undefined;
        
        var is_valid = true;
        var tokens_count: u32 = 0;
        var nesting_depth: u8 = 0;
        var in_string: bool = false;
        var escape_next: bool = false;
        
        while (true) {
            const bytes_read = reader.read(&buffer) catch {
                is_valid = false;
                break;
            };
            if (bytes_read == 0) break;
            
            for (buffer[0..bytes_read]) |char| {
                if (escape_next) {
                    escape_next = false;
                    continue;
                }
                
                switch (char) {
                    '"' => {
                        in_string = !in_string;
                        tokens_count += 1;
                    },
                    '\\' => {
                        if (in_string) {
                            escape_next = true;
                        }
                    },
                    '{', '[', '}', ']', ':', ',', 't', 'f', 'n' => {
                        if (!in_string) {
                            tokens_count += 1;
                            if (char == '{' or char == '[') {
                                nesting_depth += 1;
                            } else if (char == '}' or char == ']') {
                                if (nesting_depth > 0) {
                                    nesting_depth -= 1;
                                }
                            }
                        }
                    },
                    '0'...'9', '-', '+' => {
                        if (!in_string) {
                            tokens_count += 1;
                        }
                    },
                    else => {
                        // Skip whitespace and other characters
                    },
                }
            }
        }
        
        const end_time = std.time.nanoTimestamp();
        const parse_time = @as(u64, @intCast(end_time - start_time));
        
        return FileStats{
            .size_bytes = stat.size,
            .is_valid_json = is_valid,
            .parse_time_ns = parse_time,
            .tokens_count = tokens_count,
            .max_nesting_depth = nesting_depth,
        };
    }
    
    // Copy JSON file with validation
    pub inline fn copyJsonFile(src_path: []const u8, dst_path: []const u8) !void {
        // First validate the source file
        try validateFile(src_path);
        
        // Then copy it
        const src_file = try std.fs.cwd().openFile(src_path, .{ .mode = .read_only });
        defer src_file.close();
        
        const dst_file = try std.fs.cwd().createFile(dst_path, .{});
        defer dst_file.close();
        
        try src_file.copy(dst_file);
    }
    
    // Append JSON to existing file
    pub inline fn appendJson(file_path: []const u8, json_string: []const u8) !void {
        const file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_write });
        defer file.close();
        
        try file.seekTo(file.getEndPos());
        try file.writeAll(json_string);
    }
    
    // Check if file exists and is readable
    pub inline fn isReadable(file_path: []const u8) bool {
        std.fs.cwd().access(file_path, .{ .mode = .read_only }) catch return false;
        return true;
    }
    
    // Check if file is writable
    pub inline fn isWritable(file_path: []const u8) bool {
        std.fs.cwd().access(file_path, .{ .mode = .write_only }) catch return false;
        return true;
    }
    
    // Get file size
    pub inline fn getFileSize(file_path: []const u8) !u64 {
        const file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_only });
        defer file.close();
        
        const stat = try file.stat();
        return stat.size;
    }
    
    // Create backup of JSON file
    pub inline fn createBackup(file_path: []const u8) ![]const u8 {
        const backup_path = try std.fmt.allocPrint(
            std.heap.page_allocator,
            "{s}.backup.{d}",
            .{ file_path, std.time.milliTimestamp() }
        );
        
        try copyJsonFile(file_path, backup_path);
        return backup_path;
    }
    
    // Remove backup files
    pub inline fn cleanupBackups(file_path: []const u8, keep_count: u32) !void {
        const dir_path = std.fs.path.dirname(file_path) orelse ".";
        const base_name = std.fs.path.basename(file_path);
        
        var dir = try std.fs.cwd().openDir(dir_path, .{ .iterate = true });
        defer dir.close();
        
        var iterator = dir.iterate();
        var backups = std.ArrayList([]const u8).init(std.heap.page_allocator);
        defer backups.deinit();
        
        while (iterator.next()) |entry| {
            if (std.mem.startsWith(u8, entry.name, base_name) and 
                std.mem.endsWith(u8, entry.name, ".backup")) {
                try backups.append(entry.name);
            }
        }
        
        // Sort by modification time (newest first)
        std.mem.sort([]const u8, backups.items, {}, struct {
            fn lessThan(_: void, a: []const u8, b: []const u8) bool {
                const a_stat = std.fs.cwd().stat(a) catch return false;
                const b_stat = std.fs.cwd().stat(b) catch return false;
                return a_stat.mtime > b_stat.mtime;
            }
        }.lessThan);
        
        // Remove old backups
        if (backups.items.len > keep_count) {
            for (backups.items[keep_count..]) |backup| {
                try std.fs.cwd().deleteFile(backup);
            }
        }
    }
};

// File statistics structure
pub const FileStats = struct {
    size_bytes: u64,
    is_valid_json: bool,
    parse_time_ns: u64,
    tokens_count: u32,
    max_nesting_depth: u8,
};

// Error types for file operations
pub const FileError = error{
    FileNotFound,
    FileTooLarge,
    NestingTooDeep,
    UnterminatedString,
    UnexpectedClosingBrace,
    UnexpectedClosingBracket,
    UnmatchedBrackets,
    InvalidJson,
    BackupFailed,
    CleanupFailed,
};
