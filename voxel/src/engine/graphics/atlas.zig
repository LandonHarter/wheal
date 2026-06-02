const std = @import("std");
const gl = @import("zgl");
const zigimg = @import("zigimg");

const constants = @import("../../voxel/constants.zig");

const BLOCKS_PER_ROW: usize = constants.TEXTURE_ATLAS_SIZE;
const BLOCK_PATH_PREFIX = "assets/minecraft/textures/block/";

pub const AtlasResult = struct {
    texture: gl.Texture,
    atlas_size: u32,
    block_size: u32,
};

pub fn build(
    gpa: std.mem.Allocator,
    io: std.Io,
    zip_path: []const u8,
    blocks_list_path: []const u8,
) !AtlasResult {
    const block_names = try readBlockNames(gpa, io, blocks_list_path);
    defer {
        for (block_names) |name| gpa.free(name);
        gpa.free(block_names);
    }

    if (block_names.len == 0) return error.NoBlocksListed;

    var file = try std.Io.Dir.cwd().openFile(io, zip_path, .{});
    defer file.close(io);

    var file_buf: [4096]u8 = undefined;
    var file_reader = file.reader(io, &file_buf);

    var entries: std.StringHashMap(std.zip.Iterator.Entry) = .init(gpa);
    defer {
        var key_it = entries.keyIterator();
        while (key_it.next()) |k| gpa.free(k.*);
        entries.deinit();
    }

    try collectBlockEntries(&file_reader, &entries, gpa);

    var path_buf: [std.fs.max_path_bytes]u8 = undefined;

    const first_path = try std.fmt.bufPrint(&path_buf, BLOCK_PATH_PREFIX ++ "{s}.png", .{block_names[0]});
    const first_entry = entries.get(first_path) orelse {
        std.debug.print("atlas: missing block texture {s}\n", .{first_path});
        return error.MissingBlockTexture;
    };

    const first_png = try extractEntry(&file_reader, first_entry, gpa);
    defer gpa.free(first_png);

    var first_image = try zigimg.Image.fromMemory(gpa, first_png);
    defer first_image.deinit(gpa);
    try first_image.convert(gpa, .rgba32);

    if (first_image.width != first_image.height) return error.NonSquareTexture;
    const block_size: u32 = @intCast(first_image.width);
    const atlas_size: u32 = block_size * @as(u32, @intCast(BLOCKS_PER_ROW));

    std.debug.print("atlas: block_size={d}x{d}, atlas={d}x{d}\n", .{ block_size, block_size, atlas_size, atlas_size });

    const atlas = try gpa.alloc(u8, atlas_size * atlas_size * 4);
    defer gpa.free(atlas);
    @memset(atlas, 0);

    var index: usize = 1;
    blitBlock(atlas, atlas_size, first_image.pixels.asBytes(), block_size, index);
    index += 1;

    for (block_names[1..]) |name| {
        const path = try std.fmt.bufPrint(&path_buf, BLOCK_PATH_PREFIX ++ "{s}.png", .{name});
        const entry = entries.get(path) orelse {
            std.debug.print("atlas: missing block texture {s}\n", .{path});
            return error.MissingBlockTexture;
        };

        const png_bytes = try extractEntry(&file_reader, entry, gpa);
        defer gpa.free(png_bytes);

        var image = try zigimg.Image.fromMemory(gpa, png_bytes);
        defer image.deinit(gpa);
        try image.convert(gpa, .rgba32);

        if (image.width != block_size or image.height != block_size) {
            std.debug.print("atlas: {s} is {d}x{d}, expected {d}x{d}\n", .{ path, image.width, image.height, block_size, block_size });
            return error.BlockSizeMismatch;
        }

        blitBlock(atlas, atlas_size, image.pixels.asBytes(), block_size, index);
        index += 1;
    }

    const texture = uploadTexture(atlas, atlas_size);

    return .{
        .texture = texture,
        .atlas_size = atlas_size,
        .block_size = block_size,
    };
}

