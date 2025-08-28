// Nen IO Library - Unit Tests
// Tests the validation-first approach and edge case handling

const std = @import("std");
const io = @import("../../src/lib.zig");

test "JsonValidator - valid JSON input" {
    const valid_json = "{\"name\":\"test\",\"value\":42}";
    const result = io.JsonValidator.validateInput(valid_json);
    
    try std.testing.expect(result.isSuccess());
    try std.testing.expect(result.getError() == null);
    try std.testing.expect(result.getPosition() > 0);
}

test "JsonValidator - empty input" {
    const empty_input = "";
    const result = io.JsonValidator.validateInput(empty_input);
    
    try std.testing.expect(!result.isSuccess());
    try std.testing.expect(result.getError() == .EmptyInput);
    try std.testing.expect(result.getPosition() == 0);
}

test "JsonValidator - whitespace only" {
    const whitespace = "   \n\t\r  ";
    const result = io.JsonValidator.validateInput(whitespace);
    
    try std.testing.expect(!result.isSuccess());
    try std.testing.expect(result.getError() == .WhitespaceOnly);
}

test "JsonValidator - invalid start character" {
    const invalid_start = "abc{\"test\":123}";
    const result = io.JsonValidator.validateInput(invalid_start);
    
    try std.testing.expect(!result.isSuccess());
    try std.testing.expect(result.getError() == .InvalidStart);
}

test "JsonValidator - nesting too deep" {
    var deep_nesting = std.ArrayList(u8).init(std.testing.allocator);
    defer deep_nesting.deinit();
    
    // Create JSON with excessive nesting
    for (0..100) |_| {
        try deep_nesting.appendSlice("{");
    }
    for (0..100) |_| {
        try deep_nesting.appendSlice("}");
    }
    
    const result = io.JsonValidator.validateInput(deep_nesting.items);
    try std.testing.expect(!result.isSuccess());
    try std.testing.expect(result.getError() == .NestingTooDeep);
}

test "JsonValidator - unmatched brackets" {
    const unmatched = "{\"test\":[1,2,3}";
    const result = io.JsonValidator.validateInput(unmatched);
    
    try std.testing.expect(!result.isSuccess());
    try std.testing.expect(result.getError() == .UnmatchedClosing);
}

test "JsonValidator - unterminated string" {
    const unterminated = "{\"test\":\"unterminated";
    const result = io.JsonValidator.validateInput(unterminated);
    
    try std.testing.expect(!result.isSuccess());
    try std.testing.expect(result.getError() == .UnterminatedString);
}

test "JsonValidator - file size validation" {
    try std.testing.expect(io.JsonValidator.validateFileSize(1024));
    try std.testing.expect(io.JsonValidator.validateFileSize(io.config.max_file_size));
    try std.testing.expect(!io.JsonValidator.validateFileSize(io.config.max_file_size + 1));
}

test "JsonValidator - buffer size validation" {
    try std.testing.expect(io.JsonValidator.validateBufferSize(io.config.default_buffer_size));
    try std.testing.expect(io.JsonValidator.validateBufferSize(io.config.large_buffer_size));
    try std.testing.expect(!io.JsonValidator.validateBufferSize(0));
    try std.testing.expect(!io.JsonValidator.validateBufferSize(io.config.huge_buffer_size + 1));
}

test "JsonValidator - chunk size validation" {
    try std.testing.expect(io.JsonValidator.validateChunkSize(io.config.default_chunk_size));
    try std.testing.expect(io.JsonValidator.validateChunkSize(io.config.streaming_chunk_size));
    try std.testing.expect(!io.JsonValidator.validateChunkSize(0));
    try std.testing.expect(!io.JsonValidator.validateChunkSize(io.config.streaming_chunk_size + 1));
}

test "JsonValidator - nesting depth validation" {
    try std.testing.expect(io.JsonValidator.validateNestingDepth(0));
    try std.testing.expect(io.JsonValidator.validateNestingDepth(io.config.max_nesting_depth));
    try std.testing.expect(!io.JsonValidator.validateNestingDepth(io.config.max_nesting_depth + 1));
}

test "JsonValidator - line length validation" {
    try std.testing.expect(io.JsonValidator.validateLineLength(100));
    try std.testing.expect(io.JsonValidator.validateLineLength(io.config.max_line_length));
    try std.testing.expect(!io.JsonValidator.validateLineLength(io.config.max_line_length + 1));
}

