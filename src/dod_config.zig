// Nen IO Data-Oriented Design (DOD) Configuration
// Optimized for high-performance I/O operations with static memory management

const std = @import("std");

// DOD Configuration for nen-io
pub const DODConfig = struct {
    // Buffer configuration
    pub const buffer = struct {
        pub const default_size: u32 = 4096; // 4KB default buffer
        pub const large_size: u32 = 65536; // 64KB large buffer
        pub const huge_size: u32 = 1048576; // 1MB huge buffer
        pub const max_buffers: u32 = 1024; // Maximum number of buffers
        pub const alignment: u32 = 64; // Cache line alignment
    };
    
    // Batch processing configuration
    pub const batching = struct {
        pub const max_batch_size: u32 = 8192; // Maximum operations per batch
        pub const file_batch_size: u32 = 1024; // File operations per batch
        pub const network_batch_size: u32 = 512; // Network operations per batch
        pub const stream_batch_size: u32 = 2048; // Stream operations per batch
        pub const memory_batch_size: u32 = 4096; // Memory operations per batch
    };
    
    // Prefetching configuration
    pub const prefetching = struct {
        pub const enable_hardware_prefetch: bool = true;
        pub const enable_software_prefetch: bool = true;
        pub const prefetch_distance: u32 = 2; // Cache lines ahead
        pub const max_prefetch_requests: u32 = 8; // Maximum concurrent prefetch requests
        pub const file_prefetch_size: u32 = 64; // File prefetch size in KB
        pub const network_prefetch_size: u32 = 32; // Network prefetch size in KB
    };
    
    // SIMD configuration
    pub const simd = struct {
        pub const enable_simd: bool = true;
        pub const simd_width: u32 = 8; // SIMD width for vectorized operations
        pub const alignment: u32 = 32; // SIMD alignment requirement
        pub const batch_size: u32 = 8; // Process 8 elements at once
    };
    
    // Memory pools configuration
    pub const memory_pools = struct {
        pub const file_pool_size: u32 = 256; // File handles pool
        pub const network_pool_size: u32 = 128; // Network connections pool
        pub const buffer_pool_size: u32 = 512; // Buffer pool
        pub const batch_pool_size: u32 = 64; // Batch operations pool
    };
    
    // Performance targets
    pub const performance = struct {
        pub const min_throughput_mb_s: f64 = 500.0; // Target: 500 MB/s minimum
        pub const max_latency_ms: u64 = 5; // Target: <5ms latency
        pub const cache_hit_rate: f64 = 0.95; // Target: >95% cache hit rate
        pub const memory_efficiency: f64 = 0.9; // Target: >90% memory efficiency
        pub const simd_utilization: f64 = 0.8; // Target: >80% SIMD utilization
    };
    
    // Feature flags
    pub const features = struct {
        pub const use_soa_layout: bool = true; // Use Struct of Arrays layout
        pub const separate_hot_cold: bool = true; // Separate hot and cold data
        pub const enable_component_system: bool = true; // Enable component-based architecture
        pub const align_for_simd: bool = true; // Align data for SIMD operations
        pub const use_memory_pools: bool = true; // Use static memory pools
        pub const enable_memory_prefetch: bool = true; // Enable memory prefetching
        pub const enable_vectorization: bool = true; // Enable vectorized operations
        pub const enable_batch_processing: bool = true; // Enable batch processing
        pub const optimize_cache_locality: bool = true; // Optimize for cache locality
        pub const use_cache_friendly_layouts: bool = true; // Use cache-friendly layouts
    };
};

