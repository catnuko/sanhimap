const std = @import("std");
const ArrayList = std.ArrayList;
const lib = @import("lib.zig");
const Box3 = lib.Box3;
const TileKey = lib.TileKey;
const GeoBox = lib.GeoBox;
const QuadTreeSubdivisionScheme = lib.QuadTreeSubdivisionScheme;
const GeoCoordinates = lib.GeoCoordinates;
const MercatorProjection = lib.MercatorProjection;
const WebMercatorProjection = lib.WebMercatorProjection;
const Vec3 = lib.Vec3;
const TileKeyUtils = lib.TileKeyUtils;

pub const MercatorTilingScheme = TilingScheme(
    QuadTreeSubdivisionScheme,
    MercatorProjection,
);
pub const WebMercatorTilingScheme = TilingScheme(
    QuadTreeSubdivisionScheme,
    WebMercatorProjection,
);
pub fn TilingScheme(comptime SubdivisionScheme: type, comptime Projection: type) type {
    return struct {
        const This = @This();
        subdivisionScheme: SubdivisionScheme,
        projection: Projection,
        m_world_box: Box3,
        m_world_dimensions: Vec3,
        pub fn new(subdivisionScheme: SubdivisionScheme, projection: Projection) This {
            const m_world_box = projection.worldExtent(0, 0);
            const min = m_world_box.min;
            const max = m_world_box.max;
            return .{
                .subdivisionScheme = subdivisionScheme,
                .projection = projection,
                .m_world_box = m_world_box,
                .m_world_dimensions = max.sub(min),
            };
        }
        pub fn getSubTileKeys(this: This, tile_key: TileKey) []TileKey {
            const div_x = this.subdivisionScheme.getSubdivisionX(tile_key.level);
            const div_y = this.subdivisionScheme.getSubdivisionY(tile_key.level);
            return subTiles(tile_key, div_x, div_y);
        }
        pub fn getTileKey(this: This, geopoint: GeoCoordinates) ?TileKey {
            return TileKeyUtils.geocoordinates_to_tilekey(This, geopoint, this.level);
        }
        pub fn getTileKeys(_: This, geobox: GeoBox, level: f64) ArrayList(TileKey) {
            return TileKeyUtils.georectangle_to_tilekeys(This, geobox, level);
        }
        pub fn getGeoBox(this: This, tile_key: TileKey) GeoBox {
            const world_box = this.getWorldBox(tile_key);
            return this.projection.unproject_box(world_box);
        }
        pub fn getWorldBox(this: This, tile_key: TileKey) GeoBox {
            const level = tile_key.level;
            const subdivisionScheme = this.subdivisionScheme;
            const levelDimensionX = subdivisionScheme.getLevelDimensionX(level);
            const levelDimensionY = subdivisionScheme.getLevelDimensionY(level);
            const sizeX = this.m_world_dimensions.x / levelDimensionX;
            const sizeY = this.m_world_dimensions.y / levelDimensionY;
            const originX = this.m_worldBox.min.x + sizeX * tile_key.column;
            const originY = this.m_worldBox.min.y + sizeY * tile_key.row;
            return Box3.new(Vec3.new(originX, originY, this.m_world_box.min.z()), Vec3.new(originX + sizeX, originY + sizeY, this.m_world_box.z()));
        }
    };
}
fn subTiles(parent_tile_key: TileKey, size_x: u32, size_y: u32) []TileKey {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var tile_keys = ArrayList(TileKey).init(allocator);
    if (size_x == 2 and size_y == 2) {
        for (0..4) |ii| {
            const i: u32 = @intCast(ii);
            const tile_key = TileKey.new((parent_tile_key.row << 1) | (i >> 1), (parent_tile_key.column << 1) | (i & 1), parent_tile_key.level + 1);
            tile_keys.append(tile_key) catch unreachable;
        }
    } else {
        for (0..size_y) |yy| {
            for (0..size_x) |xx| {
                const y: u32 = @intCast(yy);
                const x: u32 = @intCast(xx);
                const tile_key = TileKey.new(parent_tile_key.row * size_x + y, parent_tile_key.column * size_y + x, parent_tile_key.level + 1);
                tile_keys.append(tile_key) catch unreachable;
            }
        }
    }
    return tile_keys.toOwnedSlice() catch unreachable;
}
test "Geo.TilingScheme.subTileKeys" {
    const TestSubdivisionScheme = struct {
        const This = @This();
        pub fn getSubdivisionX(_: This, _: u32) u32 {
            return 1;
        }
        pub fn getSubdivisionY(_: This, _: u32) u32 {
            return 1;
        }
        pub fn getLevelDimensionX(_: This, _: u32) u32 {
            return 1;
        }
        pub fn getLevelDimensionY(_: This, _: u32) u32 {
            return 1;
        }
    };
    const TestTilingScheme = TilingScheme(TestSubdivisionScheme, MercatorProjection);
    const test_tiline_scheme = TestTilingScheme.new(.{}, lib.mercatorProjection);
    const tile_keys = test_tiline_scheme.getSubTileKeys(TileKey.new(0, 0, 0));
    try std.testing.expectEqual(tile_keys.len, 1);
}
