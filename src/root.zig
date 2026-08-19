//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;

pub fn push(writer: *Io.Writer, chpwd_path: []const u8, timestamp: u64) Io.Writer.Error!void {
    try writer.print("{d}:{s}\n", .{ timestamp, chpwd_path });
}
