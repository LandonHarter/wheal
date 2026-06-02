const Vec3 = @import("../engine/math/vec.zig").Vec3;

pub const CHUNK_WIDTH = 16;
pub const CHUNK_HEIGHT = 128;

pub const TEXTURE_ATLAS_SIZE = 32;

pub const BLOCK_VERTICES: [8]Vec3 = .{
    Vec3{ .x = 0, .y = 0, .z = 0 },
    Vec3{ .x = 1, .y = 0, .z = 0 },
    Vec3{ .x = 1, .y = 1, .z = 0 },
    Vec3{ .x = 0, .y = 1, .z = 0 },
    Vec3{ .x = 0, .y = 0, .z = 1 },
    Vec3{ .x = 1, .y = 0, .z = 1 },
    Vec3{ .x = 1, .y = 1, .z = 1 },
    Vec3{ .x = 0, .y = 1, .z = 1 },
};

pub const BLOCK_INDICES: [6][4]u8 = .{
    .{ 0, 3, 1, 2 },
    .{ 5, 6, 4, 7 },
    .{ 3, 7, 2, 6 },
    .{ 1, 5, 0, 4 },
    .{ 4, 7, 0, 3 },
    .{ 1, 2, 5, 6 },
};

pub const FACE_CHECKS: [6]Vec3 = .{
    Vec3{ .x = 0, .y = 0, .z = -1 },
    Vec3{ .x = 0, .y = 0, .z = 1 },
    Vec3{ .x = 0, .y = 1, .z = 0 },
    Vec3{ .x = 0, .y = -1, .z = 0 },
    Vec3{ .x = -1, .y = 0, .z = 0 },
    Vec3{ .x = 1, .y = 0, .z = 0 },
};
