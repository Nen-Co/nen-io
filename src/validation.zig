// Nen IO Validation Module
// Focuses on preventing errors through edge case validation
// All functions are inline for maximum performance

const std = @import("std");
const config = @import("config.zig");

// Validation error types (prevented errors)
pub const ValidationError = enum {
    None,
    EmptyInput,
    InputTooLarge,
    WhitespaceOnly,
    InvalidStart,
    NestingTooDeep,
    UnmatchedClosing,
    UnmatchedOpening,
    UnterminatedString,
    InvalidCharacter,
    BufferTooSmall,
    ChunkTooLarge,
    
    pub inline fn getDescription(self: ValidationError) []const u8 {
        return switch (self) {
            .None => "No error",
            .EmptyInput => "Input is empty",
            .InputTooLarge => "Input exceeds maximum size",
            .WhitespaceOnly => "Input contains only whitespace",
            .InvalidStart => "Invalid JSON start character",
            .NestingTooDeep => "Nesting depth exceeds limit",
            .UnmatchedClosing => "Unmatched closing bracket/brace",
            .UnmatchedOpening => "Unmatched opening bracket/brace",
            .UnterminatedString => "Unterminated string",
            .InvalidCharacter => "Invalid character in JSON",
            .BufferTooSmall => "Buffer size too small",
            .ChunkTooLarge => "Chunk size too large",
        };
    }
    
    pub inline fn isRecoverable(self: ValidationError) bool {
        return switch (self) {
            .None, .EmptyInput, .WhitespaceOnly => true,
            .InputTooLarge, .NestingTooDeep, .BufferTooSmall, .ChunkTooLarge => false,
            .InvalidStart, .UnmatchedClosing, .UnmatchedOpening, .UnterminatedString, .InvalidCharacter => false,
        };
    }
};

// Validation result structure
pub const ValidationResult = struct {
    valid: bool,
    validation_error: ValidationError,
    position: usize,
    
    pub inline fn isSuccess(self: ValidationResult) bool {
        return self.valid;
    }
    
    pub inline fn getError(self: ValidationResult) ?ValidationError {
        return if (self.valid) null else self.validation_error;
    }
    
    pub inline fn getPosition(self: ValidationResult) usize {
        return self.position;
    }
};

// Input validation to prevent errors
pub const JsonValidator = struct {
    // Validate JSON string before parsing (prevents most errors)
    pub inline fn validateInput(json_string: []const u8) ValidationResult {
        if (json_string.len == 0) {
            return ValidationResult{ .valid = false, .validation_error = ValidationError.EmptyInput, .position = 0 };
        }
        
        if (json_string.len > config.max_file_size) {
            return ValidationResult{ .valid = false, .validation_error = ValidationError.InputTooLarge, .position = 0 };
        }
        
        // Check for valid JSON start
        var pos: usize = 0;
        while (pos < json_string.len and std.ascii.isWhitespace(json_string[pos])) : (pos += 1) {}
        
        if (pos >= json_string.len) {
            return ValidationResult{ .valid = false, .validation_error = ValidationError.WhitespaceOnly, .position = pos };
        }
        
        const first_char = json_string[pos];
        if (first_char != '{' and first_char != '[') {
            return ValidationResult{ .valid = false, .validation_error = ValidationError.InvalidStart, .position = pos };
        }
        
        // Quick structural validation
        return validateStructure(json_string, pos);
    }
    
    // Validate JSON structure (fast path)
    inline fn validateStructure(json_string: []const u8, start_pos: usize) ValidationResult {
        var nesting_depth: u8 = 0;
        var in_string: bool = false;
        var escape_next: bool = false;
        var pos: usize = start_pos;
        
        while (pos < json_string.len) : (pos += 1) {
            const char = json_string[pos];
            
            if (escape_next) {
                escape_next = false;
                continue;
            }
            
            switch (char) {
                '"' => {
                    in_string = !in_string;
                },
                '\\' => {
                    if (in_string) {
                        escape_next = true;
                    }
                },
                '{', '[' => {
                    if (!in_string) {
                        nesting_depth += 1;
                        if (nesting_depth > config.max_nesting_depth) {
                            return ValidationResult{ .valid = false, .validation_error = ValidationError.NestingTooDeep, .position = pos };
                        }
                    }
                },
                '}', ']' => {
                    if (!in_string) {
                        if (nesting_depth == 0) {
                            return ValidationResult{ .valid = false, .validation_error = ValidationError.UnmatchedClosing, .position = pos };
                        }
                        nesting_depth -= 1;
                    }
                },
                else => {
                    // Continue processing
                },
            }
        }
        
        if (in_string) {
            return ValidationResult{ .valid = false, .validation_error = ValidationError.UnterminatedString, .position = pos };
        }
        
        if (nesting_depth != 0) {
            return ValidationResult{ .valid = false, .validation_error = ValidationError.UnmatchedOpening, .position = pos };
        }
        
        return ValidationResult{ .valid = true, .validation_error = ValidationError.None, .position = pos };
    }
    
    // Validate file size before processing
    pub inline fn validateFileSize(file_size: u64) bool {
        return file_size <= config.max_file_size;
    }
    
    // Validate buffer sizes
    pub inline fn validateBufferSize(buffer_size: usize) bool {
        return buffer_size <= config.huge_buffer_size and buffer_size > 0;
    }
    
    // Validate chunk sizes for streaming
    pub inline fn validateChunkSize(chunk_size: usize) bool {
        return chunk_size <= config.streaming_chunk_size and chunk_size > 0;
    }
    
    // Validate nesting depth
    pub inline fn validateNestingDepth(depth: u8) bool {
        return depth <= config.max_nesting_depth;
    }
    
    // Validate line length
    pub inline fn validateLineLength(length: usize) bool {
        return length <= config.max_line_length;
    }
    
    // Check if input is likely valid JSON (heuristic)
    pub inline fn isLikelyValidJson(input: []const u8) bool {
        if (input.len < 2) return false;
        
        // Check for common JSON patterns
        const trimmed = std.mem.trim(u8, input, " \t\n\r");
        if (trimmed.len == 0) return false;
        
        const first = trimmed[0];
        const last = trimmed[trimmed.len - 1];
        
        // Must start and end with valid JSON delimiters
        const valid_start = first == '{' or first == '[';
        const valid_end = (first == '{' and last == '}') or (first == '[' and last == ']');
        
        return valid_start and valid_end;
    }
    
    // Get safe buffer size for given input
    pub inline fn getSafeBufferSize(input_size: usize) usize {
        if (input_size <= config.default_buffer_size) {
            return config.default_buffer_size;
        } else if (input_size <= config.large_buffer_size) {
            return config.large_buffer_size;
        } else {
            return config.huge_buffer_size;
        }
    }
    
    // Get safe chunk size for streaming
    pub inline fn getSafeChunkSize(input_size: usize) usize {
        if (input_size <= config.default_chunk_size) {
            return input_size;
        } else if (input_size <= config.streaming_chunk_size) {
            return config.streaming_chunk_size;
        } else {
            return config.memory_mapped_chunk;
        }
    }
};

