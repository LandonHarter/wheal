const std = @import("std");

pub fn read(path: []const u8, io: std.Io, gpa: std.mem.Allocator) ![]u8 {
    return try std.Io.Dir.cwd().readFileAlloc(io, path, gpa, .unlimited);
}
