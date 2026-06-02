const std = @import("std");
const gl = @import("zgl");

const Vec3 = @import("../math/vec.zig").Vec3;
const Transform = @import("../math/transform.zig").Transform;
const Shader = @import("shader.zig").Shader;
const Camera = @import("../camera.zig").Camera;

pub const Vertex = struct {
    pos: Vec3 = Vec3{},
};

pub const Mesh = struct {
    const Self = @This();

    vao: gl.VertexArray,
    vbo: gl.Buffer,
    ibo: gl.Buffer,
    count: usize,

    transform: Transform = Transform{},

    pub fn create(allocator: std.mem.Allocator, vertices: []const Vertex, indices: []const u32) !Mesh {
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

        const ibo = gl.genBuffer();
        ibo.bind(gl.BufferTarget.element_array_buffer);
        gl.bufferData(gl.BufferTarget.element_array_buffer, u32, indices, gl.BufferUsage.static_draw);

        gl.bindBuffer(@enumFromInt(0), gl.BufferTarget.array_buffer);

        return Mesh{
            .vao = vao,
            .vbo = vbo,
            .ibo = ibo,
            .count = indices.len,
        };
    }

    pub fn destroy(self: Self) void {
        self.ibo.delete();
        self.vbo.delete();
        self.vao.delete();
    }

    pub fn render(self: Self, shader: Shader, camera: Camera) void {
        shader.bind();

        self.vao.bind();
        gl.enableVertexAttribArray(0);

        gl.bindBuffer(self.ibo, .element_array_buffer);

        const modelArr = [1][4][4]f32{self.transform.model().data};
        const viewArr = [1][4][4]f32{camera.view().data};
        const projArr = [1][4][4]f32{camera.projection().data};

        shader.program.uniformMatrix4(shader.uniloc("model"), true, &modelArr);
        shader.program.uniformMatrix4(shader.uniloc("view"), true, &viewArr);
        shader.program.uniformMatrix4(shader.uniloc("projection"), true, &projArr);

        gl.drawElements(.triangles, self.count, .unsigned_int, 0);

        gl.disableVertexAttribArray(0);
    }
};
