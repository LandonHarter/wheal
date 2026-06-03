const Vec3 = @import("../../engine/math/vec.zig").Vec3;

pub const BlockType = struct {
    name: []const u8,
    textures: [6]u16,
    colors: [6]Vec3 = [_]Vec3{Vec3{.x=1,.y=1,.z=1}} ** 6,
};
