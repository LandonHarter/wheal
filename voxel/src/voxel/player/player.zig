const Camera = @import("../../engine/camera.zig").Camera;

pub const Player = struct {
    const Self = @This();

    camera: Camera = Camera{},
};
