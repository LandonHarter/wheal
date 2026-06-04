const std = @import("std");
const gl = @import("zgl");
const chunk = @import("chunking/chunk.zig");
const Player = @import("player/player.zig").Player;
const Vec3 = @import("../engine/math/vec.zig").Vec3;
const Shader = @import("../engine/graphics/shader.zig").Shader;
const Profiler = @import("../engine/performance.zig");
const atlas_mod = @import("../engine/graphics/atlas.zig");
const constants = @import("constants.zig");
const Time = @import("../engine/core/time.zig");
const Input = @import("../engine/core/input.zig");
const Noise = @import("noise.zig");

var chunks: std.hash_map.AutoHashMap(chunk.ChunkCoord, chunk.Chunk) = undefined;
var activeChunks: std.AutoHashMapUnmanaged(chunk.ChunkCoord, void) = .empty;
var noise: Noise.PerlinGenerator = undefined;

pub var player: Player = Player{};

var shader: Shader = undefined;
var atlas: atlas_mod.AtlasResult = undefined;

pub fn create(gpa: std.mem.Allocator, io: std.Io) !void {
    chunks = .init(gpa);

    shader = try Shader.load("resources/shaders/chunk/vert.glsl", "resources/shaders/chunk/frag.glsl", io, gpa);
    try Profiler.event("chunk_shader_load", gpa);

    atlas = try atlas_mod.build(gpa, io, "resources/default.zip", "resources/atlas-blocks.txt");
    gl.programUniform1i(shader.program, shader.uniloc("atlas"), 0);
    try Profiler.event("build_atlas", gpa);

    const seed: u32 = @as(u32, @intCast(std.Io.Clock.awake.now(io).toMilliseconds()));
    noise = try Noise.PerlinGenerator.init(gpa, seed);
    noise.falloff = 0.5;
    noise.octaves = 4;

    player.camera.transform.pos.y = 35;
    player.camera.transform.pos.z = 10;

    try checkViewDistance(gpa);
}

pub fn update(gpa: std.mem.Allocator) !void {
    Input.update();
    try player.update(@floatCast(Time.delta), gpa);

    gl.activeTexture(.texture_0);
    gl.bindTexture(atlas.texture, .@"2d");

    var it = chunks.valueIterator();
    while (it.next()) |chunk_ptr| {
        try chunk_ptr.*.update(shader);
    }

    const currentCoord = player.getChunkCoord();
    if (!currentCoord.equals(player.lastChunkCoord)) {
        try checkViewDistance(gpa);
        player.lastChunkCoord = currentCoord;
    }
}

