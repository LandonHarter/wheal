const std = @import("std");
const gl = @import("zgl");
const chunk = @import("chunking/chunk.zig");
const Player = @import("player/player.zig").Player;
const Vec3 = @import("../engine/math/vec.zig").Vec3;
const Shader = @import("../engine/graphics/shader.zig").Shader;
const atlas_mod = @import("../engine/graphics/atlas.zig");
const constants = @import("constants.zig");
const Time = @import("../engine/core/time.zig");
const Input = @import("../engine/core/input.zig");

const WORLD_SIZE = 5;
var chunks: std.hash_map.AutoHashMap(chunk.ChunkCoord, chunk.Chunk) = undefined;

pub var player: Player = Player{};

var shader: Shader = undefined;
var atlas: atlas_mod.AtlasResult = undefined;

pub fn create(gpa: std.mem.Allocator, io: std.Io) !void {
    chunks = .init(gpa);
    shader = try Shader.load("resources/shaders/vert.glsl", "resources/shaders/frag.glsl", io, gpa);

    atlas = try atlas_mod.build(gpa, io, "resources/default.zip", "resources/atlas-blocks.txt");
    gl.programUniform1i(shader.program, shader.uniloc("atlas"), 0);

    player.camera.transform.pos.y = 35;
    player.camera.transform.pos.z = 10;

    var x: u8 = 0;
    while (x <= WORLD_SIZE) : (x += 1) {
        var z: u8 = 0;
        while (z <= WORLD_SIZE) : (z += 1) {
            const coord = chunk.ChunkCoord{ .x=x, .z=z };
            try chunks.put(coord, chunk.Chunk.create(coord));
        }
    }
}

pub fn generate(allocator: std.mem.Allocator) !void {
    var it = chunks.valueIterator();
    while (it.next()) |chunk_ptr| {
        chunk_ptr.*.populate();
    }

    it = chunks.valueIterator();
    while (it.next()) |chunk_ptr| {
        try chunk_ptr.*.generate(allocator);
    }
}

pub fn update() void {
    Input.update();
    player.update(@floatCast(Time.delta));

    gl.activeTexture(.texture_0);
    gl.bindTexture(atlas.texture, .@"2d");

    var it = chunks.valueIterator();
    while (it.next()) |chunk_ptr| {
        try chunk_ptr.*.update(shader);
    }
}

pub fn destroy(allocator: std.mem.Allocator) void {
    var it = chunks.valueIterator();
    while (it.next()) |chunk_ptr| {
        chunk_ptr.*.destroy(allocator);
    }
    
    chunks.deinit();
}

pub fn checkVoxel(pos: Vec3) bool {
    if (pos.y < 0 or pos.y >= constants.CHUNK_HEIGHT) return false;

    const cx = @as(i32, @intFromFloat(@floor(pos.x / constants.CHUNK_WIDTH)));
    const cz = @as(i32, @intFromFloat(@floor(pos.z / constants.CHUNK_WIDTH)));
    const coord = chunk.ChunkCoord{ .x = cx, .z = cz };
    const c = chunks.get(coord) orelse return false;

    const local = Vec3{
        .x = pos.x - @as(f32, @floatFromInt(cx * constants.CHUNK_WIDTH)),
        .y = pos.y,
        .z = pos.z - @as(f32, @floatFromInt(cz * constants.CHUNK_WIDTH)),
    };
    return c.checkVoxel(local);
}
