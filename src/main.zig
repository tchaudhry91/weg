const std = @import("std");
const Io = std.Io;

const weg = @import("weg");

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    const home = init.environ_map.get("HOME").?;
    const db_path = try std.fs.path.join(arena, &.{ home, ".weg" });

    var push_buffer: [1024]u8 = undefined;
    var push_file: Io.File = try std.Io.Dir.createFileAbsolute(io, db_path, .{ .truncate = false });
    var push_file_writer = push_file.writer(io, &push_buffer);
    try push_file_writer.seekTo(try push_file.length(io));

    try weg.push(&push_file_writer.interface, "/home/tchaudhry/", 12312312);

    try push_file_writer.flush();
    try stdout_writer.flush();
}
