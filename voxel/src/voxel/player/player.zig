const Camera = @import("../../engine/camera.zig").Camera;
const Vec3 = @import("../../engine/math/vec.zig").Vec3;
const Input = @import("../../engine/core/input.zig");
const glfw = @import("zglfw");

pub const Player = struct {
    const Self = @This();

    camera: Camera = Camera{},
    move_speed: f32 = 10.0,
    mouse_sensitivity: f32 = 0.002,

    pub fn update(self: *Self, delta: f32) void {
        self.camera.transform.rot.y -= Input.mouseDx() * self.mouse_sensitivity;
        self.camera.transform.rot.x -= Input.mouseDy() * self.mouse_sensitivity;

        const max_pitch: f32 = 1.55334;
        if (self.camera.transform.rot.x > max_pitch) self.camera.transform.rot.x = max_pitch;
        if (self.camera.transform.rot.x < -max_pitch) self.camera.transform.rot.x = -max_pitch;

        const yaw = self.camera.transform.rot.y;
        const sy = @sin(yaw);
        const cy = @cos(yaw);

        const forward = Vec3{ .x = -sy, .y = 0, .z = -cy };
        const right = Vec3{ .x = cy, .y = 0, .z = -sy };

        var dx: f32 = 0;
        var dy: f32 = 0;
        var dz: f32 = 0;

        if (Input.isKeyDown(.w)) { dx += forward.x; dz += forward.z; }
        if (Input.isKeyDown(.s)) { dx -= forward.x; dz -= forward.z; }
        if (Input.isKeyDown(.d)) { dx += right.x; dz += right.z; }
        if (Input.isKeyDown(.a)) { dx -= right.x; dz -= right.z; }
        if (Input.isKeyDown(.space)) { dy += 1; }
        if (Input.isKeyDown(.left_shift)) { dy -= 1; }

        const len_sq = dx * dx + dy * dy + dz * dz;
        if (len_sq > 0) {
            const inv = 1.0 / @sqrt(len_sq);
            dx *= inv;
            dy *= inv;
            dz *= inv;
        }

        const step = self.move_speed * delta;
        self.camera.transform.pos.x += dx * step;
        self.camera.transform.pos.y += dy * step;
        self.camera.transform.pos.z += dz * step;
    }
};
