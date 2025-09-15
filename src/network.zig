// Nen IO - Network Module
// Low-level network I/O operations with static allocation

const std = @import("std");
const builtin = @import("builtin");
const net = std.net;
const posix = std.posix;

// Network socket abstraction
pub const NetworkSocket = struct {
    fd: posix.socket_t,
    is_connected: bool = false,

    pub const SocketOptions = struct {
        reuse_addr: bool = true,
        tcp_nodelay: bool = true,
        non_blocking: bool = true,
        keep_alive: bool = true,
    };

    pub inline fn createTcp() !@This() {
        const fd = try posix.socket(posix.AF.INET, posix.SOCK.STREAM, 0);
        return @This(){ .fd = fd };
    }

    pub inline fn configure(self: *@This(), options: SocketOptions) !void {
        if (options.reuse_addr) {
            try posix.setsockopt(self.fd, posix.SOL.SOCKET, posix.SO.REUSEADDR, &std.mem.toBytes(@as(c_int, 1)));
        }
        if (options.tcp_nodelay) {
            try posix.setsockopt(self.fd, posix.IPPROTO.TCP, posix.TCP.NODELAY, &std.mem.toBytes(@as(c_int, 1)));
        }
        if (options.keep_alive) {
            try posix.setsockopt(self.fd, posix.SOL.SOCKET, posix.SO.KEEPALIVE, &std.mem.toBytes(@as(c_int, 1)));
        }
        if (options.non_blocking) {
            const flags = try posix.fcntl(self.fd, posix.F.GETFL, 0);
            const nonblock_flag = switch (builtin.os.tag) {
                .linux => @as(u32, 0x800),
                .macos => @as(u32, 0x4),
                else => @as(u32, 0x4),
            };
            _ = try posix.fcntl(self.fd, posix.F.SETFL, flags | nonblock_flag);
        }
    }

    pub inline fn bind(self: *@This(), address: net.Address) !void {
        try posix.bind(self.fd, &address.any, address.getOsSockLen());
    }

    pub inline fn listen(self: *@This(), backlog: u32) !void {
        try posix.listen(self.fd, @intCast(backlog));
    }

    pub inline fn accept(self: *@This()) !struct { socket: @This(), address: net.Address } {
        var client_addr: net.Address = undefined;
        var addr_len: posix.socklen_t = @sizeOf(net.Address);
        const client_fd = try posix.accept(self.fd, &client_addr.any, &addr_len, posix.SOCK.CLOEXEC);

        var client_socket = @This(){
            .fd = client_fd,
            .is_connected = true,
        };

        // Configure client socket
        try client_socket.configure(.{
            .reuse_addr = true,
            .tcp_nodelay = true,
            .non_blocking = true,
            .keep_alive = true,
        });

        return .{ .socket = client_socket, .address = client_addr };
    }

    pub inline fn connect(self: *@This(), address: net.Address) !void {
        try posix.connect(self.fd, &address.any, address.getOsSockLen());
        self.is_connected = true;
    }

    pub inline fn send(self: *@This(), data: []const u8) !usize {
        return try posix.write(self.fd, data);
    }

    pub inline fn receive(self: *@This(), buffer: []u8) !usize {
        return try posix.read(self.fd, buffer);
    }

    pub inline fn close(self: *@This()) void {
        posix.close(self.fd);
        self.is_connected = false;
    }

    pub inline fn getFd(self: *const @This()) posix.socket_t {
        return self.fd;
    }
};

// Network utilities
pub inline fn parseAddress(host: []const u8, port: u16) !net.Address {
    return try net.Address.parseIp4(host, port);
}
