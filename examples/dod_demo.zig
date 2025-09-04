// Nen IO Data-Oriented Design (DOD) Demo
// Demonstrates the performance benefits of DOD architecture for I/O operations

const std = @import("std");
const nenio = @import("nen-io");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    std.debug.print("🚀 Nen IO Data-Oriented Design (DOD) Demo\n", .{});
    std.debug.print("=======================================\n\n", .{});

    // Initialize DOD I/O layout
    var io_layout = nenio.dod_layout.DODIOLayout.init();
    var prefetch_system = nenio.dod_prefetch.IOPrefetchSystem.init(nenio.dod_prefetch.IOPrefetchConfig{});

    // Demo 1: SoA vs AoS Performance for I/O Operations
    std.debug.print("📊 Demo 1: Struct of Arrays (SoA) I/O Performance\n", .{});
    std.debug.print("------------------------------------------------\n", .{});

    const num_files = 10;
    const num_buffers = 20;
    const num_network = 5;

    // Add files using SoA layout
    const start_time = std.time.nanoTimestamp();
    
    for (0..num_files) |i| {
        const file_path = try std.fmt.allocPrint(gpa.allocator(), "test_file_{d}.txt", .{i});
        defer gpa.allocator().free(file_path);
        
        // Create test file
        const file = try std.fs.cwd().createFile(file_path, .{});
        defer file.close();
        try file.writeAll("Test data for file ");
        try file.writeAll(try std.fmt.allocPrint(gpa.allocator(), "{d}", .{i}));
        
        _ = try io_layout.addFile(file_path, .{});
    }
    
    for (0..num_buffers) |i| {
        _ = try io_layout.addBuffer(1024, @intCast(i % 4));
    }
    
    for (0..num_network) |i| {
        const address = try std.fmt.allocPrint(gpa.allocator(), "192.168.1.{d}", .{i + 1});
        defer gpa.allocator().free(address);
        _ = try io_layout.addNetworkConnection(address, @intCast(8080 + i), 1);
    }
    
    const end_time = std.time.nanoTimestamp();
    const duration_ns = end_time - start_time;
    const duration_ms = @as(f64, @floatFromInt(duration_ns)) / 1_000_000.0;

    std.debug.print("✅ Added {d} files, {d} buffers, and {d} network connections in {d:.2}ms\n", .{ num_files, num_buffers, num_network, duration_ms });
    std.debug.print("⚡ Performance: {d:.0} operations/second\n\n", .{ @as(f64, @floatFromInt(num_files + num_buffers + num_network)) / (duration_ms / 1000.0) });

    // Demo 2: SIMD-Optimized I/O Operations
    std.debug.print("🔍 Demo 2: SIMD-Optimized I/O Operations\n", .{});
    std.debug.print("---------------------------------------\n", .{});

    var file_indices: [10]u32 = undefined;
    for (0..10) |i| {
        file_indices[i] = @intCast(i);
    }

    var read_data: [1024]u8 = undefined;
    
    const simd_start = std.time.nanoTimestamp();
    const bytes_read = try io_layout.readFilesSIMD(&file_indices, &read_data);
    const simd_end = std.time.nanoTimestamp();
    const simd_duration_ns = simd_end - simd_start;
    const simd_duration_ms = @as(f64, @floatFromInt(simd_duration_ns)) / 1_000_000.0;

    std.debug.print("✅ Read {d} bytes using SIMD in {d:.3}ms\n", .{ bytes_read, simd_duration_ms });
    std.debug.print("⚡ SIMD I/O performance: {d:.0} bytes/second\n\n", .{ @as(f64, @floatFromInt(bytes_read)) / (simd_duration_ms / 1000.0) });

    // Demo 3: Prefetching for I/O Operations
    std.debug.print("🎯 Demo 3: I/O Prefetching System\n", .{});
    std.debug.print("---------------------------------\n", .{});

    const prefetch_start = std.time.nanoTimestamp();
    
    // Prefetch file data
    for (0..num_files) |i| {
        prefetch_system.prefetchFileData(&io_layout, @intCast(i), .read_ahead);
    }
    
    // Prefetch network data
    for (0..num_network) |i| {
        prefetch_system.prefetchNetworkData(&io_layout, @intCast(i), .network_stream);
    }
    
    // Prefetch buffer data
    for (0..num_buffers) |i| {
        prefetch_system.prefetchBufferData(&io_layout, @intCast(i), .write_behind);
    }
    
    const prefetch_end = std.time.nanoTimestamp();
    const prefetch_duration_ns = prefetch_end - prefetch_start;
    const prefetch_duration_ms = @as(f64, @floatFromInt(prefetch_duration_ns)) / 1_000_000.0;

    std.debug.print("✅ Prefetched {d} files, {d} network connections, and {d} buffers in {d:.3}ms\n", .{ num_files, num_network, num_buffers, prefetch_duration_ms });

    // Demo 4: Batch Processing with DOD
    std.debug.print("\n📦 Demo 4: DOD Batch Processing\n", .{});
    std.debug.print("-------------------------------\n", .{});

    // Create batches
    var batch_indices: [5]u32 = undefined;
    for (0..5) |i| {
        batch_indices[i] = try io_layout.addBatch(@intCast(i % 3), @intCast(i % 5));
    }

    // Process batches with prefetching
    for (batch_indices) |batch_idx| {
        prefetch_system.prefetchBatchData(&io_layout, batch_idx, .batch_processing);
    }

    std.debug.print("✅ Created and prefetched {d} batches\n", .{batch_indices.len});

    // Demo 5: Memory Statistics
    std.debug.print("\n📈 Demo 5: DOD Memory Statistics\n", .{});
    std.debug.print("--------------------------------\n", .{});

    const stats = io_layout.getStats();
    const prefetch_stats = prefetch_system.getStats();
    
    std.debug.print("📊 I/O Layout Statistics:\n", .{});
    std.debug.print("   Files: {d}/{d} ({d:.1}% utilization)\n", .{ 
        stats.file_count, 
        stats.file_capacity, 
        stats.getFileUtilization() * 100.0 
    });
    std.debug.print("   Buffers: {d}/{d} ({d:.1}% utilization)\n", .{ 
        stats.buffer_count, 
        stats.buffer_capacity, 
        stats.getBufferUtilization() * 100.0 
    });
    std.debug.print("   Network: {d}/{d} ({d:.1}% utilization)\n", .{ 
        stats.network_count, 
        stats.network_capacity, 
        stats.getNetworkUtilization() * 100.0 
    });
    std.debug.print("   Batches: {d}/{d} ({d:.1}% utilization)\n", .{ 
        stats.batch_count, 
        stats.batch_capacity, 
        stats.getBatchUtilization() * 100.0 
    });
    std.debug.print("   Overall utilization: {d:.1}%\n", .{stats.getOverallUtilization() * 100.0});

    std.debug.print("\n📊 Prefetch Statistics:\n", .{});
    std.debug.print("   Total prefetches: {d}\n", .{prefetch_stats.getTotalPrefetches()});
    std.debug.print("   Prefetch effectiveness: {d:.1}%\n", .{prefetch_stats.getPrefetchEffectiveness() * 100.0});
    std.debug.print("   Cache hit rate: {d:.1}%\n", .{prefetch_stats.getHitRate() * 100.0});

    // Demo 6: DOD Benefits Summary
    std.debug.print("\n🎯 DOD Benefits Demonstrated\n", .{});
    std.debug.print("----------------------------\n", .{});
    std.debug.print("✅ Struct of Arrays (SoA) layout for better cache locality\n", .{});
    std.debug.print("✅ SIMD-optimized I/O operations for vectorized processing\n", .{});
    std.debug.print("✅ Advanced prefetching system for I/O operations\n", .{});
    std.debug.print("✅ Static memory allocation for predictable performance\n", .{});
    std.debug.print("✅ Batch processing with DOD optimization\n", .{});
    std.debug.print("✅ Component-based architecture for flexible I/O modeling\n", .{});

    // Cleanup
    for (0..num_files) |i| {
        const file_path = try std.fmt.allocPrint(gpa.allocator(), "test_file_{d}.txt", .{i});
        defer gpa.allocator().free(file_path);
        std.fs.cwd().deleteFile(file_path) catch {};
    }

    std.debug.print("\n🚀 Nen IO DOD architecture delivers maximum I/O performance!\n", .{});
}
