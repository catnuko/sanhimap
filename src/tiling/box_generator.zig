const GeoBox = @import("../coord/geo_box.zig").GeoBox;
const Box3 = @import("../coord/box3.zig").Box3;
const Vec3 = @import("../math/generic_vector.zig").Vec3;
const TileKey = @import("./tile_key.zig").TileKey;
pub fn FlatTileBoundingBoxGenerator(comptime TilingScheme: type) type {
    return struct {
        const This = @This();
        m_world_box: Box3,
        m_world_dimensions: Vec3,
        m_tilngscheme: *TilingScheme,
        pub fn new(tilingscheme: *TilingScheme) FlatTileBoundingBoxGenerator {
            const box = tilingscheme.projection.world_extent(0, 0);
            const min = box.min;
            const max = box.max;
            return .{ .m_tilngscheme = tilingscheme, .m_world_box = box, .m_world_dimensions = Vec3.new(max.x - min.x, max.y - min.y, max.z - min.z) };
        }
        pub fn get_world_box(this: This, tilekey: TileKey) Box3 {
            const level = tilekey.level;
            const subdivisionScheme = this.m_tilngscheme.subdivisionScheme;
            const levelDimensionX = subdivisionScheme.get_level_dimension_x(level);
            const levelDimensionY = subdivisionScheme.get_level_dimension_y(level);
            const sizeX = this.m_world_dimensions.x / levelDimensionX;
            const sizeY = this.m_world_dimensions.y / levelDimensionY;
            const originX = this.m_worldBox.min.x + sizeX * tilekey.column;
            const originY = this.m_worldBox.min.y + sizeY * tilekey.row;
            return Box3.new(Vec3.new(originX, originY, this.m_world_box.min.z()), Vec3.new(originX + sizeX, originY + sizeY, this.m_world_box.z()));
        }
        pub fn get_geo_box(this: This, tilekey: TileKey) GeoBox {
            const world_box = this.get_world_box(tilekey);
            return this.m_tilngscheme.projection.unproject_box(world_box);
        }
    };
}
