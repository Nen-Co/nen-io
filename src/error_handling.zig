// Nen IO Error Handling Module
// Provides comprehensive error handling with context and logging
// All functions are inline for maximum performance

const std = @import("std");

// Error handling with nen IO integration
pub const JsonErrorHandler = struct {
    // Log JSON parsing errors with context
    pub inline fn logError(err: anyerror, context: []const u8, file_path: ?[]const u8) !void {
        if (!@import("builtin").is_test) {
            const stderr = std.io.getStdErr().writer();
            
            try stderr.print("JSON Error in {s}: {s}", .{ context, @errorName(err) });
            
            if (file_path) |path| {
                try stderr.print(" (file: {s})", .{path});
            }
            
            try stderr.print("\n", .{});
        }
    }
    
    // Format JSON error with position information
    pub inline fn formatError(err: anyerror, line: u32, column: u32) ![]const u8 {
        return try std.fmt.allocPrint(
            std.heap.page_allocator,
            "JSON Error at line {d}, column {d}: {s}",
            .{ line, column, @errorName(err) }
        );
    }
    
    // Create detailed error context
    pub inline fn createErrorContext(err: anyerror, context: ErrorContext) ![]const u8 {
        var error_msg = std.ArrayList(u8).init(std.heap.page_allocator);
        defer error_msg.deinit();
        
        try error_msg.appendSlice("JSON Error: ");
        try error_msg.appendSlice(@errorName(err));
        try error_msg.appendSlice("\n");
        
        if (context.operation.len > 0) {
            try error_msg.appendSlice("Operation: ");
            try error_msg.appendSlice(context.operation);
            try error_msg.appendSlice("\n");
        }
        
        if (context.file_path.len > 0) {
            try error_msg.appendSlice("File: ");
            try error_msg.appendSlice(context.file_path);
            try error_msg.appendSlice("\n");
        }
        
        if (context.line > 0) {
            try error_msg.appendSlice("Line: ");
            try error_msg.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{context.line}));
            try error_msg.appendSlice("\n");
        }
        
        if (context.column > 0) {
            try error_msg.appendSlice("Column: ");
            try error_msg.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{context.column}));
            try error_msg.appendSlice("\n");
        }
        
        if (context.nesting_depth > 0) {
            try error_msg.appendSlice("Nesting Depth: ");
            try error_msg.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{context.nesting_depth}));
            try error_msg.appendSlice("\n");
        }
        
        if (context.bytes_processed > 0) {
            try error_msg.appendSlice("Bytes Processed: ");
            try error_msg.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{context.bytes_processed}));
            try error_msg.appendSlice("\n");
        }
        
        if (context.tokens_processed > 0) {
            try error_msg.appendSlice("Tokens Processed: ");
            try error_msg.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{context.tokens_processed}));
            try error_msg.appendSlice("\n");
        }
        
        if (context.suggestion.len > 0) {
            try error_msg.appendSlice("Suggestion: ");
            try error_msg.appendSlice(context.suggestion);
            try error_msg.appendSlice("\n");
        }
        
        return error_msg.toOwnedSlice();
    }
    
    // Get error severity level
    pub inline fn getErrorSeverity(err: anyerror) ErrorSeverity {
        return switch (err) {
            error.FileNotFound,
            error.FileTooLarge,
            error.InvalidFormat => .warning,
            
            error.NestingTooDeep,
            error.UnterminatedString,
            error.UnexpectedClosingBrace,
            error.UnexpectedClosingBracket,
            error.UnmatchedBrackets => io.JsonErrorHandler.ErrorSeverity.error,
            
            error.TokenPoolExhausted,
            error.MemoryError,
            error.NetworkError => .critical,
            
            else => .error,
        };
    }
    
    // Format error for different output formats
    pub inline fn formatErrorForOutput(err: anyerror, context: ErrorContext, format: ErrorOutputFormat) ![]const u8 {
        return switch (format) {
            .text => try createErrorContext(err, context),
            .json => try createErrorJson(err, context),
            .xml => try createErrorXml(err, context),
        };
    }
    
    // Create JSON error format
    inline fn createErrorJson(err: anyerror, context: ErrorContext) ![]const u8 {
        var json = std.ArrayList(u8).init(std.heap.page_allocator);
        defer json.deinit();
        
        try json.appendSlice("{");
        try json.appendSlice("\"error\":\"");
        try json.appendSlice(@errorName(err));
        try json.appendSlice("\"");
        
        if (context.operation.len > 0) {
            try json.appendSlice(",\"operation\":\"");
            try json.appendSlice(context.operation);
            try json.appendSlice("\"");
        }
        
        if (context.file_path.len > 0) {
            try json.appendSlice(",\"file\":\"");
            try json.appendSlice(context.file_path);
            try json.appendSlice("\"");
        }
        
        if (context.line > 0) {
            try json.appendSlice(",\"line\":");
            try json.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{context.line}));
        }
        
        if (context.column > 0) {
            try json.appendSlice(",\"column\":");
            try json.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{context.column}));
        }
        
        if (context.nesting_depth > 0) {
            try json.appendSlice(",\"nesting_depth\":");
            try json.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{context.nesting_depth}));
        }
        
        if (context.bytes_processed > 0) {
            try json.appendSlice(",\"bytes_processed\":");
            try json.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{context.bytes_processed}));
        }
        
        if (context.tokens_processed > 0) {
            try json.appendSlice(",\"tokens_processed\":");
            try json.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{context.tokens_processed}));
        }
        
        if (context.suggestion.len > 0) {
            try json.appendSlice(",\"suggestion\":\"");
            try json.appendSlice(context.suggestion);
            try json.appendSlice("\"");
        }
        
        try json.appendSlice("}");
        
        return json.toOwnedSlice();
    }
    
    // Create XML error format
    inline fn createErrorXml(err: anyerror, context: ErrorContext) ![]const u8 {
        var xml = std.ArrayList(u8).init(std.heap.page_allocator);
        defer xml.deinit();
        
        try xml.appendSlice("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
        try xml.appendSlice("<error>\n");
        try xml.appendSlice("  <type>");
        try xml.appendSlice(@errorName(err));
        try xml.appendSlice("</type>\n");
        
        if (context.operation.len > 0) {
            try xml.appendSlice("  <operation>");
            try xml.appendSlice(context.operation);
            try xml.appendSlice("</operation>\n");
        }
        
        if (context.file_path.len > 0) {
            try xml.appendSlice("  <file>");
            try xml.appendSlice(context.file_path);
            try xml.appendSlice("</file>\n");
        }
        
        if (context.line > 0) {
            try xml.appendSlice("  <line>");
            try xml.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{context.line}));
            try xml.appendSlice("</line>\n");
        }
        
        if (context.column > 0) {
            try xml.appendSlice("  <column>");
            try xml.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{context.column}));
            try xml.appendSlice("</column>\n");
        }
        
        if (context.nesting_depth > 0) {
            try xml.appendSlice("  <nesting_depth>");
            try xml.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{context.nesting_depth}));
            try xml.appendSlice("</nesting_depth>\n");
        }
        
        if (context.bytes_processed > 0) {
            try xml.appendSlice("  <bytes_processed>");
            try xml.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{context.bytes_processed}));
            try xml.appendSlice("</bytes_processed>\n");
        }
        
        if (context.tokens_processed > 0) {
            try xml.appendSlice("  <tokens_processed>");
            try xml.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{context.tokens_processed}));
            try xml.appendSlice("</tokens_processed>\n");
        }
        
        if (context.suggestion.len > 0) {
            try xml.appendSlice("  <suggestion>");
            try xml.appendSlice(context.suggestion);
            try xml.appendSlice("</suggestion>\n");
        }
        
        try xml.appendSlice("</error>");
        
        return xml.toOwnedSlice();
    }
    
    // Error recovery suggestions
    pub inline fn getErrorSuggestion(err: anyerror) ?[]const u8 {
        return switch (err) {
            error.FileNotFound => "Check if the file path is correct and the file exists",
            error.FileTooLarge => "Consider using streaming parsing for large files",
            error.NestingTooDeep => "Check for unmatched brackets or excessive nesting",
            error.UnterminatedString => "Check for missing closing quote in string",
            error.UnexpectedClosingBrace => "Check for missing opening brace",
            error.UnexpectedClosingBracket => "Check for missing opening bracket",
            error.UnmatchedBrackets => "Check for balanced brackets and braces",
            error.TokenPoolExhausted => "Increase token pool size or use streaming parser",
            error.MemoryError => "Check available memory or reduce buffer sizes",
            error.NetworkError => "Check network connection and server availability",
            else => null,
        };
    }
    
    // Error statistics collector
    pub const ErrorStats = struct {
        const Self = @This();
        
        error_counts: std.AutoHashMap(anyerror, u32),
        total_errors: u32 = 0,
        
        pub inline fn init() Self {
            return Self{
                .error_counts = std.AutoHashMap(anyerror, u32).init(std.heap.page_allocator),
            };
        }
        
        pub inline fn deinit(self: *Self) void {
            self.error_counts.deinit();
        }
        
        pub inline fn recordError(self: *Self, err: anyerror) !void {
            const current_count = self.error_counts.get(err) orelse 0;
            try self.error_counts.put(err, current_count + 1);
            self.total_errors += 1;
        }
        
        pub inline fn getErrorCount(self: *const Self, err: anyerror) u32 {
            return self.error_counts.get(err) orelse 0;
        }
        
        pub inline fn getMostCommonError(self: *const Self) ?anyerror {
            var max_count: u32 = 0;
            var most_common: ?anyerror = null;
            
            var iterator = self.error_counts.iterator();
            while (iterator.next()) |entry| {
                if (entry.value_ptr.* > max_count) {
                    max_count = entry.value_ptr.*;
                    most_common = entry.key_ptr.*;
                }
            }
            
            return most_common;
        }
        
        pub inline fn printSummary(self: *const Self) !void {
            const stderr = std.io.getStdErr().writer();
            try stderr.print("Error Statistics Summary:\n", .{});
            try stderr.print("Total Errors: {d}\n", .{self.total_errors});
            
            var iterator = self.error_counts.iterator();
            while (iterator.next()) |entry| {
                try stderr.print("  {s}: {d}\n", .{ @errorName(entry.key_ptr.*), entry.value_ptr.* });
            }
        }
    };
};

// Error context structure
pub const ErrorContext = struct {
    operation: []const u8 = "",
    file_path: []const u8 = "",
    line: u32 = 0,
    column: u32 = 0,
    nesting_depth: u8 = 0,
    bytes_processed: u64 = 0,
    tokens_processed: u32 = 0,
    suggestion: []const u8 = "",
};

// Error severity levels
pub const ErrorSeverity = enum {
    warning,
    error,
    critical,
};

// Error output formats
pub const ErrorOutputFormat = enum {
    text,
    json,
    xml,
};

// Error handling error types
pub const ErrorHandlingError = error{
    ContextCreationFailed,
    FormattingFailed,
    OutputGenerationFailed,
    StatisticsError,
};
