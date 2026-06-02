const std = @import("std");
const Transform = @import("math/transform.zig").Transform;
const Mat4 = @import("math/mat.zig").Mat4;

pub const Camera = struct {
    const Self = @This();

    transform: Transform = Transform{},
    fov: f32 = std.math.pi / 3.0,
    aspect: f32 = 16.0 / 9.0,
    near: f32 = 0.1,
    far: f32 = 1000.0,

    pub fn view(self: Self) Mat4 {
        const pitch = self.transform.rot.x;
        const yaw = self.transform.rot.y;
        const roll = self.transform.rot.z;

        const cp = @cos(pitch);
        const sp = @sin(pitch);
        const cy = @cos(yaw);
        const sy = @sin(yaw);
        const cr = @cos(roll);
        const sr = @sin(roll);

        const r00 = cy * cr + sy * sp * sr;
        const r01 = -cy * sr + sy * sp * cr;
        const r02 = sy * cp;
        const r10 = cp * sr;
        const r11 = cp * cr;
        const r12 = -sp;
        const r20 = -sy * cr + cy * sp * sr;
        const r21 = sy * sr + cy * sp * cr;
        const r22 = cy * cp;

        const px = self.transform.pos.x;
        const py = self.transform.pos.y;
        const pz = self.transform.pos.z;

        const tx = -(r00 * px + r10 * py + r20 * pz);
        const ty = -(r01 * px + r11 * py + r21 * pz);
        const tz = -(r02 * px + r12 * py + r22 * pz);

        return Mat4{
            .data = .{
                .{ r00, r10, r20, tx },
                .{ r01, r11, r21, ty },
                .{ r02, r12, r22, tz },
                .{ 0, 0, 0, 1 },
            },
        };
    }

    pub fn projection(self: Self) Mat4 {
        const f = 1.0 / @tan(self.fov / 2.0);
        const nf = 1.0 / (self.near - self.far);

        return Mat4{
            .data = .{
                .{ f / self.aspect, 0, 0, 0 },
                .{ 0, f, 0, 0 },
                .{ 0, 0, (self.far + self.near) * nf, 2.0 * self.far * self.near * nf },
                .{ 0, 0, -1, 0 },
            },
        };
    }
};