test "JsonValidator - likely valid JSON heuristic" {
    try std.testing.expect(io.JsonValidator.isLikelyValidJson("{\"test\":123}"));
    try std.testing.expect(io.JsonValidator.isLikelyValidJson("[1,2,3]"));
    try std.testing.expect(!io.JsonValidator.isLikelyValidJson("abc"));
    try std.testing.expect(!io.JsonValidator.isLikelyValidJson(""));
    try std.testing.expect(!io.JsonValidator.isLikelyValidJson("  "));
}

test "JsonValidator - safe buffer size calculation" {
    try std.testing.expectEqual(io.config.default_buffer_size, io.JsonValidator.getSafeBufferSize(100));
    try std.testing.expectEqual(io.config.large_buffer_size, io.JsonValidator.getSafeBufferSize(io.config.default_buffer_size + 1000));
    try std.testing.expectEqual(io.config.huge_buffer_size, io.JsonValidator.getSafeBufferSize(io.config.large_buffer_size + 1000));
}

test "JsonValidator - safe chunk size calculation" {
    try std.testing.expectEqual(100, io.JsonValidator.getSafeChunkSize(100));
    try std.testing.expectEqual(io.config.streaming_chunk_size, io.JsonValidator.getSafeChunkSize(io.config.default_chunk_size + 1000));
    try std.testing.expectEqual(io.config.memory_mapped_chunk, io.JsonValidator.getSafeChunkSize(io.config.streaming_chunk_size + 1000));
}

test "EdgeCaseHandler - empty input handling" {
    const result = io.EdgeCaseHandler.handleEmptyInput();
    try std.testing.expectEqualStrings("{}", result);
}

test "EdgeCaseHandler - whitespace input handling" {
    const result = io.EdgeCaseHandler.handleWhitespaceInput();
    try std.testing.expectEqualStrings("{}", result);
}

test "EdgeCaseHandler - oversized input truncation" {
    const oversized = "{\"test\":\"very long string that exceeds the limit\"}";
    const max_size = 20;
    const truncated = io.EdgeCaseHandler.truncateOversizedInput(oversized, max_size);
    
    try std.testing.expect(truncated.len <= max_size);
    try std.testing.expect(truncated.len > 0);
}

test "EdgeCaseHandler - line ending normalization" {
    const input = "{\"test\":\"line1\r\nline2\rline3\nline4\"}";
    var buffer: [100]u8 = undefined;
    const normalized = io.EdgeCaseHandler.normalizeLineEndings(input, &buffer);
    
    try std.testing.expect(normalized.len > 0);
    // Should not contain \r characters
    for (normalized) |char| {
        try std.testing.expect(char != '\r');
    }
}

test "EdgeCaseHandler - special character escaping" {
    const input = "{\"test\":\"quotes\"and\nnewlines\tand\rreturns\"}";
    var buffer: [100]u8 = undefined;
    const escaped = io.EdgeCaseHandler.escapeSpecialChars(input, &buffer);
    
    try std.testing.expect(escaped.len > 0);
    // Should contain escaped characters
    const has_escaped_quotes = std.mem.indexOf(u8, escaped, "\\\"") != null;
    try std.testing.expect(has_escaped_quotes);
}

test "ValidationError - error descriptions" {
    try std.testing.expectEqualStrings("No error", io.validation.ValidationError.None.getDescription());
    try std.testing.expectEqualStrings("Input is empty", io.validation.ValidationError.EmptyInput.getDescription());
    try std.testing.expectEqualStrings("Input exceeds maximum size", io.validation.ValidationError.InputTooLarge.getDescription());
}

test "ValidationError - recoverable errors" {
    try std.testing.expect(io.validation.ValidationError.EmptyInput.isRecoverable());
    try std.testing.expect(io.validation.ValidationError.WhitespaceOnly.isRecoverable());
    try std.testing.expect(!io.validation.ValidationError.InvalidStart.isRecoverable());
    try std.testing.expect(!io.validation.ValidationError.NestingTooDeep.isRecoverable());
}

test "StreamingJsonParser - basic functionality" {
    var parser = io.StreamingJsonParser.init();
    defer parser.deinit();
    
    try std.testing.expect(parser.isValid());
    try std.testing.expectEqual(@as(u8, 0), parser.getNestingDepth());
    try std.testing.expect(!parser.isInObject());
    try std.testing.expect(!parser.isInArray());
}

