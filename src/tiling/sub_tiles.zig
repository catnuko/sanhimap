const TileKey = @import("./tile_key.zig").TileKey;
const std = @import("std");
pub const SubTilesType = enum { RowColumnIterator, ZCurveIterator };
pub const SubTiles = struct {
    size_x: u32,
    size_y: u32,
    tile_key: TileKey,
    types: SubTilesType,
    x: u32 = 0,
    y: u32 = 0,
    pub fn new(parent_tile_key: TileKey, size_x: u32, size_y: u32) SubTiles {
        return .{ .size_x = size_x, .size_y = size_y, .tile_key = parent_tile_key, .types = if (size_x == 2 and size_y == 2) SubTilesType.ZCurveIterator else SubTilesType.RowColumnIterator };
    }
    pub fn next(this: *SubTiles) ?TileKey {
        switch (this.types) {
            SubTilesType.ZCurveIterator => {
                const i = this.x;
                if (i == 4) {
                    return null;
                }
                const tile_key = TileKey.new((this.tile_key.row << 1) | (i >> 1), (this.tile_key.column << 1) | (i & 1), this.tile_key.level + 1);
                this.x = this.x + 1;
                return tile_key;
            },
            SubTilesType.RowColumnIterator => {
                const x = this.x;
                const y = this.y;
                if (x >= this.size_x or y >= this.size_y) {
                    return null;
                }
                const tile_key = TileKey.new(this.tile_key.row * this.size_x + y, this.tile_key.column * this.size_y + x, this.tile_key.level + 1);
                this.x = this.x + 1;
                if (this.x == this.size_x) {
                    this.x = 0;
                    this.y = this.y + 1;
                }
                return tile_key;
            },
        }
    }
};
fn print_tile_key(tile_key: ?TileKey) void {
    if (tile_key) |v| {
        std.debug.print("row={},column={},level={}\n", .{ v.row, v.column, v.level });
    } else {
        std.debug.print("tile key is null\n", .{});
    }
}
test "tiling.sub_tiles.ZCurveIterator" {
    const parent_tile_key = TileKey.new(0, 0, 0);
    var sub_tiles = SubTiles.new(parent_tile_key, 2, 2);
    try std.testing.expectEqual(sub_tiles.types, SubTilesType.ZCurveIterator);
    const k1 = sub_tiles.next();
    try std.testing.expect(k1.?.eq(TileKey.new(0, 0, 1)));
    const k2 = sub_tiles.next();
    try std.testing.expect(k2.?.eq(TileKey.new(0, 1, 1)));
    const k3 = sub_tiles.next();
    try std.testing.expect(k3.?.eq(TileKey.new(1, 0, 1)));
    const k4 = sub_tiles.next();
    try std.testing.expect(k4.?.eq(TileKey.new(1, 1, 1)));
    const tile_key = sub_tiles.next();
    try std.testing.expectEqual(tile_key, null);
}

test "tiling.sub_tiles.RowColumnIterator" {
    const parent_tile_key = TileKey.new(0, 0, 0);
    var sub_tiles = SubTiles.new(parent_tile_key, 2, 1);
    try std.testing.expectEqual(sub_tiles.types, SubTilesType.RowColumnIterator);
    const k1 = sub_tiles.next();
    try std.testing.expect(k1.?.eq(TileKey.new(0, 0, 1)));
    const k2 = sub_tiles.next();
    try std.testing.expect(k2.?.eq(TileKey.new(0, 1, 1)));
    const tile_key = sub_tiles.next();
    try std.testing.expectEqual(tile_key, null);
}
