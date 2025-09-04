const std = @import("std");

/// Get stdin file handle using the correct Zig 0.15.1 API
pub fn getStdIn() std.fs.File {
    return std.fs.File.stdin();
}

/// Get a buffered reader for stdin using Zig 0.15.1 API
pub fn getStdInReader(buffer: []u8) std.fs.File.Reader {
    return std.fs.File.stdin().reader(buffer);
}

/// Read a line from stdin using the correct Zig 0.15.1 API
pub fn readLine(buffer: []u8) !?[]const u8 {
    var stdin_reader_buffer: [1024]u8 = undefined;
    var reader = std.fs.File.stdin().reader(&stdin_reader_buffer);

    var writer = std.io.fixedBufferWriter(buffer);
    const bytes_read = try reader.streamDelimiterLimit(writer.writer(), '\n', .unlimited);

    if (bytes_read == 0) return null;
    return buffer[0..bytes_read];
}