test "StreamingJsonParser - statistics tracking" {
    var parser = io.StreamingJsonParser.init();
    defer parser.deinit();
    
    const stats = parser.getStats();
    try std.testing.expectEqual(@as(u64, 0), stats.bytes_read);
    try std.testing.expectEqual(@as(u32, 0), stats.chunks_parsed);
    try std.testing.expectEqual(@as(u32, 0), stats.tokens_processed);
}

test "StreamingJsonParser - buffer utilization" {
    var parser = io.StreamingJsonParser.init();
    defer parser.deinit();
    
    const utilization = parser.getBufferUtilization();
    try std.testing.expect(utilization >= 0.0 and utilization <= 1.0);
}

test "StreamingJsonParser - memory efficiency" {
    var parser = io.StreamingJsonParser.init();
    defer parser.deinit();
    
    const efficiency = parser.getMemoryEfficiency();
    try std.testing.expect(efficiency >= 0.0);
}

test "JsonFile - basic file operations" {
    const test_content = "{\"test\":\"value\"}";
    const test_file = "test_file.json";
    
    // Write file
    try io.JsonFile.writeStatic(test_file, test_content);
    
    // Check if readable
    try std.testing.expect(io.JsonFile.isReadable(test_file));
    
    // Get file size
    const size = try io.JsonFile.getFileSize(test_file);
    try std.testing.expectEqual(test_content.len, size);
    
    // Clean up
    try std.fs.cwd().deleteFile(test_file);
}

test "JsonFile - file validation" {
    const valid_content = "{\"test\":\"value\"}";
    const test_file = "valid_test.json";
    
    try io.JsonFile.writeStatic(test_file, valid_content);
    try io.JsonFile.validateFile(test_file);
    
    // Clean up
    try std.fs.cwd().deleteFile(test_file);
}

test "JsonFile - file statistics" {
    const test_content = "{\"test\":\"value\",\"array\":[1,2,3]}";
    const test_file = "stats_test.json";
    
    try io.JsonFile.writeStatic(test_file, test_content);
    const stats = try io.JsonFile.getFileStats(test_file);
    
    try std.testing.expectEqual(test_content.len, stats.size_bytes);
    try std.testing.expect(stats.is_valid_json);
    try std.testing.expect(stats.tokens_count > 0);
    
    // Clean up
    try std.fs.cwd().deleteFile(test_file);
}

test "JsonNetwork - HTTP response parsing" {
    const http_response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"status\":\"success\"}";
    const json_content = try io.JsonNetwork.parseHttpResponse(http_response);
    
    try std.testing.expectEqualStrings("{\"status\":\"success\"}", json_content);
}

test "JsonNetwork - HTTP response creation" {
    const json_body = "{\"message\":\"Hello World\"}";
    const response = try io.JsonNetwork.createHttpResponse(json_body, 200);
    
    try std.testing.expect(std.mem.indexOf(u8, response, "HTTP/1.1 200 OK") != null);
    try std.testing.expect(std.mem.indexOf(u8, response, json_body) != null);
}

