// Nen IO Library - Basic Usage Example
// Demonstrates the validation-first approach and edge case handling

const std = @import("std");
const io = @import("../src/lib.zig");

pub fn main() !void {
    std.debug.print("🚀 Nen IO Library - Validation-First Example\n", .{});
    std.debug.print("=============================================\n\n", .{});

    // Example 1: Input validation before processing
    try exampleInputValidation();
    
    // Example 2: Edge case handling
    try exampleEdgeCaseHandling();
    
    // Example 3: Performance monitoring with validation
    try examplePerformanceMonitoring();
    
    // Example 4: Error prevention through validation
    try exampleErrorPrevention();
    
    std.debug.print("\n🎉 All examples completed successfully!\n", .{});
}

fn exampleInputValidation() !void {
    std.debug.print("📝 Example 1: Input Validation Before Processing\n", .{});
    
    const test_cases = [_][]const u8{
        "{\"name\":\"valid\",\"value\":42}",           // Valid JSON
        "",                                            // Empty input
        "   \n\t\r  ",                                // Whitespace only
        "abc{\"invalid\":123}",                       // Invalid start
        "{\"nested\":{\"deep\":{\"structure\":{}}}}", // Deep nesting
        "{\"unterminated\":\"string",                 // Unterminated string
    };
    
    for (test_cases, 0..) |test_case, i| {
        std.debug.print("  Test case {d}: ", .{i + 1});
        
        // Validate input before processing
        const validation_result = io.JsonValidator.validateInput(test_case);
        
        if (validation_result.isSuccess()) {
            std.debug.print("✅ Valid - proceeding with processing\n", .{});
            
            // Safe to process - validation passed
            try processValidJson(test_case);
        } else {
            const error = validation_result.getError().?;
            const position = validation_result.getPosition();
            
            std.debug.print("❌ Invalid: {s} at position {d}\n", .{ 
                error.getDescription(), 
                position 
            });
            
            // Handle invalid input gracefully
            try handleInvalidInput(test_case, error, position);
        }
    }
    
    std.debug.print("  ✅ Input validation example completed\n\n", .{});
}

fn exampleEdgeCaseHandling() !void {
    std.debug.print("🔧 Example 2: Edge Case Handling\n", .{});
    
    // Handle empty input
    const empty_input = "";
    if (empty_input.len == 0) {
        const default_json = io.EdgeCaseHandler.handleEmptyInput();
        std.debug.print("  📭 Empty input handled: '{s}'\n", .{default_json});
    }
    
    // Handle whitespace-only input
    const whitespace_input = "   \n\t\r  ";
    if (std.mem.trim(u8, whitespace_input, " \t\n\r").len == 0) {
        const default_json = io.EdgeCaseHandler.handleWhitespaceInput();
        std.debug.print("  📄 Whitespace input handled: '{s}'\n", .{default_json});
    }
    
    // Handle oversized input
    const oversized_input = "{\"very\":\"long string that exceeds reasonable limits and should be truncated\"}";
    const max_size = 30;
    const truncated = io.EdgeCaseHandler.truncateOversizedInput(oversized_input, max_size);
    std.debug.print("  📏 Oversized input truncated: '{s}' (max: {d})\n", .{truncated, max_size});
    
    // Handle line ending normalization
    const mixed_line_endings = "{\"test\":\"line1\r\nline2\rline3\nline4\"}";
    var buffer: [100]u8 = undefined;
    const normalized = io.EdgeCaseHandler.normalizeLineEndings(mixed_line_endings, &buffer);
    std.debug.print("  🔄 Line endings normalized: {d} bytes\n", .{normalized.len});
    
    std.debug.print("  ✅ Edge case handling example completed\n\n", .{});
}

