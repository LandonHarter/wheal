const std = @import("std");

pub const Profiler = struct {
    const Self = @This();

    timeStarted: f64 = 0,

    pub fn start(self: *Self, io: std.Io) void {
        self.timeStarted = @as(f64, @floatFromInt(std.Io.Clock.awake.now(io).nanoseconds)) / 1e9;
    }

    pub fn end(self: *Self, io: std.Io) f64 {
        const timeEnded: f64 = @as(f64, @floatFromInt(std.Io.Clock.awake.now(io).nanoseconds)) / 1e9;
        return timeEnded - self.timeStarted;
    }
};
