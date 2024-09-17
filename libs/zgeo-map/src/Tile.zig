const lib = @import("lib.zig");
const TileKey = lib.TileKey;
const GeoBox = lib.GeoBox;

pub const Tile = struct {
    const Self = @This();
    geoBox: GeoBox,
    tileKey: TileKey,
    dataSource: *lib.DataSource,
    forceHasGeometry: bool = false,
    pub fn new(dataSource: *lib.DataSource, tileKey: TileKey) Tile {
        return .{
            .tileKey = tileKey,
            .dataSource = dataSource,
        };
    }
};