// DOD-specific constants
pub const DOD_CONSTANTS = struct {
    // Buffer sizes (power of 2 for better alignment)
    pub const BUFFER_SIZE_SMALL = 1024; // 1KB
    pub const BUFFER_SIZE_MEDIUM = 4096; // 4KB
    pub const BUFFER_SIZE_LARGE = 65536; // 64KB
    pub const BUFFER_SIZE_HUGE = 1048576; // 1MB
    
    // Alignment requirements
    pub const CACHE_LINE_SIZE = 64;
    pub const SIMD_ALIGNMENT = 32;
    pub const PAGE_SIZE = 4096;
    
    // Pool sizes
    pub const MAX_FILE_HANDLES = 256;
    pub const MAX_NETWORK_CONNECTIONS = 128;
    pub const MAX_BUFFERS = 512;
    pub const MAX_BATCHES = 64;
    pub const MAX_BATCH_SIZE = 1024;
    
    // SIMD batch sizes
    pub const SIMD_FILE_BATCH = 8;
    pub const SIMD_NETWORK_BATCH = 8;
    pub const SIMD_STREAM_BATCH = 8;
    pub const SIMD_MEMORY_BATCH = 8;
    
    // Prefetch distances
    pub const PREFETCH_DISTANCE_SMALL = 1;
    pub const PREFETCH_DISTANCE_MEDIUM = 2;
    pub const PREFETCH_DISTANCE_LARGE = 4;
    
    // Performance thresholds
    pub const THROUGHPUT_THRESHOLD_MB_S = 100.0;
    pub const LATENCY_THRESHOLD_MS = 10;
    pub const CACHE_HIT_THRESHOLD = 0.9;
    pub const MEMORY_EFFICIENCY_THRESHOLD = 0.8;
};

// DOD error types
pub const DODError = error{
    PoolExhausted,
    BufferOverflow,
    InvalidAlignment,
    PrefetchFailed,
    SIMDNotSupported,
    ComponentNotFound,
    HotColdSeparationFailed,
    SoALayoutError,
    MemoryPoolError,
    BatchProcessingError,
};

// DOD statistics
pub const DODStats = struct {
    // Performance metrics
    throughput_mb_s: f64 = 0.0,
    latency_ms: f64 = 0.0,
    cache_hit_rate: f64 = 0.0,
    memory_efficiency: f64 = 0.0,
    simd_utilization: f64 = 0.0,
    
    // Operation counts
    file_operations: u64 = 0,
    network_operations: u64 = 0,
    stream_operations: u64 = 0,
    memory_operations: u64 = 0,
    batch_operations: u64 = 0,
    
    // Prefetch statistics
    hardware_prefetches: u64 = 0,
    software_prefetches: u64 = 0,
    prefetch_hits: u64 = 0,
    prefetch_misses: u64 = 0,
    
    // Memory statistics
    total_allocated: u64 = 0,
    total_freed: u64 = 0,
    peak_usage: u64 = 0,
    current_usage: u64 = 0,
    
    pub fn getThroughput(self: DODStats) f64 {
        return self.throughput_mb_s;
    }
    
    pub fn getLatency(self: DODStats) f64 {
        return self.latency_ms;
    }
    
    pub fn getCacheHitRate(self: DODStats) f64 {
        return self.cache_hit_rate;
    }
    
    pub fn getMemoryEfficiency(self: DODStats) f64 {
        return self.memory_efficiency;
    }
    
    pub fn getSIMDUtilization(self: DODStats) f64 {
        return self.simd_utilization;
    }
    
    pub fn getTotalOperations(self: DODStats) u64 {
        return self.file_operations + self.network_operations + 
               self.stream_operations + self.memory_operations + 
               self.batch_operations;
    }
    
    pub fn getPrefetchEffectiveness(self: DODStats) f64 {
        const total_prefetches = self.hardware_prefetches + self.software_prefetches;
        if (total_prefetches == 0) return 0.0;
        return @as(f64, @floatFromInt(self.prefetch_hits)) / @as(f64, @floatFromInt(total_prefetches));
    }
    
    pub fn getMemoryUtilization(self: DODStats) f64 {
        if (self.peak_usage == 0) return 0.0;
        return @as(f64, @floatFromInt(self.current_usage)) / @as(f64, @floatFromInt(self.peak_usage));
    }
};
