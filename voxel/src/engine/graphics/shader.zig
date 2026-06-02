const std = @import("std");
const gl = @import("zgl");

pub const Shader = struct {
    const Self = @This();

    program: gl.Program,
    uniformLocations: std.StringHashMap(u32),

    pub fn load(vertexContent: []const u8, fragmentContent: []const u8) Shader {
        const vertexShader = gl.createShader(.vertex);
        defer vertexShader.delete();
        vertexShader.source(1, &[_][]const u8{vertexContent});
        vertexShader.compile();

        const fragmentShader = gl.createShader(.fragment);
        defer fragmentShader.delete();
        fragmentShader.source(1, &[_][]const u8{fragmentContent});
        fragmentShader.compile();

        const program = gl.createProgram();
        program.attach(vertexShader);
        program.attach(fragmentShader);
        program.link();

        return Shader {
            .program = program,
            .uniformLocations = .init(std.heap.page_allocator)
        };
    }

    pub fn bind(self: Self) void {
        self.program.use();
    }

    pub fn uniloc(self: Self, name: [:0]const u8) ?u32 {
        return self.program.uniformLocation(name);
    }
};
