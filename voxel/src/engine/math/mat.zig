const vec = @import("vec.zig");

pub const Mat4 = struct {
    const Self = @This();

    data: [4][4]f32 = .{
        .{ 1, 0, 0, 0 },
        .{ 0, 1, 0, 0 },
        .{ 0, 0, 1, 0 },
        .{ 0, 0, 0, 1 },
    },

    fn set(self: *Self, other: Mat4) void {
        self.data = other.data;
    }

    fn mult(self: *Self, other: Mat4) void {
        var out = Mat4{};

        for (0..4) |row| {
            for (0..4) |col| {
                out.data[row][col] =
                    self.data[row][0] * other.data[0][col] +
                    self.data[row][1] * other.data[1][col] +
                    self.data[row][2] * other.data[2][col] +
                    self.data[row][3] * other.data[3][col];
            }
        }

        self.set(out);
    }

    pub fn translate(self: *Self, translation: vec.Vec3) void {
        const translationMat = Mat4{
            .data = .{
                .{ 1, 0, 0, translation.x },
                .{ 0, 1, 0, translation.y },
                .{ 0, 0, 1, translation.z },
                .{ 0, 0, 0, 1 },
            },
        };
        self.mult(translationMat);
    }
};
