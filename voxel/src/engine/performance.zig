const std = @import("std");

const ProfilerEvent = struct {
    name: []const u8,
    time: f64,
    duration: f64
};

var io: *const std.Io = undefined;
var timeStarted: f64 = 0;
var events: std.ArrayList(ProfilerEvent) = .empty;

pub fn init(io_ptr: *const std.Io) void {
    io = io_ptr;
}

pub fn start() void {
    timeStarted = @as(f64, @floatFromInt(std.Io.Clock.awake.now(io.*).nanoseconds)) / 1e9;
}

pub fn event(name: []const u8, gpa: std.mem.Allocator) !void {
    const lastEventTime = if (events.items.len > 0) events.items[events.items.len - 1].time else timeStarted;
    const time = @as(f64, @floatFromInt(std.Io.Clock.awake.now(io.*).nanoseconds)) / 1e9;
    try events.append(gpa, .{
        .name = name,
        .time = time,
        .duration = time - lastEventTime
    });
}

pub fn end() f64 {
    const timeEnded: f64 = @as(f64, @floatFromInt(std.Io.Clock.awake.now(io.*).nanoseconds)) / 1e9;

    for (events.items) |e| {
        std.debug.print("{s}: {}s\n", .{ e.name, e.duration });
    }
    std.debug.print("Total: {}s", .{timeEnded - timeStarted});

    return timeEnded - timeStarted;
}

pub fn destroy(gpa: std.mem.Allocator) void {
    events.deinit(gpa);
}
