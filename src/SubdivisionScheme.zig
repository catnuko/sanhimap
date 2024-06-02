pub const QuadTreeSubdivisionScheme = struct {
    const This = @This();
    pub fn getSubdivisionX(_: This, _: u32) u32 {
        return 2;
    }
    pub fn getSubdivisionY(_: This, _: u32) u32 {
        return 2;
    }
    pub fn getLevelDimensionX(_: This, level: u32) u32 {
        return 1 << level;
    }
    pub fn getLevelDimensionY(_: This, level: u32) u32 {
        return 1 << level;
    }
};

pub const HalfQuadTreeSubdivisionScheme = struct {
    const This = @This();
    pub fn getSubdivisionX(_: This, _: u32) u32 {
        return 2;
    }
    pub fn getSubdivisionY(_: This, level: u32) u32 {
        return if (level == 0) 1 else 2;
    }
    pub fn getLevelDimensionX(_: This, level: u32) u32 {
        return 1 << level;
    }
    pub fn getLevelDimensionY(_: This, level: u32) u32 {
        return if (level != 0) 1 << (level - 1) else 1;
    }
};
