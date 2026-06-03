const std = @import("std");
const mesh = @import("../../engine/graphics/mesh.zig");
const constants = @import("../constants.zig");
const vec = @import("../../engine/math/vec.zig");
const Vec3 = vec.Vec3;
const Vec2 = vec.Vec2;
const Shader = @import("../../engine/graphics/shader.zig").Shader;

const block = @import("../blocks/block.zig");
const World = @import("../world.zig");

pub const ChunkCoord = struct {
    x: i32,
    z: i32
};

pub const Chunk = struct {
    const Self = @This();

    coord: ChunkCoord,
    neighbors: [4]ChunkCoord,

    mesh: mesh.Mesh,
    blocks: [constants.CHUNK_WIDTH][constants.CHUNK_HEIGHT][constants.CHUNK_WIDTH]block.Block,

    vertices: std.ArrayList(mesh.Vertex),
    indices: std.ArrayList(u32),

    vertexIndex: u32 = 0,

    pub fn create(coord: ChunkCoord) Chunk {
        return Chunk {
            .coord = coord,
            .neighbors = [4]ChunkCoord{
                ChunkCoord{ .x=coord.x-1, .z=coord.z },
                ChunkCoord{ .x=coord.x+1, .z=coord.z },
                ChunkCoord{ .x=coord.x, .z=coord.z-1 },
                ChunkCoord{ .x=coord.x, .z=coord.z+1 }
            },
            .blocks = @splat(@splat(@splat(block.Block{ .type = 0 }))),
            .mesh = undefined,
            .vertices = .empty,
            .indices = .empty
        };
    }

    pub fn update(self: Self, shader: Shader) !void {
        self.mesh.render(shader, World.player.camera);
    }

    pub fn destroy(self: *Self, allocator: std.mem.Allocator) void {
        self.vertices.deinit(allocator);
        self.indices.deinit(allocator);
    }

    pub fn generate(self: *Self, allocator: std.mem.Allocator) !void {
        try self.buildBlocks(allocator);
        try self.createMeshData(allocator);
    }

    pub fn checkVoxel(self: Self, pos: Vec3) bool {
        if (!inChunk(pos)) {
            const world_pos = Vec3{
                .x = pos.x + @as(f32, @floatFromInt(self.coord.x * constants.CHUNK_WIDTH)),
                .y = pos.y,
                .z = pos.z + @as(f32, @floatFromInt(self.coord.z * constants.CHUNK_WIDTH)),
            };
            return World.checkVoxel(world_pos);
        }

        const x = @as(usize, @intFromFloat(pos.x));
        const y = @as(usize, @intFromFloat(pos.y));
        const z = @as(usize, @intFromFloat(pos.z));

        return self.blocks[x][y][z].type != @intFromEnum(block.Blocks.AIR);
    }

    pub fn inChunk(pos: Vec3) bool {
        const x = @as(i32, @intFromFloat(pos.x));
        const y = @as(i32, @intFromFloat(pos.y));
        const z = @as(i32, @intFromFloat(pos.z));

        return x >= 0 and x < constants.CHUNK_WIDTH
            and y >= 0 and y < constants.CHUNK_HEIGHT
            and z >= 0 and z < constants.CHUNK_WIDTH;
    }

    pub fn worldPos(self: Self) Vec3 {
        return Vec3{
            .x = self.coord.x * constants.CHUNK_WIDTH,
            .y = 0,
            .z = self.coord.z * constants.CHUNK_WIDTH
        };
    }

    pub fn populate(self: *Self) void {
        var x: u8 = 0;
        while (x < self.blocks.len) : (x += 1) {
            var y: u8 = 0;
            while (y < self.blocks[x].len) : (y += 1) {
                var z: u8 = 0;
                while (z < self.blocks[x][y].len) : (z += 1) {
                    self.blocks[x][y][z].type = @intFromEnum(if (y > 32) block.Blocks.AIR else block.Blocks.GRASS);
                }
            }
        }
    }

    fn buildBlocks(self: *Self, allocator: std.mem.Allocator) !void {
        var x: u8 = 0;
        while (x < self.blocks.len) : (x += 1) {
            var y: u8 = 0;
            while (y < self.blocks[x].len) : (y += 1) {
                var z: u8 = 0;
                while (z < self.blocks[x][y].len) : (z += 1) {
                    if (self.blocks[x][y][z].type != @intFromEnum(block.Blocks.AIR)) {
                        try self.addToChunk(Vec3{ .x = @floatFromInt(x), .y = @floatFromInt(y), .z = @floatFromInt(z) }, self.blocks[x][y][z], allocator);
                    }
                }
            }
        }
    }

    fn addToChunk(self: *Self, pos: Vec3, voxel: block.Block, allocator: std.mem.Allocator) !void {
        var tempPos: Vec3 = .{};
        var i: u8 = 0;
        while (i < 6) : (i += 1) {
            _ = tempPos.set(pos);
            tempPos = tempPos.add(constants.FACE_CHECKS[i]);

            if (!self.checkVoxel(tempPos)) {
                const tile_uv = computeTileUv(voxel.type, i);
                const color = constants.BLOCK_TYPES[voxel.type].colors[i];
                try self.vertices.appendSlice(allocator, &[4]mesh.Vertex {
                    mesh.Vertex{ .pos = pos.clone().add(constants.BLOCK_VERTICES[constants.BLOCK_INDICES[i][0]]), .uv = .{ .x = tile_uv.u0, .y = tile_uv.v1 }, .color = color },
                    mesh.Vertex{ .pos = pos.clone().add(constants.BLOCK_VERTICES[constants.BLOCK_INDICES[i][1]]), .uv = .{ .x = tile_uv.u0, .y = tile_uv.v0 }, .color = color },
                    mesh.Vertex{ .pos = pos.clone().add(constants.BLOCK_VERTICES[constants.BLOCK_INDICES[i][2]]), .uv = .{ .x = tile_uv.u1, .y = tile_uv.v1 }, .color = color },
                    mesh.Vertex{ .pos = pos.clone().add(constants.BLOCK_VERTICES[constants.BLOCK_INDICES[i][3]]), .uv = .{ .x = tile_uv.u1, .y = tile_uv.v0 }, .color = color },
                });
                try self.indices.appendSlice(allocator, &[6]u32 {
                    self.vertexIndex,
                    self.vertexIndex + 1,
                    self.vertexIndex + 2,
                    self.vertexIndex + 2,
                    self.vertexIndex + 1,
                    self.vertexIndex + 3,
                });

                self.vertexIndex += 4;
            }
        }
    }

    const TileUv = struct { u0: f32, v0: f32, u1: f32, v1: f32 };

    fn computeTileUv(block_type: u8, face: u8) TileUv {
        const n: f32 = @floatFromInt(constants.TEXTURE_ATLAS_SIZE);
        const tile: u16 = constants.BLOCK_TYPES[block_type].textures[face];
        const col: f32 = @floatFromInt(tile % constants.TEXTURE_ATLAS_SIZE);
        const row: f32 = @floatFromInt(tile / constants.TEXTURE_ATLAS_SIZE);
        return .{
            .u0 = col / n,
            .v0 = row / n,
            .u1 = (col + 1) / n,
            .v1 = (row + 1) / n,
        };
    }

    fn createMeshData(self: *Self, allocator: std.mem.Allocator) !void {
        self.mesh = try mesh.Mesh.create(allocator, self.vertices.items, self.indices.items);
        self.mesh.transform.pos.x = @as(f32, @floatFromInt(self.coord.x * constants.CHUNK_WIDTH));
        self.mesh.transform.pos.z = @as(f32, @floatFromInt(self.coord.z * constants.CHUNK_WIDTH));
    }

};
