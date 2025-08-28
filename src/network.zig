// Nen IO Network Module
// Provides HTTP JSON parsing and response creation
// All functions are inline for maximum performance

const std = @import("std");
const config = @import("lib.zig").config;

// Network JSON operations
pub const JsonNetwork = struct {
    // Parse JSON from HTTP response
    pub inline fn parseHttpResponse(response: []const u8) ![]const u8 {
        // Find JSON content in HTTP response
        const json_start = std.mem.indexOf(u8, response, "\r\n\r\n") orelse 0;
        const json_content = response[json_start..];
        
        // Validate that we have JSON content
        if (json_content.len == 0) {
            return error.NoJsonContent;
        }
        
        // Check if content starts with valid JSON
        const trimmed = std.mem.trim(u8, json_content, " \t\n\r");
        if (trimmed.len == 0) {
            return error.EmptyJsonContent;
        }
        
        if (trimmed[0] != '{' and trimmed[0] != '[') {
            return error.InvalidJsonStart;
        }
        
        return trimmed;
    }
    
    // Create JSON HTTP response
    pub inline fn createHttpResponse(json_body: []const u8, status_code: u16) ![]const u8 {
        const status_text = switch (status_code) {
            200 => "OK",
            201 => "Created",
            400 => "Bad Request",
            401 => "Unauthorized",
            403 => "Forbidden",
            404 => "Not Found",
            500 => "Internal Server Error",
            502 => "Bad Gateway",
            503 => "Service Unavailable",
            else => "Unknown",
        };
        
        var response = std.ArrayList(u8).init(std.heap.page_allocator);
        defer response.deinit();
        
        try response.appendSlice("HTTP/1.1 ");
        try response.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d} {s}\r\n", .{ status_code, status_text }));
        try response.appendSlice("Content-Type: application/json; charset=utf-8\r\n");
        try response.appendSlice("Content-Length: ");
        try response.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}\r\n", .{json_body.len}));
        try response.appendSlice("Cache-Control: no-cache\r\n");
        try response.appendSlice("Access-Control-Allow-Origin: *\r\n");
        try response.appendSlice("\r\n");
        try response.appendSlice(json_body);
        
        return response.toOwnedSlice();
    }
    
    // Create HTTP request with JSON body
    pub inline fn createHttpRequest(method: []const u8, url: []const u8, json_body: ?[]const u8, headers: ?[]const u8) ![]const u8 {
        var request = std.ArrayList(u8).init(std.heap.page_allocator);
        defer request.deinit();
        
        try request.appendSlice(method);
        try request.appendSlice(" ");
        try request.appendSlice(url);
        try request.appendSlice(" HTTP/1.1\r\n");
        
        try request.appendSlice("Host: ");
        try request.appendSlice(extractHost(url));
        try request.appendSlice("\r\n");
        
        try request.appendSlice("User-Agent: Nen-IO/1.0\r\n");
        try request.appendSlice("Accept: application/json\r\n");
        
        if (json_body) |body| {
            try request.appendSlice("Content-Type: application/json\r\n");
            try request.appendSlice("Content-Length: ");
            try request.appendSlice(try std.fmt.allocPrint(std.heap.page_allocator, "{d}\r\n", .{body.len}));
        }
        
        if (headers) |custom_headers| {
            try request.appendSlice(custom_headers);
        }
        
        try request.appendSlice("\r\n");
        
        if (json_body) |body| {
            try request.appendSlice(body);
        }
        
        return request.toOwnedSlice();
    }
    
    // Extract host from URL
    inline fn extractHost(url: []const u8) []const u8 {
        if (std.mem.startsWith(u8, url, "http://")) {
            const without_protocol = url[7..];
            const slash_pos = std.mem.indexOf(u8, without_protocol, "/") orelse without_protocol.len;
            return without_protocol[0..slash_pos];
        } else if (std.mem.startsWith(u8, url, "https://")) {
            const without_protocol = url[8..];
            const slash_pos = std.mem.indexOf(u8, without_protocol, "/") orelse without_protocol.len;
            return without_protocol[0..slash_pos];
        } else {
            const slash_pos = std.mem.indexOf(u8, url, "/") orelse url.len;
            return url[0..slash_pos];
        }
    }
    
    // Parse HTTP headers
    pub inline fn parseHttpHeaders(response: []const u8) !HttpHeaders {
        const header_end = std.mem.indexOf(u8, response, "\r\n\r\n") orelse return error.NoHeaders;
        const headers_text = response[0..header_end];
        
        var headers = HttpHeaders.init();
        
        var lines = std.mem.split(u8, headers_text, "\r\n");
        while (lines.next()) |line| {
            if (std.mem.startsWith(u8, line, "HTTP/")) {
                // Parse status line
                var parts = std.mem.split(u8, line, " ");
                _ = parts.next(); // Skip "HTTP/1.1"
                if (parts.next()) |status_code_str| {
                    headers.status_code = std.fmt.parseInt(u16, status_code_str, 10) catch 0;
                }
                if (parts.next()) |status_text| {
                    headers.status_text = status_text;
                }
            } else if (std.mem.indexOf(u8, line, ":") != null) {
                // Parse header line
                const colon_pos = std.mem.indexOf(u8, line, ":") orelse continue;
                const key = std.mem.trim(u8, line[0..colon_pos], " ");
                const value = std.mem.trim(u8, line[colon_pos + 1..], " ");
                
                try headers.set(key, value);
            }
        }
        
        return headers;
    }
    
    // Validate HTTP response
    pub inline fn validateHttpResponse(response: []const u8) !void {
        if (response.len < 12) {
            return error.ResponseTooShort;
        }
        
        if (!std.mem.startsWith(u8, response, "HTTP/")) {
            return error.InvalidHttpResponse;
        }
        
        const header_end = std.mem.indexOf(u8, response, "\r\n\r\n") orelse return error.NoHeaders;
        const headers_text = response[0..header_end];
        
        // Check for required headers
        if (std.mem.indexOf(u8, headers_text, "Content-Type:") == null) {
            return error.MissingContentType;
        }
        
        if (std.mem.indexOf(u8, headers_text, "Content-Length:") == null) {
            return error.MissingContentLength;
        }
    }
    
    // Create CORS headers
    pub inline fn createCorsHeaders() []const u8 {
        return "Access-Control-Allow-Origin: *\r\n" ++
               "Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS\r\n" ++
               "Access-Control-Allow-Headers: Content-Type, Authorization\r\n" ++
               "Access-Control-Max-Age: 86400\r\n";
    }
    
    // Create error response
    pub inline fn createErrorResponse(error_message: []const u8, status_code: u16) ![]const u8 {
        const error_json = try std.fmt.allocPrint(
            std.heap.page_allocator,
            "{{\"error\":\"{s}\",\"status\":{d}}}",
            .{ error_message, status_code }
        );
        defer std.heap.page_allocator.free(error_json);
        
        return createHttpResponse(error_json, status_code);
    }
    
    // Create success response
    pub inline fn createSuccessResponse(data: []const u8) ![]const u8 {
        const success_json = try std.fmt.allocPrint(
            std.heap.page_allocator,
            "{{\"success\":true,\"data\":{s}}}",
            .{ data }
        );
        defer std.heap.page_allocator.free(success_json);
        
        return createHttpResponse(success_json, 200);
    }
};

