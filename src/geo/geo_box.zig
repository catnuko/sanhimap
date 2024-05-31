const lngLatAlt = @import("lng_lat_alt.zig").LngLatAlt;
pub const GeoBox = struct {
    southWest: lngLatAlt,
    northEast: lngLatAlt,
};
