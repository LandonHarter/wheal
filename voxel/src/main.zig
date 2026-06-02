const std = @import("std");
const Io = std.Io;

const voxel = @import("voxel");

const glfw = @import("zglfw");
const gl = @import("zgl");

const file = @import("engine/util/file.zig");

const Shader = voxel.Shader;

pub fn main() !void {
    try glfw.init();
    defer glfw.terminate();

    glfw.windowHint(.context_version_major, 4);
    glfw.windowHint(.context_version_minor, 1);
    glfw.windowHint(.opengl_profile, .opengl_core_profile);
    glfw.windowHint(.opengl_forward_compat, true);

    const window = try glfw.createWindow(800, 600, "Voxel Game - float", null, null); // add "float" so aerospace doesn't tile the window
    defer window.destroy();

    glfw.makeContextCurrent(window);
    gl.loadExtensions({}, getProcAddress) catch {}; // macOS caps at GL 4.1; 4.3+ entry points are absent

    const vertexContent = file.read("resources/shaders/vert.glsl");
    const fragmentContent = file.read("resources/shaders/frag.glsl");
    const shader = Shader.load(vertexContent, fragmentContent);

    const vertices = [3]voxel.Vertex{
        .{ .pos=.{ .x=0.5, .y=-0.5, .z=0 } },
        .{ .pos=.{ .x=-0.5, .y=-0.5, .z=0 } },
        .{ .pos=.{ .x=0, .y=0.5, .z=0 } }
    };
    const mesh = try voxel.Mesh.create(std.heap.page_allocator, &vertices);
    defer mesh.destroy();

    while (!window.shouldClose()) {
        gl.clear(.{ .color = true });

        shader.bind();
        mesh.vao.bind();
        gl.drawArrays(.triangles, 0, mesh.count);

        window.swapBuffers();
        glfw.pollEvents();
    }
}

fn getProcAddress(_: void, name: [:0]const u8) ?gl.binding.FunctionPointer {
    return @ptrCast(@alignCast(glfw.getProcAddress(name.ptr)));
}
