pub const Vec3 = struct {
    const Self = @This();

    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,

    pub fn set(self: *Self, other: Vec3) *Self {
        self.x = other.x;
        self.y = other.y;
        self.z = other.z;
        return self;
    }

    pub fn add(self: Self, other: Vec3) Self {
        return Vec3 {
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
        };
    }

    pub fn clone(self: Self) Vec3 {
        return Vec3 {
            .x = self.x,
            .y = self.y,
            .z = self.z
        };
    }

};