// Edge case handler for graceful degradation
pub const EdgeCaseHandler = struct {
    // Handle edge cases gracefully
    pub inline fn handleEmptyInput() []const u8 {
        return "{}";
    }
    
    pub inline fn handleWhitespaceInput() []const u8 {
        return "{}";
    }
    
    // Truncate oversized input
    pub inline fn truncateOversizedInput(input: []const u8, max_size: usize) []const u8 {
        if (input.len <= max_size) return input;
        
        // Find a safe truncation point
        var pos: usize = max_size;
        while (pos > 0) : (pos -= 1) {
            const char = input[pos];
            if (char == '}' or char == ']') {
                return input[0..pos + 1];
            }
        }
        
        return input[0..max_size];
    }
    
    // Normalize line endings
    pub inline fn normalizeLineEndings(input: []const u8, buffer: []u8) []u8 {
        var out_pos: usize = 0;
        var in_pos: usize = 0;
        
        while (in_pos < input.len and out_pos < buffer.len) : (in_pos += 1) {
            const char = input[in_pos];
            
            if (char == '\r' and in_pos + 1 < input.len and input[in_pos + 1] == '\n') {
                buffer[out_pos] = '\n';
                out_pos += 1;
                in_pos += 1; // Skip the \n
            } else if (char == '\r') {
                buffer[out_pos] = '\n';
                out_pos += 1;
            } else {
                buffer[out_pos] = char;
                out_pos += 1;
            }
        }
        
        return buffer[0..out_pos];
    }
    
    // Escape special characters
    pub inline fn escapeSpecialChars(input: []const u8, buffer: []u8) []u8 {
        var out_pos: usize = 0;
        var in_pos: usize = 0;
        
        while (in_pos < input.len and out_pos < buffer.len) : (in_pos += 1) {
            const char = input[in_pos];
            
            switch (char) {
                '"', '\\', '\n', '\r', '\t' => {
                    if (out_pos + 1 < buffer.len) {
                        buffer[out_pos] = '\\';
                        out_pos += 1;
                        buffer[out_pos] = char;
                        out_pos += 1;
                    }
                },
                else => {
                    if (out_pos < buffer.len) {
                        buffer[out_pos] = char;
                        out_pos += 1;
                    }
                },
            }
        }
        
        return buffer[0..out_pos];
    }
};
