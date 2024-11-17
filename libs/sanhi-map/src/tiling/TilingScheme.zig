const math = @import("../math.zig");
const std = @import("std");
const shm = @import("../lib.zig");
const AABB = shm.AABB;
const GeoBox = shm.GeoBox;
const Cartographic = shm.Cartographic;
const TileKey = shm.tiling.TileKey;
const ArrayList = std.ArrayList;
const Vector3 = math.Vector3;
const TileKeyUtils = shm.tiling.TileKeyUtils;
const SubdivisionScheme = shm.tiling.SubdivisionScheme;
const proj = shm.projection;
// const MercatorProjection = @import("../projection/MercatorProjection.zig");
// const WebMercatorProjection = @import("../projection/WebMercatorProjection.zig");

pub fn TilingScheme(comptime P: type) type {
    return struct {
        const Self = @This();
        pub const Projection = proj.Projection(P);
        subdivisionScheme: SubdivisionScheme,
        projection: Projection,
        m_world_box: AABB,
        m_world_dimensions: Vector3,
        pub fn new(subdivisionScheme: SubdivisionScheme, projection: Projection) Self {
            const m_world_box = projection.worldExtent(0.0, 0.0);
            const min = m_world_box.min;
            const max = m_world_box.max;
            return .{
                .subdivisionScheme = subdivisionScheme,
                .projection = projection,
                .m_world_box = m_world_box,
                .m_world_dimensions = max.subtract(&min),
            };
        }
        pub fn getSubTileKeys(this: Self, tile_key: *const TileKey) []TileKey {
            const div_x = this.subdivisionScheme.getSubdivisionX(tile_key.level);
            const div_y = this.subdivisionScheme.getSubdivisionY(tile_key.level);
            return subTiles(tile_key, div_x, div_y);
        }
        pub fn getTileKey(this: Self, geopoint: Cartographic) ?TileKey {
            return TileKeyUtils.geocoordinates_to_tilekey(Self, geopoint, this.level);
        }
        pub fn getTileKeys(_: Self, geobox: GeoBox, level: f64) ArrayList(TileKey) {
            return TileKeyUtils.georectangle_to_tilekeys(Self, geobox, level);
        }
        pub fn getGeoBox(this: Self, tile_key: *const TileKey) GeoBox {
            const world_box = this.getWorldBox(tile_key);
            return this.projection.unprojectBox(world_box);
        }
        pub fn getWorldBox(this: Self, tile_key: *const TileKey) GeoBox {
            const level = tile_key.level;
            const subdivisionScheme = this.subdivisionScheme;
            const levelDimensionX = subdivisionScheme.getLevelDimensionX(level);
            const levelDimensionY = subdivisionScheme.getLevelDimensionY(level);
            const sizeX = this.m_world_dimensions.x / levelDimensionX;
            const sizeY = this.m_world_dimensions.y / levelDimensionY;
            const originX = this.m_worldBox.min.x + sizeX * tile_key.column;
            const originY = this.m_worldBox.min.y + sizeY * tile_key.row;
            return AABB.new(Vector3.new(originX, originY, this.m_world_box.min.z()), Vector3.new(originX + sizeX, originY + sizeY, this.m_world_box.z()));
        }
    };
}
pub const mercatorTilingScheme = TilingScheme(proj.MercatorProjection).new(
    shm.tiling.quadTreeSubdivisionScheme,
    proj.MercatorProjection.mercatorProjection,
);

pub const webMercatorTilingScheme = TilingScheme(proj.WebMercatorProjection).new(
    shm.tiling.quadTreeSubdivisionScheme,
    proj.WebMercatorProjection.webMercatorProjection,
);

fn subTiles(parent_tile_key: *const TileKey, size_x: u32, size_y: u32) []TileKey {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    if (size_x == 2 and size_y == 2) {
        var tile_keys = ArrayList(TileKey).initCapacity(allocator, 4) catch unreachable;
        for (0..4) |ii| {
            const i: u32 = @intCast(ii);
            const tile_key = TileKey.new((parent_tile_key.row << 1) | (i >> 1), (parent_tile_key.column << 1) | (i & 1), parent_tile_key.level + 1);
            tile_keys.appendAssumeCapacity(tile_key);
        }
        return tile_keys.toOwnedSlice() catch unreachable;
    } else {
        var tile_keys = ArrayList(TileKey).initCapacity(allocator, size_y) catch unreachable;
        for (0..size_y) |yy| {
            for (0..size_x) |xx| {
                const y: u32 = @intCast(yy);
                const x: u32 = @intCast(xx);
                const tile_key = TileKey.new(parent_tile_key.row * size_x + y, parent_tile_key.column * size_y + x, parent_tile_key.level + 1);
                tile_keys.appendAssumeCapacity(tile_key);
            }
        }
        return tile_keys.toOwnedSlice() catch unreachable;
    }
}
test "TilingScheme" {
    const TestSubdivisionScheme = struct {
        pub fn getSubdivisionX(_: u32) u32 {
            return 1;
        }
        pub fn getSubdivisionY(_: u32) u32 {
            return 1;
        }
        pub fn getLevelDimensionX(_: u32) u32 {
            return 1;
        }
        pub fn getLevelDimensionY(_: u32) u32 {
            return 1;
        }
        pub fn subdivisionSchemeI() SubdivisionScheme {
            return .{ .vtable = &.{
                .getSubdivisionX = getSubdivisionX,
                .getSubdivisionY = getSubdivisionY,
                .getLevelDimensionX = getLevelDimensionX,
                .getLevelDimensionY = getLevelDimensionY,
            } };
        }
    };
    const testTilingScheme = TilingScheme(proj.MercatorProjection).new(
        TestSubdivisionScheme.subdivisionSchemeI(),
        proj.MercatorProjection.mercatorProjection,
    );
    const tile_keys = testTilingScheme.getSubTileKeys(&TileKey.new(0, 0, 0));
    try std.testing.expectEqual(tile_keys.len, 1);
}
