const lib = @import("lib.zig");
const Vec3 = lib.math.Vec3;
pub const GeoBoxCorner = struct {
    southWest: Vec3,
    southEast: Vec3,
    northWest: Vec3,
    northEast: Vec3,
    pub fn new(
        southWest: Vec3,
        southEast: Vec3,
        northWest: Vec3,
        northEast: Vec3,
    ) GeoBoxCorner {
        return .{
            .southWest = southWest,
            .southEast = southEast,
            .northWest = northWest,
            .northEast = northEast,
        };
    }
    pub fn fromBox(geobox: lib.GeoBox, projection: lib.Projection) GeoBoxCorner {
        const southWest = projection.projectPoint(geobox.southWest());
        const southEast = projection.projectPoint(geobox.southEast());
        const northWest = projection.projectPoint(geobox.northWest());
        const northEast = projection.projectPoint(geobox.northEast());
        return GeoBoxCorner.new(southWest, southEast, northWest, northEast);
    }
};
