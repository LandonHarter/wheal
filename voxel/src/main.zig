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
    try voxel.Input.init(window);
    gl.loadExtensions({}, getProcAddress) catch {}; // macOS caps at GL 4.1; 4.3+ entry points are absent

    gl.enable(.depth_test);

    var profiler = voxel.Profiler{};

    profiler.start(io);
    try voxel.World.create(gpa, io);
    defer voxel.World.destroy(gpa);
    try voxel.World.generate(gpa);
    const worldLoadTime = profiler.end(io);
    std.debug.print("World took {} seconds to generate.", .{worldLoadTime});

    while (!window.shouldClose()) {
        voxel.Time.startFrame(io);
        gl.clearColor(0.53, 0.81, 0.92, 1.0);
        gl.clear(.{ .color = true, .depth = true });

        voxel.World.update();

        window.swapBuffers();
        glfw.pollEvents();
        voxel.Time.endFrame(io);
    }
}

fn getProcAddress(_: void, name: [:0]const u8) ?gl.binding.FunctionPointer {
    return @ptrCast(@alignCast(glfw.getProcAddress(name.ptr)));
}
