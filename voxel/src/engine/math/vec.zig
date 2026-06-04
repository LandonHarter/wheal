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

    pub fn sub(self: Self, other: Vec3) Self {
        return Vec3 {
            .x = self.x - other.x,
            .y = self.y - other.y,
            .z = self.z - other.z,
        };
    }

    pub fn mult(self: Self, scalar: f32) Self {
        return Vec3 {
            .x = self.x * scalar,
            .y = self.y * scalar,
            .z = self.z * scalar,
        };
    }

    pub fn floor(self: Self) Self {
        return Vec3 {
            .x = @floor(self.x),
            .y = @floor(self.y),
            .z = @floor(self.z),
        };
    }

    pub fn normalize(self: Self) Self {
        const n = @sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
        return Vec3 {
            .x = self.x / n,
            .y = self.y / n,
            .z = self.z / n,
        };
    }

    pub fn scale(self: Self, s: f32) Self {
        return Vec3 {
            .x = self.x * s,
            .y = self.y * s,
            .z = self.z * s,
        };
    }

    pub fn lengthSq(self: Self) f32 {
        return self.x * self.x + self.y * self.y + self.z * self.z;
    }

    pub fn length(self: Self) f32 {
        return @sqrt(self.lengthSq());
    }

    pub fn normalized(self: Self) Vec3 {
        const l2 = self.lengthSq();
        if (l2 == 0) return Vec3{};
        const inv = 1.0 / @sqrt(l2);
        return Vec3 { .x = self.x * inv, .y = self.y * inv, .z = self.z * inv };
    }

    pub fn clone(self: Self) Vec3 {
        return Vec3 {
            .x = self.x,
            .y = self.y,
            .z = self.z
        };
    }

    pub fn col(self: Self) Vec3 {
        return Vec3 {
            .x = self.x / 255,
            .y = self.y / 255,
            .z = self.z / 255,
        };
    }

    pub fn clamp(self: *Self, max: Vec3) *Self {
        if (self.x < -max.x) { self.x = -max.x; }
        else if (self.x > max.x) { self.x = max.x; }
 
        if (self.y < -max.y) { self.y = -max.y; }
        else if (self.y > max.y) { self.y = max.y; }

        if (self.z < -max.z) { self.z = -max.z; }
        else if (self.z > max.z) { self.z = max.z; }

        return self;
    }

};

pub const Vec2 = struct {
    x: f32 = 0,
    y: f32 = 0,
};
