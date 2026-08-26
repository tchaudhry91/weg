//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;

pub fn push(io: Io, db_path: []const u8, chpwd_path: []const u8) !u64 {
    var push_buffer: [1024]u8 = undefined;
    var push_file: Io.File = try std.Io.Dir.createFileAbsolute(io, db_path, .{ .truncate = false });
    defer push_file.close(io);
    var push_file_writer = push_file.writer(io, &push_buffer);
    try push_file_writer.seekTo(try push_file.length(io));
    try push_file_writer.interface.print("{s}\n", .{chpwd_path});
    try push_file_writer.flush();
    return push_file.length(io);
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
        const l = std.mem.trim(u8, line, "\t\n ");
        if (std.ascii.findIgnoreCase(l, query) != null) {
            ret = l;
        }
    }
    return ret;
}

pub fn compact(allocator: std.mem.Allocator, io: Io, db_path: []const u8) !void {
    const data = try std.Io.Dir.cwd().readFileAlloc(io, db_path, allocator, .unlimited);
    var lines = std.mem.splitBackwardsScalar(u8, data, '\n');
    var compacted = try std.ArrayList([]const u8).initCapacity(allocator, 10);
    defer compacted.deinit(allocator);

    var seen = std.StringHashMap(void).init(allocator);
    defer seen.deinit();

    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        const exists = try seen.getOrPut(line);
        if (exists.found_existing) {
            continue;
        }
        try compacted.append(allocator, line);
    }
    std.mem.reverse([]const u8, compacted.items);
    var af_buffer: [1024]u8 = undefined;
    var af = try std.Io.Dir.cwd().createFileAtomic(io, db_path, .{ .replace = true });
    defer af.deinit(io);
    var compacted_file_writer = af.file.writer(io, &af_buffer);
    for (compacted.items) |line| {
        try compacted_file_writer.interface.print("{s}\n", .{line});
    }
    try compacted_file_writer.flush();
    try af.replace(io);
}
