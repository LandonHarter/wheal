const glfw = @import("zglfw");

var window: *glfw.Window = undefined;

var last_x: f64 = 0;
var last_y: f64 = 0;
var mouse_dx: f32 = 0;
var mouse_dy: f32 = 0;
var first_mouse: bool = true;

pub fn init(w: *glfw.Window) !void {
    window = w;
    try w.setInputMode(.cursor, .disabled);
}

pub fn update() void {
    const pos = window.getCursorPos();
    if (first_mouse) {
        last_x = pos[0];
        last_y = pos[1];
        first_mouse = false;
    }
    mouse_dx = @floatCast(pos[0] - last_x);
    mouse_dy = @floatCast(pos[1] - last_y);
    last_x = pos[0];
    last_y = pos[1];
}

pub fn isKeyDown(key: glfw.Key) bool {
    return window.getKey(key) == .press;
}

pub fn isKeyUp(key: glfw.Key) bool {
    return window.getKey(key) == .release;
}

pub fn mouseDx() f32 {
    return mouse_dx;
}

pub fn mouseDy() f32 {
    return mouse_dy;
}
