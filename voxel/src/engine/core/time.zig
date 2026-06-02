const std = @import("std");

var timeStarted: f64 = 0;
pub var delta: f64 = 0;

pub fn startFrame(io: std.Io) void {
    timeStarted = @as(f64, @floatFromInt(std.Io.Clock.awake.now(io).nanoseconds)) / 1e9;
}

pub fn endFrame(io: std.Io) void {
    const timeEnded: f64 = @as(f64, @floatFromInt(std.Io.Clock.awake.now(io).nanoseconds)) / 1e9;
    delta = timeEnded - timeStarted;
}
