const std = @import("std");
const gl = @import("zgl");

const vec = @import("../math/vec.zig");
const Vec3 = vec.Vec3;
const Vec2 = vec.Vec2;

const Transform = @import("../math/transform.zig").Transform;
const Shader = @import("shader.zig").Shader;
const Camera = @import("../camera.zig").Camera;

pub const Vertex = struct {
    pos: Vec3 = Vec3{},
    uv: Vec2 = Vec2{},
};

pub const Mesh = struct {
    const Self = @This();

    vao: gl.VertexArray,
    vbo: gl.Buffer,
    ibo: gl.Buffer,
    count: usize,

    transform: Transform = Transform{},

    pub fn create(allocator: std.mem.Allocator, vertices: []const Vertex, indices: []const u32) !Mesh {
        const vertexBuffer = try allocator.alloc(f32, vertices.len * 3);
        defer allocator.free(vertexBuffer);
        for (vertices, 0..) |vertex, index| {
            vertexBuffer[index * 3] = vertex.pos.x;
            vertexBuffer[index * 3 + 1] = vertex.pos.y;
            vertexBuffer[index * 3 + 2] = vertex.pos.z;
        }

        const uvBuffer = try allocator.alloc(f32, vertices.len * 2);
        defer allocator.free(uvBuffer);
        for (vertices, 0..) |vertex, index| {
            uvBuffer[index * 2] = vertex.uv.x;
            uvBuffer[index * 2 + 1] = vertex.uv.y;
        }

        const vao = gl.genVertexArray();
        vao.bind();

        const vbo = gl.genBuffer();
        vbo.bind(gl.BufferTarget.array_buffer);
        gl.bufferData(gl.BufferTarget.array_buffer, f32, vertexBuffer, gl.BufferUsage.static_draw);

        gl.vertexAttribPointer(0, 3, gl.Type.float, false, 3 * @sizeOf(f32), 0);
        gl.enableVertexAttribArray(0);

        const ibo = gl.genBuffer();
        ibo.bind(gl.BufferTarget.element_array_buffer);
        gl.bufferData(gl.BufferTarget.element_array_buffer, u32, indices, gl.BufferUsage.static_draw);

        gl.bindBuffer(@enumFromInt(0), gl.BufferTarget.array_buffer);

        const ubo = gl.genBuffer();
        ubo.bind(gl.BufferTarget.array_buffer);
        gl.bufferData(gl.BufferTarget.array_buffer, f32, uvBuffer, gl.BufferUsage.static_draw);

        gl.vertexAttribPointer(1, 2, gl.Type.float, false, 2 * @sizeOf(f32), 0);
        gl.enableVertexAttribArray(1);

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
