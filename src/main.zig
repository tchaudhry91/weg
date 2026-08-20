const std = @import("std");
const Io = std.Io;

const weg = @import("weg");

const Mode = enum {
    push,
    pull,
};

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    if (args.len < 3) {
        // printUsage
        return error.IncorrectArguments;
    }
    const mode: Mode = parseMode(args[1]) orelse {
        // printUsage
        return error.IncorrectMode;
    };

    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;
    const home = init.environ_map.get("HOME").?;
    const db_file_path = try weg.getDBFilePath(arena, home);

    switch (mode) {
        .pull => std.debug.print("nothing yet", .{}),
        .push => {
            const ts = std.Io.Clock.real.now(io);
            try weg.push(io, db_file_path, args[2], ts);
        },
    }

    try stdout_writer.flush();
}

fn parseMode(mode: []const u8) ?Mode {
    return std.meta.stringToEnum(Mode, mode);
}