pub fn destroy(allocator: std.mem.Allocator) void {
    var it = chunks.valueIterator();
    while (it.next()) |chunk_ptr| {
        chunk_ptr.*.destroy(allocator);
    }
    
    noise.deinit();
    activeChunks.deinit(allocator);
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

pub fn setVoxel(pos: Vec3, blockType: u8, gpa: std.mem.Allocator) !void {
    if (pos.y < 0 or pos.y >= constants.CHUNK_HEIGHT) return;

    const cx = @as(i32, @intFromFloat(@floor(pos.x / constants.CHUNK_WIDTH)));
    const cz = @as(i32, @intFromFloat(@floor(pos.z / constants.CHUNK_WIDTH)));
    const coord = chunk.ChunkCoord{ .x = cx, .z = cz };
    const c = chunks.getPtr(coord) orelse return;

    const local = Vec3{
        .x = pos.x - @as(f32, @floatFromInt(cx * constants.CHUNK_WIDTH)),
        .y = pos.y,
        .z = pos.z - @as(f32, @floatFromInt(cz * constants.CHUNK_WIDTH)),
    };
    c.setVoxel(local, blockType);

    try c.rebuildBlocks(gpa);
    try c.refinalize(gpa);

    const lx = @as(i32, @intFromFloat(local.x));
    const lz = @as(i32, @intFromFloat(local.z));
    const edges = [_]struct { hit: bool, ncoord: chunk.ChunkCoord }{
        .{ .hit = lx == 0,                              .ncoord = .{ .x = cx - 1, .z = cz } },
        .{ .hit = lx == constants.CHUNK_WIDTH - 1,      .ncoord = .{ .x = cx + 1, .z = cz } },
        .{ .hit = lz == 0,                              .ncoord = .{ .x = cx, .z = cz - 1 } },
        .{ .hit = lz == constants.CHUNK_WIDTH - 1,      .ncoord = .{ .x = cx, .z = cz + 1 } },
    };
    for (edges) |e| {
        if (!e.hit) continue;
        const np = chunks.getPtr(e.ncoord) orelse continue;
        if (!np.generated) continue;
        try np.rebuildBlocks(gpa);
        try np.refinalize(gpa);
    }
}

fn checkViewDistance(gpa: std.mem.Allocator) !void {
    const currentCoord = player.getChunkCoord();

    var previouslyActiveChunks = try activeChunks.clone(gpa);
    defer previouslyActiveChunks.deinit(gpa);

    var newChunks: std.ArrayList(chunk.ChunkCoord) = .empty;
    defer newChunks.deinit(gpa);

    var x: i32 = currentCoord.x - constants.VIEW_DISTANCE / 2;
    while (x < currentCoord.x + constants.VIEW_DISTANCE / 2) : (x += 1) {
        var z: i32 = currentCoord.z - constants.VIEW_DISTANCE / 2;
        while (z < currentCoord.z + constants.VIEW_DISTANCE / 2) : (z += 1) {
            const coord = chunk.ChunkCoord{ .x=x, .z=z };
            if (!chunks.contains(coord)) {
                try chunks.put(coord, chunk.Chunk.create(coord));
                try activeChunks.put(gpa, coord, {});
                try newChunks.append(gpa, coord);
            } else if (!chunks.getPtr(coord).?.*.active) {
                chunks.getPtr(coord).?.*.active = true;
                try activeChunks.put(gpa, coord, {});
            }
            _ = previouslyActiveChunks.remove(coord);
        }
    }

    var it = previouslyActiveChunks.keyIterator();
    while (it.next()) |cc| {
        chunks.getPtr(cc.*).?.*.active = false;
        _ = activeChunks.remove(cc.*);
    }

    if (newChunks.items.len == 0) return;

    for (newChunks.items) |coord| {
        chunks.getPtr(coord).?.populate(&noise);
    }

    var vit = chunks.valueIterator();
    while (vit.next()) |chunk_ptr| {
        var i: usize = 0;
        while (i < chunk_ptr.*.neighbors.len) : (i += 1) {
            chunk_ptr.*.neighbor_ptrs[i] = chunks.getPtr(chunk_ptr.*.neighbors[i]);
        }
    }

    const ThreadCtx = struct {
        c: *chunk.Chunk,
        alloc: std.mem.Allocator,
        is_new: bool,
        err: ?anyerror = null,

        fn run(self: *@This()) void {
            if (self.is_new) {
                self.c.generate(self.alloc) catch |e| { self.err = e; };
            } else {
                self.c.rebuildBlocks(self.alloc) catch |e| { self.err = e; };
            }
        }
    };

    var new_set: std.AutoHashMapUnmanaged(chunk.ChunkCoord, void) = .empty;
    defer new_set.deinit(gpa);
    for (newChunks.items) |c| try new_set.put(gpa, c, {});

    var remesh_set: std.AutoHashMapUnmanaged(chunk.ChunkCoord, void) = .empty;
    defer remesh_set.deinit(gpa);

    for (newChunks.items) |coord| {
        const c_ptr = chunks.getPtr(coord).?;
        for (c_ptr.neighbors) |ncoord| {
            if (new_set.contains(ncoord)) continue;
            const np = chunks.getPtr(ncoord) orelse continue;
            if (!np.generated) continue;
            try remesh_set.put(gpa, ncoord, {});
        }
    }

    const remesh_count = remesh_set.count();
    const total = newChunks.items.len + remesh_count;

    const ctxs = try gpa.alloc(ThreadCtx, total);
    defer gpa.free(ctxs);
    const threads = try gpa.alloc(std.Thread, total);
    defer gpa.free(threads);

    for (newChunks.items, 0..) |coord, i| {
        ctxs[i] = .{ .c = chunks.getPtr(coord).?, .alloc = gpa, .is_new = true };
        threads[i] = try std.Thread.spawn(.{}, ThreadCtx.run, .{&ctxs[i]});
    }
    {
        var rit = remesh_set.keyIterator();
        var i: usize = newChunks.items.len;
        while (rit.next()) |cc| : (i += 1) {
            ctxs[i] = .{ .c = chunks.getPtr(cc.*).?, .alloc = gpa, .is_new = false };
            threads[i] = try std.Thread.spawn(.{}, ThreadCtx.run, .{&ctxs[i]});
        }
    }
    for (threads) |t| t.join();
    for (ctxs) |c| if (c.err) |e| return e;

    for (newChunks.items) |coord| {
        try chunks.getPtr(coord).?.finalize(gpa);
    }
    var rit = remesh_set.keyIterator();
    while (rit.next()) |cc| {
        try chunks.getPtr(cc.*).?.refinalize(gpa);
    }
}
