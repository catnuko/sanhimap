const math = @import("std").math;
pub const TileKey = struct {
    row: u32,
    column: u32,
    level: u32,
    m_mortonCode: undefined,
    pub fn new(row: u32, column: u32, level: u32) TileKey {
        return .{
            .row = row,
            .column = column,
            .level = level,
        };
    }
    pub fn parent(self: TileKey) TileKey {
        return TileKey.new(self.row >> 1, self.column >> 1, self.level - 1);
    }
    pub fn eq(self: TileKey, other: TileKey) bool {
        return self.row == other.row and self.column == other.column and self.level == other.level;
    }

    pub fn mortoncode(self: *TileKey) u32 {
        if (self.m_mortonCode == undefined) {
            const column = self.column;
            const row = self.row;
            const result = powerOfTwo[self.level << 1];
            for (0..self.level) |i| {
                if (column & 0x1) {
                    result += powerOfTwo[2 * i];
                }
                if (row & 0x1) {
                    result += powerOfTwo[2 * i + 1];
                }
                column = column >> 1;
                row = row >> 1;
            }
            self.m_mortonCode = result;
        }
        return self.m_mortonCode;
    }
    pub fn from_mortoncode(quadKey64: u32) TileKey {
        var level = 0;
        var row = 0;
        var column = 0;
        var quadKey = quadKey64;
        while (quadKey > 1) {
            const mask = 1 << level;

            if (quadKey & 0x1) {
                column |= mask;
            }
            if (quadKey & 0x2) {
                row |= mask;
            }

            level = level + 1;
            quadKey = (quadKey - (quadKey & 0x3)) / 4;
        }
        const result = TileKey.new(row, column, level);
        result.m_mortonCode = quadKey64;
        return result;
    }
    pub fn rows_at_level(level: u32) u32 {
        return math.pow(u32, 2, level);
    }
    pub fn columns_at_level(level: u32) u32 {
        return math.pow(u32, 2, level);
    }
    pub fn row_count(self: TileKey) u32 {
        return rows_at_level(self.level);
    }
    pub fn column_count(self: TileKey) u32 {
        return columns_at_level(self.level);
    }
};

const powerOfTwo = [52]u8{
    0x1,
    0x2,
    0x4,
    0x8,
    0x10,
    0x20,
    0x40,
    0x80,
    0x100,
    0x200,
    0x400,
    0x800,
    0x1000,
    0x2000,
    0x4000,
    0x8000,
    0x10000,
    0x20000,
    0x40000,
    0x80000,
    0x100000,
    0x200000,
    0x400000,
    0x800000,
    0x1000000,
    0x2000000,
    0x4000000,
    0x8000000,
    0x10000000,
    0x20000000,
    0x40000000,
    0x80000000,
    0x100000000,
    0x200000000,
    0x400000000,
    0x800000000,
    0x1000000000,
    0x2000000000,
    0x4000000000,
    0x8000000000,
    0x10000000000,
    0x20000000000,
    0x40000000000,
    0x80000000000,
    0x100000000000,
    0x200000000000,
    0x400000000000,
    0x800000000000,
    0x1000000000000,
    0x2000000000000,
    0x4000000000000,
    0x8000000000000,
    0x10000000000000, // Math.pow(2, 52), highest bit that can be set correctly.
};
