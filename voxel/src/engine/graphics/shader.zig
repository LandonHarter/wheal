const std = @import("std");
const gl = @import("zgl");

const file = @import("../util/file.zig");

pub const Shader = struct {
    const Self = @This();

    program: gl.Program,
    uniformLocations: std.StringHashMap(u32),

    pub fn load(vertexPath: []const u8, fragmentPath: []const u8, io: std.Io, gpa: std.mem.Allocator) !Shader {
        const vertexContent = try file.read(vertexPath, io, gpa);
        defer gpa.free(vertexContent);
        const fragmentContent = try file.read(fragmentPath, io, gpa);
        defer gpa.free(fragmentContent);

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
            .uniformLocations = .init(gpa)
        };
    }

    pub fn bind(self: Self) void {
        self.program.use();
    }

    pub fn uniloc(self: Self, name: [:0]const u8) ?u32 {
        return self.program.uniformLocation(name);
    }
};
