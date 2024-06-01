const ArrayList = @import("std").ArrayList;
const TileKey = @import("./tile_key.zig").TileKey;
const GeoBox = @import("../coord//geo_box.zig").GeoBox;
const GeoCoordinates = @import("../coord//geo_coordinates.zig").GeoCoordinates;
const tilekeyUtils = @import("./tile_key_utils.zig");
const FlatTileBoundingBoxGenerator = @import("./box_generator.zig").FlatTileBoundingBoxGenerator;
pub fn GenericVector(comptime SubdivisionScheme: type, comptime Projection: type) type {
    return extern struct {
        const Self = @This();
        subdivisionScheme: SubdivisionScheme,
        projection: Projection,
        bounding_box_generator: FlatTileBoundingBoxGenerator(Self) = undefined,
        pub fn new(subdivisionScheme: SubdivisionScheme, projection: Projection) Self {
            const self = .{ .subdivisionScheme = subdivisionScheme, .projection = projection };
            self.bounding_box_generator = FlatTileBoundingBoxGenerator(Self).new(&self);
            return self;
        }
        pub fn get_sub_tile_keys(self: Self, tile_key: TileKey) TileKey {
            return self.subdivisionScheme.sub_tiles(tile_key);
        }
        pub fn get_tile_key(self: Self, geopoint: GeoCoordinates) ?TileKey {
            return tilekeyUtils.geocoordinates_to_tilekey(Self, geopoint, self.level);
        }
        pub fn get_tile_keys(_: Self, geobox: GeoBox, level: f64) ArrayList(TileKey) {
            return tilekeyUtils.georectangle_to_tilekeys(Self, geobox, level);
        }
        pub fn get_geo_box(self: Self, tile_key: TileKey) GeoBox {
            return self.bounding_box_generator.get_geo_box(tile_key);
        }
        pub fn get_world_box(self: Self, tile_key: TileKey) GeoBox {
            return self.bounding_box_generator.get_world_box(tile_key);
        }
    };
}
