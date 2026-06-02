const std = @import("std");
const gl = @import("zgl");

pub const Shader = struct {
    const Self = @This();

    program: gl.Program,
    uniformLocations: std.AutoHashMap([]const u8, u32),

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

    pub fn uniloc(self: Self, name: []const u8) ?u32 {
        if (self.uniformLocations.contains(name)) {
            return self.uniformLocations.get(name);
        }
        const loc = self.program.uniformLocation(name);
        if (loc) {
            self.uniformLocations.put(name, loc);
        }
        return loc;
    }
};
