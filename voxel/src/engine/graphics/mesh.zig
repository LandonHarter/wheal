const std = @import("std");
const gl = @import("zgl");
const Vec3 = @import("../math/vec.zig").Vec3;

pub const Vertex = struct {
    pos: Vec3 = Vec3{},
};

pub const Mesh = struct {
    const Self = @This();

    vao: gl.VertexArray,
    vbo: gl.Buffer,
    count: usize,

    pub fn create(allocator: std.mem.Allocator, vertices: []const Vertex) !Mesh {
        const buffer = try allocator.alloc(f32, vertices.len * 3);
        defer allocator.free(buffer);
        for (vertices, 0..) |vertex, index| {
            buffer[index * 3] = vertex.pos.x;
            buffer[index * 3 + 1] = vertex.pos.y;
            buffer[index * 3 + 2] = vertex.pos.z;
        }

        const vao = gl.genVertexArray();
        vao.bind();

        const vbo = gl.genBuffer();
        vbo.bind(gl.BufferTarget.array_buffer);
        gl.bufferData(gl.BufferTarget.array_buffer, f32, buffer, gl.BufferUsage.static_draw);

        gl.vertexAttribPointer(0, 3, gl.Type.float, false, 3 * @sizeOf(f32), 0);
        gl.enableVertexAttribArray(0);

        gl.bindBuffer(@enumFromInt(0), gl.BufferTarget.array_buffer);

        return Mesh{
            .vao = vao,
            .vbo = vbo,
            .count = vertices.len,
        };
    }

    pub fn destroy(self: Self) void {
        self.vbo.delete();
        self.vao.delete();
    }
};