test "JsonNetwork - HTTP headers parsing" {
    const http_response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 25\r\n\r\n{\"status\":\"success\"}";
    const headers = try io.JsonNetwork.parseHttpHeaders(http_response);
    
    try std.testing.expectEqual(@as(u16, 200), headers.status_code);
    try std.testing.expectEqualStrings("OK", headers.status_text);
    try std.testing.expectEqualStrings("application/json", headers.get("Content-Type").?);
    try std.testing.expectEqualStrings("25", headers.get("Content-Length").?);
}

test "JsonPerformance - basic monitoring" {
    var operation_called = false;
    const test_operation = struct {
        fn run() !void {
            operation_called = true;
        }
    }.run;
    
    try io.JsonPerformance.monitorParsing("test_operation", test_operation);
    try std.testing.expect(operation_called);
}

test "JsonPerformance - benchmarking" {
    var operation_count: u32 = 0;
    const test_operation = struct {
        fn run() !void {
            operation_count += 1;
        }
    }.run;
    
    const results = try io.JsonPerformance.benchmark("test_benchmark", 100, test_operation);
    
    try std.testing.expectEqual(@as(u32, 100), results.iterations);
    try std.testing.expectEqual(@as(u32, 100), operation_count);
    try std.testing.expect(results.operations_per_second > 0);
}

test "JsonPerformance - profiler" {
    var profiler = io.JsonPerformance.Profiler.init();
    defer profiler.deinit();
    
    profiler.start();
    try profiler.checkpoint("test_checkpoint");
    
    const results = profiler.getResults();
    try std.testing.expectEqual(@as(usize, 1), results.len);
    try std.testing.expectEqualStrings("test_checkpoint", results[0].name);
}

test "JsonPerformance - metrics collector" {
    var collector = io.JsonPerformance.MetricsCollector.init();
    defer collector.deinit();
    
    try collector.record("test_metric", 1000, 1024);
    try collector.record("test_metric", 2000, 2048);
    
    const metric = collector.getMetric("test_metric");
    try std.testing.expect(metric != null);
    try std.testing.expectEqual(@as(u64, 2), metric.?.count);
    try std.testing.expectEqual(@as(u64, 1500), metric.?.getAverageTime());
}

test "JsonErrorHandler - basic error logging" {
    // This should not crash
    try io.JsonErrorHandler.logError(error.TestError, "test_context", null);
}

test "JsonErrorHandler - error formatting" {
    const error_msg = try io.JsonErrorHandler.formatError(error.TestError, 10, 20);
    defer std.testing.allocator.free(error_msg);
    
    try std.testing.expect(std.mem.indexOf(u8, error_msg, "line 10") != null);
    try std.testing.expect(std.mem.indexOf(u8, error_msg, "column 20") != null);
}

test "JsonErrorHandler - error context creation" {
    const context = io.JsonErrorHandler.ErrorContext{
        .operation = "test_operation",
        .file_path = "test.json",
        .line = 5,
        .column = 10,
    };
    
    const error_msg = try io.JsonErrorHandler.createErrorContext(error.TestError, context);
    defer std.testing.allocator.free(error_msg);
    
    try std.testing.expect(std.mem.indexOf(u8, error_msg, "test_operation") != null);
    try std.testing.expect(std.mem.indexOf(u8, error_msg, "test.json") != null);
    try std.testing.expect(std.mem.indexOf(u8, error_msg, "line 5") != null);
    try std.testing.expect(std.mem.indexOf(u8, error_msg, "column 10") != null);
}

test "JsonErrorHandler - error severity" {
    try std.testing.expectEqual(io.JsonErrorHandler.ErrorSeverity.warning, io.JsonErrorHandler.getErrorSeverity(error.FileNotFound));
    try std.testing.expectEqual(io.JsonErrorHandler.ErrorSeverity.error, io.JsonErrorHandler.getErrorSeverity(error.NestingTooDeep));
    try std.testing.expectEqual(io.JsonErrorHandler.ErrorSeverity.critical, io.JsonErrorHandler.getErrorSeverity(error.TokenPoolExhausted));
}

test "JsonErrorHandler - error output formats" {
    const context = io.JsonErrorHandler.ErrorContext{
        .operation = "test",
        .file_path = "test.json",
    };
    
    const text_output = try io.JsonErrorHandler.formatErrorForOutput(error.TestError, context, .text);
    defer std.testing.allocator.free(text_output);
    
    const json_output = try io.JsonErrorHandler.formatErrorForOutput(error.TestError, context, .json);
    defer std.testing.allocator.free(json_output);
    
    try std.testing.expect(text_output.len > 0);
    try std.testing.expect(json_output.len > 0);
    try std.testing.expect(std.mem.startsWith(u8, json_output, "{"));
}

test "JsonErrorHandler - error suggestions" {
    const suggestion = io.JsonErrorHandler.getErrorSuggestion(error.FileNotFound);
    try std.testing.expect(suggestion != null);
    try std.testing.expect(std.mem.indexOf(u8, suggestion.?, "file path") != null);
}

test "JsonErrorHandler - error statistics" {
    var stats = io.JsonErrorHandler.ErrorStats.init();
    defer stats.deinit();
    
    try stats.recordError(error.FileNotFound);
    try stats.recordError(error.FileNotFound);
    try stats.recordError(error.InvalidFormat);
    
    try std.testing.expectEqual(@as(u32, 3), stats.total_errors);
    try std.testing.expectEqual(@as(u32, 2), stats.getErrorCount(error.FileNotFound));
    try std.testing.expectEqual(@as(u32, 1), stats.getErrorCount(error.InvalidFormat));
    
    const most_common = stats.getMostCommonError();
    try std.testing.expect(most_common != null);
    try std.testing.expectEqual(error.FileNotFound, most_common.?);
}
