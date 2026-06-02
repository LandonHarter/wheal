const std = @import("std");
const Io = std.Io;

const voxel = @import("voxel");

const glfw = @import("zglfw");
const gl = @import("zgl");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var da: std.heap.DebugAllocator(.{}) = .init;
    defer _ = da.deinit();
    const gpa = da.allocator();

    try glfw.init();
    defer glfw.terminate();

    glfw.windowHint(.context_version_major, 4);
    glfw.windowHint(.context_version_minor, 1);
    glfw.windowHint(.opengl_profile, .opengl_core_profile);
    glfw.windowHint(.opengl_forward_compat, true);

    const window = try glfw.createWindow(800, 600, "Voxel Game - float", null, null); // add "float" so aerospace doesn't tile the window
    defer window.destroy();

    glfw.makeContextCurrent(window);
    glfw.swapInterval(1);
    gl.loadExtensions({}, getProcAddress) catch {}; // macOS caps at GL 4.1; 4.3+ entry points are absent

    const shader = try voxel.Shader.load("resources/shaders/vert.glsl", "resources/shaders/frag.glsl", io, gpa);

    const vertices = [3]voxel.Vertex{
        .{ .pos=.{ .x=0.5, .y=-0.5, .z=0 } },
        .{ .pos=.{ .x=-0.5, .y=-0.5, .z=0 } },
        .{ .pos=.{ .x=0, .y=0.5, .z=0 } }
    };
    const mesh = try voxel.Mesh.create(gpa, &vertices);
    defer mesh.destroy();

    var meshTransform = voxel.Transform{};
    var camera = voxel.Camera{};
    camera.transform.pos.z = 5;

    while (!window.shouldClose()) {
        voxel.Time.startFrame(io);
        gl.clear(.{ .color = true });

        shader.bind();

        const modelArr = [1][4][4]f32{meshTransform.model().data};
        const viewArr = [1][4][4]f32{camera.view().data};
        const projArr = [1][4][4]f32{camera.projection().data};

        shader.program.uniformMatrix4(shader.uniloc("model"), false, &modelArr);
        shader.program.uniformMatrix4(shader.uniloc("view"), false, &viewArr);
        shader.program.uniformMatrix4(shader.uniloc("projection"), false, &projArr);
        mesh.vao.bind();
        gl.drawArrays(.triangles, 0, mesh.count);

        window.swapBuffers();
        glfw.pollEvents();
        voxel.Time.endFrame(io);

        meshTransform.pos.z -= @floatCast(voxel.Time.delta);
    }
}

fn getProcAddress(_: void, name: [:0]const u8) ?gl.binding.FunctionPointer {
    return @ptrCast(@alignCast(glfw.getProcAddress(name.ptr)));
}