fn readBlockNames(gpa: std.mem.Allocator, io: std.Io, path: []const u8) ![][]u8 {
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, path, gpa, .unlimited);
    defer gpa.free(contents);

    var names: std.ArrayList([]u8) = .empty;
    errdefer {
        for (names.items) |item| gpa.free(item);
        names.deinit(gpa);
    }

    var it = std.mem.splitScalar(u8, contents, '\n');
    while (it.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \t\r\n");
        if (line.len == 0) continue;
        try names.append(gpa, try gpa.dupe(u8, line));
    }

    return names.toOwnedSlice(gpa);
}

fn collectBlockEntries(
    file_reader: *std.Io.File.Reader,
    entries: *std.StringHashMap(std.zip.Iterator.Entry),
    gpa: std.mem.Allocator,
) !void {
    var iter = try std.zip.Iterator.init(file_reader);

    var name_buf: [std.fs.max_path_bytes]u8 = undefined;
    while (try iter.next()) |entry| {
        if (entry.filename_len == 0 or entry.filename_len > name_buf.len) continue;

        try file_reader.seekTo(entry.header_zip_offset + @sizeOf(std.zip.CentralDirectoryFileHeader));
        try file_reader.interface.readSliceAll(name_buf[0..entry.filename_len]);

        const name = name_buf[0..entry.filename_len];
        if (!std.mem.startsWith(u8, name, BLOCK_PATH_PREFIX)) continue;
        if (!std.mem.endsWith(u8, name, ".png")) continue;

        const key = try gpa.dupe(u8, name);
        errdefer gpa.free(key);
        try entries.put(key, entry);
    }
}

fn extractEntry(
    file_reader: *std.Io.File.Reader,
    entry: std.zip.Iterator.Entry,
    gpa: std.mem.Allocator,
) ![]u8 {
    try file_reader.seekTo(entry.file_offset);
    const local_header = try file_reader.interface.takeStruct(std.zip.LocalFileHeader, .little);
    if (!std.mem.eql(u8, &local_header.signature, &std.zip.local_file_header_sig)) return error.ZipBadFileOffset;

    const data_offset: u64 = entry.file_offset
        + @sizeOf(std.zip.LocalFileHeader)
        + @as(u64, local_header.filename_len)
        + @as(u64, local_header.extra_len);
    try file_reader.seekTo(data_offset);

    const buf = try gpa.alloc(u8, @intCast(entry.uncompressed_size));
    errdefer gpa.free(buf);
    var writer = std.Io.Writer.fixed(buf);

    switch (entry.compression_method) {
        .store => try file_reader.interface.streamExact64(&writer, entry.uncompressed_size),
        .deflate => {
            var flate_buf: [std.compress.flate.max_window_len]u8 = undefined;
            var decompress: std.compress.flate.Decompress = .init(&file_reader.interface, .raw, &flate_buf);
            try decompress.reader.streamExact64(&writer, entry.uncompressed_size);
        },
        else => return error.UnsupportedCompressionMethod,
    }

    return buf;
}

fn blitBlock(atlas: []u8, atlas_size: u32, block_rgba: []const u8, block_size: u32, index: usize) void {
    const row: u32 = @intCast(index / BLOCKS_PER_ROW);
    const col: u32 = @intCast(index % BLOCKS_PER_ROW);
    const dst_x = col * block_size;
    const dst_y = row * block_size;

    var y: u32 = 0;
    while (y < block_size) : (y += 1) {
        const src_start = y * block_size * 4;
        const dst_start = ((dst_y + y) * atlas_size + dst_x) * 4;
        @memcpy(atlas[dst_start .. dst_start + block_size * 4], block_rgba[src_start .. src_start + block_size * 4]);
    }
}

fn uploadTexture(rgba: []const u8, size: u32) gl.Texture {
    const tex = gl.genTexture();
    gl.bindTexture(tex, .@"2d");

    gl.texParameter(.@"2d", .wrap_s, .clamp_to_edge);
    gl.texParameter(.@"2d", .wrap_t, .clamp_to_edge);
    gl.texParameter(.@"2d", .min_filter, .nearest);
    gl.texParameter(.@"2d", .mag_filter, .nearest);

    gl.textureImage2D(.@"2d", 0, .rgba, size, size, .rgba, .unsigned_byte, rgba.ptr);

    gl.bindTexture(@enumFromInt(0), .@"2d");
    return tex;
}
