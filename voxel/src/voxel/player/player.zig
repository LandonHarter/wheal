const std = @import("std");
const Camera = @import("../../engine/camera.zig").Camera;
const Vec3 = @import("../../engine/math/vec.zig").Vec3;
const ChunkCoord = @import("../chunking/chunk.zig").ChunkCoord;
const Input = @import("../../engine/core/input.zig");
const World = @import("../world.zig");
const constants = @import("../constants.zig");
const glfw = @import("zglfw");

const HALF_WIDTH: f32 = 0.3;
const EYE_TO_TOP: f32 = 0.2;
const EYE_TO_BOTTOM: f32 = 1.62;
const SKIN: f32 = 0.001;

pub const Player = struct {
    const Self = @This();

    camera: Camera = Camera{},

    mouse_sensitivity: f32 = 0.002,

    walk_speed: f32 = 6.0,
    sprint_mult: f32 = 1.8,
    fly_speed: f32 = 14.0,
    fly_sprint_mult: f32 = 3.0,

    ground_accel: f32 = 14.0,
    air_accel: f32 = 3.0,
    fly_accel: f32 = 12.0,

    gravity: f32 = 28.0,
    jump_speed: f32 = 9.0,
    max_fall_speed: f32 = 60.0,

    velocity: Vec3 = Vec3{},

    flying: bool = false,
    grounded: bool = false,

    prev_fly_toggle: bool = false,

    lastChunkCoord: ChunkCoord = ChunkCoord{ .x = 0, .z = 0 },

    pub fn update(self: *Self, delta: f32) void {
        self.updateLook();

        const fly_down = Input.isKeyDown(.f);
        if (fly_down and !self.prev_fly_toggle) {
            self.flying = !self.flying;
            self.velocity.y = 0;
            self.grounded = false;
        }
        self.prev_fly_toggle = fly_down;

        const yaw = self.camera.transform.rot.y;
        const sy = @sin(yaw);
        const cy = @cos(yaw);
        const forward = Vec3{ .x = -sy, .y = 0, .z = -cy };
        const right = Vec3{ .x = cy, .y = 0, .z = -sy };

        var wish = Vec3{};
        if (Input.isKeyDown(.w)) wish = wish.add(forward);
        if (Input.isKeyDown(.s)) wish = wish.sub(forward);
        if (Input.isKeyDown(.d)) wish = wish.add(right);
        if (Input.isKeyDown(.a)) wish = wish.sub(right);

        const wish_h = blk: {
            const l2 = wish.x * wish.x + wish.z * wish.z;
            if (l2 > 0) {
                const inv = 1.0 / @sqrt(l2);
                break :blk Vec3{ .x = wish.x * inv, .y = 0, .z = wish.z * inv };
            }
            break :blk Vec3{};
        };

        const sprinting = Input.isKeyDown(.left_control);

        if (self.flying) {
            const speed = self.fly_speed * (if (sprinting) self.fly_sprint_mult else 1.0);
            var wish_vel = wish_h.scale(speed);
            if (Input.isKeyDown(.space)) wish_vel.y += speed;
            if (Input.isKeyDown(.left_shift)) wish_vel.y -= speed;

            self.velocity = damp(self.velocity, wish_vel, self.fly_accel, delta);
        } else {
            const speed = self.walk_speed * (if (sprinting) self.sprint_mult else 1.0);
            const wish_vel = wish_h.scale(speed);

            const accel = if (self.grounded) self.ground_accel else self.air_accel;
            const new_h = damp(
                Vec3{ .x = self.velocity.x, .y = 0, .z = self.velocity.z },
                wish_vel,
                accel,
                delta,
            );
            self.velocity.x = new_h.x;
            self.velocity.z = new_h.z;

            self.velocity.y -= self.gravity * delta;
            if (self.velocity.y < -self.max_fall_speed) self.velocity.y = -self.max_fall_speed;

            if (self.grounded and Input.isKeyDown(.space)) {
                self.velocity.y = self.jump_speed;
                self.grounded = false;
            }
        }

        const disp = self.velocity.scale(delta);
        self.moveAndCollide(disp);
    }

    fn moveAndCollide(self: *Self, disp: Vec3) void {
        var pos = self.camera.transform.pos;

        pos.x += disp.x;
        if (collidesAt(pos)) {
            if (disp.x > 0) {
                pos.x = @floor(pos.x + HALF_WIDTH) - HALF_WIDTH - SKIN;
            } else if (disp.x < 0) {
                pos.x = @floor(pos.x - HALF_WIDTH) + 1.0 + HALF_WIDTH + SKIN;
            }
            self.velocity.x = 0;
        }

        pos.z += disp.z;
        if (collidesAt(pos)) {
            if (disp.z > 0) {
                pos.z = @floor(pos.z + HALF_WIDTH) - HALF_WIDTH - SKIN;
            } else if (disp.z < 0) {
                pos.z = @floor(pos.z - HALF_WIDTH) + 1.0 + HALF_WIDTH + SKIN;
            }
            self.velocity.z = 0;
        }

        var grounded_this_frame = false;
        pos.y += disp.y;
        if (collidesAt(pos)) {
            if (disp.y > 0) {
                pos.y = @floor(pos.y + EYE_TO_TOP) - EYE_TO_TOP - SKIN;
            } else if (disp.y < 0) {
                pos.y = @floor(pos.y - EYE_TO_BOTTOM) + 1.0 + EYE_TO_BOTTOM + SKIN;
                grounded_this_frame = true;
            }
            self.velocity.y = 0;
        }
        self.grounded = grounded_this_frame;

        self.camera.transform.pos = pos;
    }

    fn collidesAt(pos: Vec3) bool {
        const min_x = pos.x - HALF_WIDTH;
        const max_x = pos.x + HALF_WIDTH;
        const min_y = pos.y - EYE_TO_BOTTOM;
        const max_y = pos.y + EYE_TO_TOP;
        const min_z = pos.z - HALF_WIDTH;
        const max_z = pos.z + HALF_WIDTH;

        var x: i32 = @intFromFloat(@floor(min_x));
        const x_end: i32 = @intFromFloat(@floor(max_x));
        while (x <= x_end) : (x += 1) {
            var y: i32 = @intFromFloat(@floor(min_y));
            const y_end: i32 = @intFromFloat(@floor(max_y));
            while (y <= y_end) : (y += 1) {
                var z: i32 = @intFromFloat(@floor(min_z));
                const z_end: i32 = @intFromFloat(@floor(max_z));
                while (z <= z_end) : (z += 1) {
                    const sample = Vec3{
                        .x = @as(f32, @floatFromInt(x)) + 0.5,
                        .y = @as(f32, @floatFromInt(y)) + 0.5,
                        .z = @as(f32, @floatFromInt(z)) + 0.5,
                    };
                    if (World.checkVoxel(sample)) return true;
                }
            }
        }
        return false;
    }

    fn updateLook(self: *Self) void {
        self.camera.transform.rot.y -= Input.mouseDx() * self.mouse_sensitivity;
        self.camera.transform.rot.x -= Input.mouseDy() * self.mouse_sensitivity;

        const max_pitch: f32 = 1.55334;
        if (self.camera.transform.rot.x > max_pitch) self.camera.transform.rot.x = max_pitch;
        if (self.camera.transform.rot.x < -max_pitch) self.camera.transform.rot.x = -max_pitch;
    }

    fn damp(current: Vec3, target: Vec3, rate: f32, delta: f32) Vec3 {
        const t: f32 = 1.0 - @exp(-rate * delta);
        return current.add(target.sub(current).scale(t));
    }

    pub fn getChunkCoord(self: Self) ChunkCoord {
        return ChunkCoord{
            .x = @floor(self.camera.transform.pos.x / constants.CHUNK_WIDTH),
            .z = @floor(self.camera.transform.pos.z / constants.CHUNK_WIDTH),
        };
    }
};
