// Nen IO Library - Configuration
// Centralized configuration to avoid circular dependencies

// Buffer sizes for different use cases
pub const default_buffer_size = 4096;        // 4KB - small files
pub const large_buffer_size = 65536;         // 64KB - medium files  
pub const huge_buffer_size = 1048576;        // 1MB - large files

// Chunk sizes for streaming operations
pub const default_chunk_size = 1024;         // 1KB - small chunks
pub const streaming_chunk_size = 65536;      // 64KB - streaming chunks
pub const memory_mapped_chunk = 1048576;     // 1MB - memory mapped chunks

// File size limits
pub const max_file_size = 1073741824;        // 1GB - maximum file size
pub const max_line_length = 1048576;         // 1MB - maximum line length

// JSON parsing limits
pub const max_nesting_depth = 100;           // Maximum nesting depth
pub const max_tokens = 1000000;              // Maximum tokens per file

// Performance thresholds
pub const min_throughput_mb_s = 10.0;        // Minimum acceptable throughput
pub const max_parse_time_ms = 30000;         // Maximum parse time (30 seconds)

// Error handling
pub const max_error_context = 1000;          // Maximum error context length
pub const max_error_suggestions = 5;         // Maximum error suggestions

// Network settings
pub const http_timeout_ms = 30000;           // HTTP timeout (30 seconds)
pub const max_http_headers = 100;            // Maximum HTTP headers
pub const max_http_body_size = 104857600;    // Maximum HTTP body (100MB)

// Memory management
pub const memory_pool_size = 16777216;       // 16MB memory pool
pub const max_memory_usage = 1073741824;     // 1GB maximum memory usage
pub const memory_cleanup_threshold = 0.8;    // Cleanup when 80% full

// Logging and debugging
pub const enable_performance_logging = true;  // Enable performance logging
pub const enable_memory_logging = true;      // Enable memory usage logging
pub const enable_validation_logging = true;   // Enable validation logging

// Batching Configuration - Following nen-db patterns
pub const batching = struct {
    // File I/O batching (like your WAL sync_interval)
    pub const file_sync_interval = 100;          // Sync every 100 operations
    pub const file_batch_size = 8192;            // Max batch size (like your batch_max)
    pub const file_message_size_max = 2048;      // Max message size (like your message_size_max)
    
    // Network batching
    pub const network_batch_size = 100;          // Batch HTTP requests
    pub const network_buffer_size = 8192;        // Network buffer size
    pub const network_sync_interval = 50;        // Sync network operations every 50
    
    // Memory batching
    pub const memory_batch_size = 1024;          // Memory operation batching
    pub const memory_sync_interval = 200;        // Memory sync interval
    
    // Streaming batching
    pub const stream_batch_size = 512;           // Streaming operation batching
    pub const stream_sync_interval = 100;        // Stream sync interval
    
    // Performance batching
    pub const perf_batch_size = 1000;            // Performance metric batching
    pub const perf_sync_interval = 100;          // Performance sync interval
};
