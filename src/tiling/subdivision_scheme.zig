pub const QuadTreeSubdivisionScheme = struct {
    pub fn get_subdivision_x() u32 {
        return 2;
    }
    pub fn get_subdivision_y() u32 {
        return 2;
    }
    pub fn get_level_dimension_x(level: u32) u32 {
        return 1 << level;
    }
    pub fn get_level_dimension_y(level: u32) u32 {
        return 1 << level;
    }
};

pub const HalfQuadTreeSubdivisionScheme = struct {
    pub fn get_subdivision_x() u32 {
        return 2;
    }
    pub fn get_subdivision_y(level: u32) u32 {
        return if (level == 0) 1 else 2;
    }
    pub fn get_level_dimension_x(level: u32) u32 {
        return 1 << level;
    }
    pub fn get_level_dimension_y(level: u32) u32 {
        return if (level != 0) 1 << (level - 1) else 1;
    }
};
