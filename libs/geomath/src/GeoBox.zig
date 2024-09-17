const math = @import("math");
const Cartographic = @import("./Cartographic.zig").Cartographic;
const MAX_LONGITUDE = @import("./Cartographic.zig").MAX_LONGITUDE;
pub const GeoBox = struct {
    southWest: Cartographic,
    northEast: Cartographic,
    pub fn new(
        southWestP: Cartographic,
        northEastP: Cartographic,
    ) GeoBox {
        var news = GeoBox{
            .southWest = southWestP,
            .northEast = northEastP,
        };
        if (news.west() > news.east()) {
            news.northEast.longitude += math.tau;
        }
        return news;
    }
    pub fn fromCenterAndExtents(center_v: Cartographic, extents: GeoBox) GeoBox {
        return GeoBox.new(
            Cartographic.fromRadians(
                center_v.longitude - extents.longitudeSpan() / 2,
                center_v.latitude - extents.latitudeSpan() / 2,
                0,
            ),
            Cartographic.fromRadians(
                center_v.longitude + extents.longitudeSpan() / 2,
                center_v.latitude + extents.latitudeSpan() / 2,
                0,
            ),
        );
    }
    pub inline fn minAltitude(self: GeoBox) f64 {
        return @min(self.southWest.altitude, self.northEast.altitude);
    }
    pub inline fn maxAltitude(self: GeoBox) f64 {
        return @max(self.southWest.altitude, self.northEast.altitude);
    }
    pub inline fn south(self: GeoBox) f64 {
        return self.southWest.latitude;
    }
    pub inline fn north(self: GeoBox) f64 {
        return self.northEast.latitude;
    }
    pub inline fn west(self: GeoBox) f64 {
        return self.southWest.longitude;
    }
    pub inline fn east(self: GeoBox) f64 {
        return self.northEast.longitude;
    }
    pub inline fn southWest(self: GeoBox) Cartographic {
        return self.southWest;
    }
    pub inline fn southEast(self: GeoBox) Cartographic {
        return Cartographic.new(
            self.east(),
            self.south(),
        );
    }
    pub inline fn northWest(self: GeoBox) Cartographic {
        return Cartographic.new(
            self.west(),
            self.north(),
        );
    }
    pub inline fn northEast(self: GeoBox) Cartographic {
        return self.northEast;
    }
    fn getAltitudeHelper(self: GeoBox) f64 {
        const min_altitude_v = self.minAltitude();
        const altitude_span_v = self.altitudeSpan();
        const a = min_altitude_v;
        const b = altitude_span_v;
        return a + b * 0.5;
    }
    pub fn center(self: GeoBox) Cartographic {
        const east_v = self.east();
        const west_v = self.west();
        const north_v = self.north();
        const south_v = self.south();
        const latitude_v = (south_v + north_v) * 0.5;
        const altitude_v = self.getAltitudeHelper();
        if (west_v <= east_v) {
            return Cartographic.fromRadians((west_v + east_v) * 0.5, latitude_v, altitude_v);
        }
        var longitude_v = (math.tau + east_v + west_v) * 0.5;

        if (longitude_v > math.tau) {
            longitude_v -= math.tau;
        }
        return Cartographic.fromRadians(longitude_v, latitude_v, altitude_v);
    }
    pub inline fn latitudeSpan(self: GeoBox) f64 {
        return self.north() - self.south();
    }
    pub inline fn altitudeSpan(self: GeoBox) f64 {
        const max_altitude_v = self.maxAltitude();
        const min_altitude_v = self.minAltitude();
        return max_altitude_v - min_altitude_v;
    }
    pub inline fn longitudeSpan(self: GeoBox) f64 {
        var width = self.east() - self.west();
        if (width < 0.0) {
            width += math.tau;
        }
        return width;
    }
    pub inline fn clone(self: GeoBox) GeoBox {
        return GeoBox.new(self.southWest, self.northEast);
    }
    pub fn contains(self: GeoBox, point: Cartographic) bool {
        const min_altitude_v = self.minAltitude();
        const max_altitude_v = self.maxAltitude();
        if (point.altitude == 0 or min_altitude_v == 0 or max_altitude_v == 0) {
            return self.containsHelper(point);
        }
        const min_altitude_h = min_altitude_v;
        const max_altitude_h = max_altitude_v;
        const point_altitude = point.altitude;
        const isFlat = min_altitude_h == max_altitude_h;
        const isSameAltitude = min_altitude_h == point_altitude;
        const isWithinAltitudeRange =
            min_altitude_h <= point_altitude and max_altitude_h > point_altitude;

        if (if (isFlat) isSameAltitude else isWithinAltitudeRange) {
            return self.containsHelper(point);
        }
        return false;
    }
    pub fn containsHelper(self: GeoBox, point: Cartographic) bool {
        if (point.latitude < self.southWest.latitude or point.latitude >= self.northEast.latitude) {
            return false;
        }
        const east_v: f64 = self.east();
        const west_v: f64 = self.west();

        var longitude = point.longitude;
        if (east_v > MAX_LONGITUDE) {
            while (longitude < west_v) {
                longitude = longitude + math.tau;
            }
        }

        if (longitude > east_v) {
            while (longitude > west_v + math.tau) {
                longitude = longitude - math.tau;
            }
        }

        return longitude >= west_v and longitude < east_v;
    }
    pub fn growToContain(self: *GeoBox, point: Cartographic) void {
        self.southWest.latitude = @min(self.southWest.latitude, point.latitude);
        self.southWest.longitude = @min(self.southWest.longitude, point.longitude);
        self.southWest.altitude = @min(self.southWest.altitude, point.altitude);
        self.northEast.latitude = @max(self.northEast.latitude, point.latitude);
        self.northEast.longitude = @max(self.northEast.longitude, point.longitude);
        self.northEast.altitude = @max(self.northEast.altitude, point.altitude);
    }
};
const GEOCOORDS_EPSILON = 0.000001;
test "Geo.GeoBox.center" {
    const std = @import("std");
    const testing = std.testing;
    const t = std.math.degreesToRadians;
    const g = GeoBox.new(Cartographic.fromDegrees(170, -10, 0), Cartographic.fromDegrees(-160, 10, 0));
    try testing.expectEqual(g.west(), t(170));
    try testing.expectEqual(g.east(), t(200));
    try testing.expectEqual(g.north(), t(10));
    try testing.expectEqual(g.south(), t(-10));
    const center = g.center();
    try testing.expectApproxEqAbs(center.longitude, t(185), GEOCOORDS_EPSILON);
    try testing.expectApproxEqAbs(center.latitude, t(0), GEOCOORDS_EPSILON);
    try testing.expectApproxEqAbs(g.longitudeSpan(), t(30), GEOCOORDS_EPSILON);
    try testing.expectApproxEqAbs(g.latitudeSpan(), t(20), GEOCOORDS_EPSILON);

    try testing.expect(g.contains(Cartographic.fromDegrees(180, 0, 0)));
    try testing.expect(g.contains(Cartographic.fromDegrees(190, 0, 0)));
    try testing.expect(g.contains(Cartographic.fromDegrees(-170, 0, 0)));
    try testing.expect(g.contains(Cartographic.fromDegrees(-530, 0, 0)));
    try testing.expect(g.contains(Cartographic.fromDegrees(540, 0, 0)));

    try testing.expect(!g.contains(Cartographic.fromDegrees(
        -159,
        0,
        0,
    )));
    try testing.expect(!g.contains(Cartographic.fromDegrees(
        201,
        0,
        0,
    )));
    try testing.expect(!g.contains(Cartographic.fromDegrees(
        561,
        0,
        0,
    )));
    try testing.expect(!g.contains(Cartographic.fromDegrees(
        -510,
        0,
        0,
    )));
}
