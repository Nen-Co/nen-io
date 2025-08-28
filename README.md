# Nen IO Library

A high-performance, zero-allocation I/O library for Zig that provides streaming, file operations, and network capabilities with static memory pools.

## Features

- **Zero Dynamic Allocation**: Uses static memory pools for predictable performance
- **Inline Functions**: Critical operations are marked inline for maximum performance
- **Streaming Support**: Efficient processing of large files and data streams
- **File Operations**: Static memory file reading, writing, and validation
- **Network Support**: HTTP JSON parsing and response creation
- **Memory Mapping**: High-performance file parsing with memory mapping
- **Performance Monitoring**: Built-in benchmarking and performance tracking
- **Error Handling**: Comprehensive error handling with context

## Architecture

The library is designed around several core principles:

1. **Static Memory**: All operations use pre-allocated buffers
2. **Inline Performance**: Critical functions are marked inline
3. **Streaming**: Large data can be processed in chunks
4. **Zero Copy**: Minimize memory copying where possible
5. **Error Context**: Rich error information with file positions

## Usage

### Basic File Operations

```zig
const io = @import("nen-io");

// Read JSON from file
const value = try io.JsonFile.readStatic("data.json");

// Write JSON to file
try io.JsonFile.writeStatic("output.json", value);

// Validate JSON file
try io.JsonFile.validateFile("data.json");
```

### Streaming Parsing

```zig
const io = @import("nen-io");

var parser = io.StreamingJsonParser.init();
defer parser.deinit();

try parser.openFile("large_file.json");
try parser.parseFile();

const stats = parser.getStats();
std.debug.print("Parsed {d} bytes in {d} chunks\n", .{
    stats.bytes_read, 
    stats.chunks_parsed
});
```

### Performance Monitoring

```zig
const io = @import("nen-io");

// Monitor single operation
try io.JsonPerformance.monitorParsing("parse_large_file", parseFile);

// Benchmark multiple iterations
const results = try io.JsonPerformance.benchmark("parse_json", 1000, parseJson);
std.debug.print("Average time: {d}ns\n", .{results.avg_time_ns});
```

### Network Operations

```zig
const io = @import("nen-io");

// Parse HTTP response
const value = try io.JsonNetwork.parseHttpResponse(http_response);

// Create HTTP response
const response = try io.JsonNetwork.createHttpResponse(json_value, 200);
```

## Integration with Nen Ecosystem

This library is designed to work seamlessly with other Nen libraries:

- **nen-json**: JSON parsing and manipulation
- **nendb**: Database operations
- **nenflow**: Workflow processing

## Performance Targets

- **Parse Speed**: Target 2+ GB/s for JSON parsing
- **Memory Overhead**: <5% memory overhead
- **Startup Time**: <10ms initialization
- **Buffer Utilization**: >80% token pool utilization

## Dependencies

- Zig 0.14.1+
- Standard library only (no external dependencies)

## Building

```bash
# Build library
zig build

# Run tests
zig build test

# Run performance tests
zig build test-perf

# Run examples
zig build examples
```

## License

MIT License - see LICENSE file for details.

## Contributing

Contributions are welcome! Please see CONTRIBUTING.md for guidelines.