// HTTP headers structure
pub const HttpHeaders = struct {
    status_code: u16 = 0,
    status_text: []const u8 = "",
    headers: std.StringHashMap([]const u8),
    
    pub inline fn init() HttpHeaders {
        return HttpHeaders{
            .headers = std.StringHashMap([]const u8).init(std.heap.page_allocator),
        };
    }
    
    pub inline fn deinit(self: *HttpHeaders) void {
        self.headers.deinit();
    }
    
    pub inline fn set(self: *HttpHeaders, key: []const u8, value: []const u8) !void {
        try self.headers.put(key, value);
    }
    
    pub inline fn get(self: *const HttpHeaders, key: []const u8) ?[]const u8 {
        return self.headers.get(key);
    }
    
    pub inline fn has(self: *const HttpHeaders, key: []const u8) bool {
        return self.headers.contains(key);
    }
    
    pub inline fn count(self: *const HttpHeaders) u32 {
        return @intCast(self.headers.count());
    }
};

// Network error types
pub const NetworkError = error{
    NoJsonContent,
    EmptyJsonContent,
    InvalidJsonStart,
    ResponseTooShort,
    InvalidHttpResponse,
    NoHeaders,
    MissingContentType,
    MissingContentLength,
    InvalidUrl,
    NetworkTimeout,
    ConnectionFailed,
};
