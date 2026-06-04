pub const Blocks = enum(u8) {
    AIR,
    DIRT,
    GRASS,
    STONE,
    BEDROCK,
};

pub const Block = struct {
    type: u8
};
