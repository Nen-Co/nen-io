const std = @import("std");

/// Get stdin file handle using the correct Zig 0.15.1 API
pub fn getStdIn() std.fs.File {
    return std.fs.File.stdin();
}

/// Get stdout file handle using the correct Zig 0.15.1 API
pub fn getStdOut() std.fs.File {
    return std.fs.File.stdout();
}

/// Get a buffered reader for stdin using Zig 0.15.1 API
pub fn getStdInReader(buffer: []u8) std.fs.File.Reader {
    return std.fs.File.stdin().reader(buffer);
}

/// Read a line from stdin using the correct Zig 0.15.1 API
pub fn readLine(buffer: []u8) !?[]const u8 {
    // Read from stdin one byte at a time until a newline or EOF.
    // This avoids relying on std.io helpers that changed across Zig versions.
    var reader_buffer: [1024]u8 = undefined;
    var reader = std.fs.File.stdin().reader(&reader_buffer);

    var write_index: usize = 0;
    while (true) {
        var byte_buf: [1]u8 = undefined;
        const n = try reader.read(byte_buf[0..]);

        if (n == 0) {
            // EOF
            if (write_index == 0) return null;
            break;
        }

        const b = byte_buf[0];
        if (b == '\n') {
            break;
        }

        if (write_index < buffer.len) {
            buffer[write_index] = b;
            write_index += 1;
        } else {
            // Buffer full: continue consuming until newline/EOF, but don't write.
        }
    }

    return buffer[0..write_index];
}
