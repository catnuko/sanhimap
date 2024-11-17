const math = @import("../math.zig");
const Cartographic = @import("../Cartographic.zig").Cartographic;
const Utils = @import("./TileKeyUtils.zig");
const GeoBox = @import("../GeoBox.zig");
pub const TileKey = struct {
    const Self = @This();
    row: u32,
    column: u32,
    level: u32,
    mortonCode: u64 = undefined,
    pub fn new(row: u32, column: u32, level: u32) Self {
        var self = Self{
            .row = row,
            .column = column,
            .level = level,
        };
        self.updateMortonCode();
        return self;
    }
    pub fn parent(self: Self) Self {
        return Self.new(self.row >> 1, self.column >> 1, self.level - 1);
    }
    pub fn eq(self: Self, other: Self) bool {
        return self.row == other.row and self.column == other.column and self.level == other.level;
    }
    pub fn updateMortonCode(self: *Self) void {
        var column = self.column;
        var row = self.row;
        var result: u64 = powerOfTwo[self.level << 1];
        for (0..self.level) |i| {
            if (column & 0x1 != 0) {
                result += powerOfTwo[2 * i];
            }
            if (row & 0x1 != 0) {
                result += powerOfTwo[2 * i + 1];
            }
            column >>= 1;
            row >>= 1;
        }
        self.mortonCode = result;
    }
    pub fn fromMortoncode(quadKey64: u64) Self {
        var level: u64 = 0;
        var row: u64 = 0;
        var column: u64 = 0;
        var quadKey: u64 = quadKey64;
        while (quadKey > 1) {
            const mask: u64 = math.pow(u64, 2, level);
            if (quadKey & 0x1 != 0) {
                column |= mask;
            }
            if (quadKey & 0x2 != 0) {
                row |= mask;
            }
            level += 1;
            quadKey = (quadKey - (quadKey & 0x3)) / 4;
        }
        var result = Self.new(@intCast(row), @intCast(column), @intCast(level));
        result.mortonCode = quadKey64;
        return result;
    }
    pub fn rowsAtLevel(level: u32) u32 {
        return math.pow(u32, 2, level);
    }
    pub fn columnsAtLevel(level: u32) u32 {
        return math.pow(u32, 2, level);
    }
    pub fn rowCount(self: Self) u32 {
        return rowsAtLevel(self.level);
    }
    pub fn columnCount(self: Self) u32 {
        return columnsAtLevel(self.level);
    }
    pub fn getKeyForTileKeyAndOffset(self: *const Self, offset: u64, bitshift: u8) u64 {
        const shiftedOffset = getShiftedOffset(offset, bitshift);
        return self.mortonCode + shiftedOffset;
    }
    pub fn fromCartographic(comptime TilingScheme: type, tilingscheme: TilingScheme, cartograpic: *const Cartographic, level: usize) Self {
        return Utils.geoCoordinatesToTileKey(TilingScheme, tilingscheme, cartograpic, level);
    }
    pub fn fromCartesian(comptime TilingScheme: type, tilingscheme: TilingScheme, cartesian: *const math.Vector3, level: usize) Self {
        return Utils.worldCoordinatesToTileKey(TilingScheme, tilingscheme, cartesian, level);
    }
    pub fn fromGeoRectangle(comptime TilingScheme: type, tilingscheme: TilingScheme, geoBox: *const GeoBox, level: usize) []Self {
        return Utils.geoCoordinatesToTileKey(TilingScheme, tilingscheme, geoBox, level);
    }
};
const powerOfTwo = [53]u64{
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
    0x10000000000000,
};
fn getShiftedOffset(offset: u64, offsetBits: u8) u64 {
    var result: u64 = 0;
    const totalOffsetsToStore = powerOfTwo[offsetBits];
    var offsetx = offset + totalOffsetsToStore / 2;
    while (offsetx < 0) {
        offsetx = offsetx + totalOffsetsToStore;
    }
    while (offsetx >= totalOffsetsToStore) {
        offsetx = offsetx - totalOffsetsToStore;
    }
    var i: u8 = 0;
    while (i < offsetBits and offsetx > 0) {
        if (offsetx & 0x1 == 1) {
            result += powerOfTwo[53 - offsetBits + i];
        }
        offsetx = offsetx >> 1;
        i = i + 1;
    }
    return offsetx;
}

test "TileKey.fromMortonCode" {
    const testing = @import("std").testing;
    const mortonCode: u64 = 377894432;
    const tileKey = TileKey.fromMortoncode(mortonCode);
    try testing.expect(tileKey.mortonCode == mortonCode);
    const tileKey2 = TileKey.new(tileKey.row, tileKey.column, tileKey.level);
    try testing.expect(tileKey2.mortonCode == mortonCode);
}
