const Vec3 = @import("vec.zig").Vec3;
const Mat4 = @import("mat.zig").Mat4;

pub const Transform = struct {
    const Self = @This();

    pos: Vec3 = Vec3{},
    rot: Vec3 = Vec3{},
    scale: Vec3 = Vec3{},

    pub fn model(self: Self) Mat4 {
        var mat = Mat4{};
        mat.translate(self.pos);
        return mat;
    }

    pub fn forward(self: Self) Vec3 {
        return Vec3 {
            .x = -@cos(self.rot.x) * @sin(self.rot.y),
            .y = @sin(self.rot.x),
            .z = -@cos(self.rot.x) * @cos(self.rot.y)
        };
    }

};
