pub const QuadTreeSubdivisionScheme = struct {
    const This = @This();
    pub fn get_subdivision_x(_: This, _: u32) u32 {
        return 2;
    }
    pub fn get_subdivision_y(_: This, _: u32) u32 {
        return 2;
    }
    pub fn get_level_dimension_x(_: This, level: u32) u32 {
        return 1 << level;
    }
    pub fn get_level_dimension_y(_: This, level: u32) u32 {
        return 1 << level;
    }
};

pub const HalfQuadTreeSubdivisionScheme = struct {
    const This = @This();
    pub fn get_subdivision_x(_: This, _: u32) u32 {
        return 2;
    }
    pub fn get_subdivision_y(_: This, level: u32) u32 {
        return if (level == 0) 1 else 2;
    }
    pub fn get_level_dimension_x(_: This, level: u32) u32 {
        return 1 << level;
    }
    pub fn get_level_dimension_y(_: This, level: u32) u32 {
        return if (level != 0) 1 << (level - 1) else 1;
    }
};
