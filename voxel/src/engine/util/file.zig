const std = @import("std");

pub fn read(comptime path: []const u8) []const u8 {
    return @embedFile("../../" ++ path);
}
