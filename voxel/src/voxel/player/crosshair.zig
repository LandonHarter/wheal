const std = @import("std");
const mesh = @import("../../engine/graphics/mesh.zig");
const vec = @import("../../engine/math/vec.zig");
const Shader = @import("../../engine/graphics/shader.zig").Shader;
const Camera = @import("../../engine/camera.zig").Camera;

const size = 15;

var uiMesh: mesh.Mesh = undefined;
var uiShader: Shader = undefined;

pub fn create(gpa: std.mem.Allocator, io: std.Io) !void {
    uiShader = try Shader.load("resources/shaders/ui/vert.glsl", "resources/shaders/ui/frag.glsl", io, gpa);
    const half = size / 2;
    const th = size / 10;
    uiMesh = try mesh.Mesh.create(gpa, &[8]mesh.Vertex {
        .{ .pos=vec.Vec3{ .x=-th, .y=-half, .z=0 }, .uv=vec.Vec2{ .x=0, .y=0 } },
        .{ .pos=vec.Vec3{ .x=-th, .y=half, .z=0 }, .uv=vec.Vec2{ .x=0, .y=1 } },
        .{ .pos=vec.Vec3{ .x=th, .y=half, .z=0 }, .uv=vec.Vec2{ .x=1, .y=1 } },
        .{ .pos=vec.Vec3{ .x=th, .y=-half, .z=0 }, .uv=vec.Vec2{ .x=1, .y=0 } },
        .{ .pos=vec.Vec3{ .x=-half, .y=-th, .z=0 }, .uv=vec.Vec2{ .x=0, .y=0 } },
        .{ .pos=vec.Vec3{ .x=-half, .y=th, .z=0 }, .uv=vec.Vec2{ .x=0, .y=1 } },
        .{ .pos=vec.Vec3{ .x=half, .y=th, .z=0 }, .uv=vec.Vec2{ .x=1, .y=1 } },
        .{ .pos=vec.Vec3{ .x=half, .y=-th, .z=0 }, .uv=vec.Vec2{ .x=1, .y=0 } },
    }, &[12]u32 {
        0, 1, 2, 2, 3, 0,
        4, 5, 6, 6, 7, 4,
    });
}

pub fn destroy() void {
    uiMesh.destroy();
}

pub fn render(camera: Camera) void {
    uiMesh.render2d(uiShader, camera);
}
