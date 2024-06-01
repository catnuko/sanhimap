const ArrayList = @import("std").ArrayList;
const TileKey = @import("./tile_key.zig").TileKey;
const GeoBox = @import("../coord//geo_box.zig").GeoBox;
const GeoCoordinates = @import("../coord//geo_coordinates.zig").GeoCoordinates;
const tilekeyUtils = @import("./tile_key_utils.zig");
const FlatTileBoundingBoxGenerator = @import("./box_generator.zig").FlatTileBoundingBoxGenerator;
pub fn GenericVector(comptime SubdivisionScheme: type, comptime Projection: type) type {
    return extern struct {
        const This = @This();
        subdivisionScheme: SubdivisionScheme,
        projection: Projection,
        bounding_box_generator: FlatTileBoundingBoxGenerator(This) = undefined,
        pub fn new(subdivisionScheme: SubdivisionScheme, projection: Projection) This {
            const this = .{ .subdivisionScheme = subdivisionScheme, .projection = projection };
            this.bounding_box_generator = FlatTileBoundingBoxGenerator(This).new(&this);
            return this;
        }
        pub fn get_sub_tile_keys(this: This, tile_key: TileKey) TileKey {
            const div_x = this.m_subdivisionScheme.get_subdivision_x(tile_key.level);
            const div_y = this.m_subdivisionScheme.get_subdivision_y(tile_key.level);
        }
        pub fn get_tile_key(this: This, geopoint: GeoCoordinates) ?TileKey {
            return tilekeyUtils.geocoordinates_to_tilekey(This, geopoint, this.level);
        }
        pub fn get_tile_keys(_: This, geobox: GeoBox, level: f64) ArrayList(TileKey) {
            return tilekeyUtils.georectangle_to_tilekeys(This, geobox, level);
        }
        pub fn get_geo_box(this: This, tile_key: TileKey) GeoBox {
            return this.bounding_box_generator.get_geo_box(tile_key);
        }
        pub fn get_world_box(this: This, tile_key: TileKey) GeoBox {
            return this.bounding_box_generator.get_world_box(tile_key);
        }
    };
}
