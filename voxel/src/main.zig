const std = @import("std");
const Io = std.Io;

const voxel = @import("voxel");

const glfw = @import("zglfw");
const gl = @import("zgl");

pub fn main(init: std.process.Init) !void {
    var da: std.heap.DebugAllocator(.{}) = .init;
    defer _ = da.deinit();
    const gpa = da.allocator();

    const io = init.io;
    voxel.Profiler.init(&io);
    defer voxel.Profiler.destroy(gpa);

    try glfw.init();
    defer glfw.terminate();

    glfw.windowHint(.context_version_major, 4);
    glfw.windowHint(.context_version_minor, 1);
    glfw.windowHint(.opengl_profile, .opengl_core_profile);
    glfw.windowHint(.opengl_forward_compat, true);

    const window = try glfw.createWindow(800, 600, "Voxel Game - float", null, null); // add "float" so aerospace doesn't tile the window
    defer window.destroy();

    glfw.makeContextCurrent(window);
    glfw.swapInterval(0);
    try voxel.Input.init(window);
    gl.loadExtensions({}, getProcAddress) catch {}; // macOS caps at GL 4.1; 4.3+ entry points are absent

    gl.enable(.depth_test);

    voxel.Profiler.start();
    try voxel.World.create(gpa, io);
    defer voxel.World.destroy(gpa);
    _ = voxel.Profiler.end();

    var fps_frames: u32 = 0;
    var fps_elapsed: f64 = 0;
    var fps: f64 = 0;

    while (!window.shouldClose()) {
        voxel.Time.startFrame(io);
        gl.clearColor(0.53, 0.81, 0.92, 1.0);
        gl.clear(.{ .color = true, .depth = true });

        try voxel.World.update(gpa);

        window.swapBuffers();
        glfw.pollEvents();
        voxel.Time.endFrame(io);

        fps_frames += 1;
        fps_elapsed += voxel.Time.delta;
        if (fps_elapsed >= 0.5) {
            fps = @as(f64, @floatFromInt(fps_frames)) / fps_elapsed;
            fps_frames = 0;
            fps_elapsed = 0;
            std.debug.print("FPS: {d:.1}\n", .{fps});
        }
    }
}

fn getProcAddress(_: void, name: [:0]const u8) ?gl.binding.FunctionPointer {
    return @ptrCast(@alignCast(glfw.getProcAddress(name.ptr)));
}
