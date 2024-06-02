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
const Vec3 = lib.math.Vec3;
const tile_key_utils = lib.tile_key_utils;

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
            const m_world_box = projection.world_extent(0, 0);
            const min = m_world_box.min;
            const max = m_world_box.max;
            return .{
                .subdivisionScheme = subdivisionScheme,
                .projection = projection,
                .m_world_box = m_world_box,
                .m_world_dimensions = max.sub(min),
            };
        }
        pub fn get_sub_tile_keys(this: This, tile_key: TileKey) ArrayList(TileKey) {
            const div_x = this.subdivisionScheme.get_subdivision_x(tile_key.level);
            const div_y = this.subdivisionScheme.get_subdivision_y(tile_key.level);
            return sub_tiles(tile_key, div_x, div_y);
        }
        pub fn get_tile_key(this: This, geopoint: GeoCoordinates) ?TileKey {
            return tile_key_utils.geocoordinates_to_tilekey(This, geopoint, this.level);
        }
        pub fn get_tile_keys(_: This, geobox: GeoBox, level: f64) ArrayList(TileKey) {
            return tile_key_utils.georectangle_to_tilekeys(This, geobox, level);
        }
        pub fn get_geo_box(this: This, tile_key: TileKey) GeoBox {
            const world_box = this.get_world_box(tile_key);
            return this.projection.unproject_box(world_box);
        }
        pub fn get_world_box(this: This, tile_key: TileKey) GeoBox {
            const level = tile_key.level;
            const subdivisionScheme = this.subdivisionScheme;
            const levelDimensionX = subdivisionScheme.get_level_dimension_x(level);
            const levelDimensionY = subdivisionScheme.get_level_dimension_y(level);
            const sizeX = this.m_world_dimensions.x / levelDimensionX;
            const sizeY = this.m_world_dimensions.y / levelDimensionY;
            const originX = this.m_worldBox.min.x + sizeX * tile_key.column;
            const originY = this.m_worldBox.min.y + sizeY * tile_key.row;
            return Box3.new(Vec3.new(originX, originY, this.m_world_box.min.z()), Vec3.new(originX + sizeX, originY + sizeY, this.m_world_box.z()));
        }
    };
}
fn sub_tiles(parent_tile_key: TileKey, size_x: u32, size_y: u32) ArrayList(TileKey) {
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
    return tile_keys;
}
test "tilings.tiling_scheme.sub_tile_keys" {
    // const TestSubdivisionScheme = struct {
    //     const This = @This();
    //     pub fn get_subdivision_x(_: This, _: u32) u32 {
    //         return 1;
    //     }
    //     pub fn get_subdivision_y(_: This, _: u32) u32 {
    //         return 1;
    //     }
    //     pub fn get_level_dimension_x(_: This, _: u32) u32 {
    //         return 1;
    //     }
    //     pub fn get_level_dimension_y(_: This, _: u32) u32 {
    //         return 1;
    //     }
    // };
    // const TestTilingScheme = TilingScheme(TestSubdivisionScheme, MercatorProjection);
    // const test_tiline_scheme = TestTilingScheme.new(.{}, lib.mercator_projection);
    // const tile_keys = test_tiline_scheme.get_sub_tile_keys(TileKey.new(0, 0, 0));
    // try std.testing.expectEqual(tile_keys.items.len, 1);
}