fn examplePerformanceMonitoring() !void {
    std.debug.print("⚡ Example 3: Performance Monitoring with Validation\n", .{});
    
    const test_json = "{\"test\":\"value\",\"array\":[1,2,3,4,5]}";
    
    // Monitor validation performance
    try io.JsonPerformance.monitorParsing("json_validation", struct {
        fn run() !void {
            const result = io.JsonValidator.validateInput(test_json);
            if (!result.isSuccess()) {
                return error.ValidationFailed;
            }
        }
    }.run);
    
    // Benchmark validation operations
    const benchmark_results = try io.JsonPerformance.benchmark("validation_benchmark", 1000, struct {
        fn run() !void {
            const result = io.JsonValidator.validateInput(test_json);
            if (!result.isSuccess()) {
                return error.ValidationFailed;
            }
        }
    }.run);
    
    std.debug.print("  📊 Validation benchmark: {d} ops/sec (avg {d}ns)\n", .{
        @as(u64, @intFromFloat(benchmark_results.operations_per_second)),
        benchmark_results.avg_time_ns
    });
    
    // Use profiler for detailed analysis
    var profiler = io.JsonPerformance.Profiler.init();
    defer profiler.deinit();
    
    profiler.start();
    
    // Validate input
    const result = io.JsonValidator.validateInput(test_json);
    try profiler.checkpoint("input_validation");
    
    // Process if valid
    if (result.isSuccess()) {
        try processValidJson(test_json);
        try profiler.checkpoint("json_processing");
    }
    
    try profiler.printResults();
    
    std.debug.print("  ✅ Performance monitoring example completed\n\n", .{});
}

fn exampleErrorPrevention() !void {
    std.debug.print("🛡️ Example 4: Error Prevention Through Validation\n", .{});
    
    // Simulate processing multiple files with validation
    const file_paths = [_][]const u8{
        "data1.json",
        "data2.json", 
        "data3.json",
        "nonexistent.json",
    };
    
    for (file_paths) |file_path| {
        std.debug.print("  📁 Processing: {s}\n", .{file_path});
        
        // Validate file before processing
        if (!io.JsonFile.isReadable(file_path)) {
            std.debug.print("    ⚠️ File not readable, skipping\n", .{});
            continue;
        }
        
        // Get file size and validate
        const file_size = io.JsonFile.getFileSize(file_path) catch |err| {
            std.debug.print("    ❌ Error getting file size: {s}\n", .{@errorName(err)});
            continue;
        };
        
        if (!io.JsonValidator.validateFileSize(file_size)) {
            std.debug.print("    ❌ File too large ({d} bytes), skipping\n", .{file_size});
            continue;
        }
        
        // File is valid, proceed with processing
        std.debug.print("    ✅ File validated, processing...\n", .{});
        
        // Validate JSON content
        io.JsonFile.validateFile(file_path) catch |err| {
            std.debug.print("    ❌ JSON validation failed: {s}\n", .{@errorName(err)});
            continue;
        };
        
        std.debug.print("    ✅ File processed successfully\n", .{});
    }
    
    std.debug.print("  ✅ Error prevention example completed\n\n", .{});
}

// Helper functions

fn processValidJson(json_string: []const u8) !void {
    // Simulate JSON processing
    var token_count: u32 = 0;
    var nesting_depth: u8 = 0;
    
    for (json_string) |char| {
        switch (char) {
            '{', '[' => {
                nesting_depth += 1;
                token_count += 1;
            },
            '}', ']' => {
                if (nesting_depth > 0) {
                    nesting_depth -= 1;
                }
                token_count += 1;
            },
            '"' => token_count += 1,
            '0'...'9', '-', '+' => token_count += 1,
            't', 'f', 'n' => token_count += 1,
            else => {},
        }
    }
    
    std.debug.print("    📊 Processed: {d} tokens, max nesting: {d}\n", .{token_count, nesting_depth});
}

fn handleInvalidInput(input: []const u8, error: io.validation.ValidationError, position: usize) !void {
    // Handle different types of validation errors
    switch (error) {
        .EmptyInput => {
            std.debug.print("    🔄 Replacing empty input with default JSON\n", .{});
        },
        .WhitespaceOnly => {
            std.debug.print("    🔄 Replacing whitespace with default JSON\n", .{});
        },
        .InputTooLarge => {
            std.debug.print("    ✂️ Input too large, consider streaming approach\n", .{});
        },
        .NestingTooDeep => {
            std.debug.print("    ⚠️ Nesting too deep, check JSON structure\n", .{});
        },
        .UnterminatedString => {
            std.debug.print("    🔍 Unterminated string at position {d}\n", .{position});
        },
        .UnmatchedClosing => {
            std.debug.print("    🔍 Unmatched closing bracket at position {d}\n", .{position});
        },
        .UnmatchedOpening => {
            std.debug.print("    🔍 Unmatched opening bracket at position {d}\n", .{position});
        },
        .InvalidStart => {
            std.debug.print("    🔍 Invalid JSON start at position {d}\n", .{position});
        },
        else => {
            std.debug.print("    ❓ Unknown validation error: {s}\n", .{error.getDescription()});
        },
    }
}
