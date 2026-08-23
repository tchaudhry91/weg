//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;

pub fn push(io: Io, db_path: []const u8, chpwd_path: []const u8, timestamp: Io.Timestamp) !void {
    var push_buffer: [1024]u8 = undefined;
    var push_file: Io.File = try std.Io.Dir.createFileAbsolute(io, db_path, .{ .truncate = false });
    defer push_file.close(io);
    var push_file_writer = push_file.writer(io, &push_buffer);
    try push_file_writer.seekTo(try push_file.length(io));
    try push_file_writer.interface.print("{d}:{s}\n", .{ timestamp.toSeconds(), chpwd_path });
    try push_file_writer.flush();
}

pub fn getDBFilePath(allocator: std.mem.Allocator, home: []const u8, weg_db_var: ?[]const u8) ![]const u8 {
    return weg_db_var orelse std.fs.path.join(allocator, &.{ home, ".weg.db" });
}

pub fn pull(allocator: std.mem.Allocator, io: Io, db_path: []const u8, query: []const u8) !?[]const u8 {
    var ret: ?[]const u8 = null;
    const data = std.Io.Dir.cwd().readFileAlloc(io, db_path, allocator, .unlimited) catch |err| switch (err) {
        error.FileNotFound => {
            return null;
        },
        else => return err,
    };
    var lines = std.mem.splitScalar(u8, data, '\n');
    while (lines.next()) |line| {
        // Remove the timestamp
        const split = std.mem.cutScalar(u8, line, ':') orelse continue;
        var l = split.@"1";
        l = std.mem.trim(u8, l, "\t\n ");
        if (std.mem.find(u8, l, query) != null) {
            ret = l;
        }
    }
    return ret;
}
