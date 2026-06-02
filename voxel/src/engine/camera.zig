const Transform = @import("math/transform.zig").Transform;
const Mat4 = @import("math/mat.zig").Mat4;

const Camera = struct {
    const Self = @This();

    transform: Transform,
};
