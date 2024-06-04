const lib = @import("lib.zig");
const Tile = @This();
const TileKey = lib.TileKey;
const GeoBox = lib.GeoBox;

geoBox: GeoBox,
tileKey: TileKey,

pub fn new(tileKey: TileKey) Tile {
    return .{
        .tileKey = tileKey,
    };
}
