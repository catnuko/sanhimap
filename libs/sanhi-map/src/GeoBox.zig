const std = @import("std");
const c = @import("Cartographic.zig");
const Cartographic = c.Cartographic;
const MAX_LONGITUDE = c.MAX_LONGITUDE;
pub const GeoBox = struct {
    southWest: Cartographic,
    northEast: Cartographic,
    pub fn new(sw: Cartographic, ne: Cartographic) GeoBox {
        var news = GeoBox{ .southWest = sw, .northEast = ne };
        if (news.west() > news.east()) {
            news.northEast.lon += std.math.tau;
        }
        return news;
    }
    pub fn fromCenterAndExtents(center_v: Cartographic, extents: GeoBox) GeoBox {
        return GeoBox.new(
            Cartographic.fromRadians(center_v.lon - extents.longitudeSpan() / 2, center_v.lat - extents.latitudeSpan() / 2, 0),
            Cartographic.fromRadians(center_v.lon + extents.longitudeSpan() / 2, center_v.lat + extents.latitudeSpan() / 2, 0),
        );
    }
    pub inline fn minAltitude(self: *const GeoBox) f64 {
        return @min(self.southWest.height, self.northEast.height);
    }
    pub inline fn maxAltitude(self: *const GeoBox) f64 {
        return @max(self.southWest.height, self.northEast.height);
    }
    pub inline fn south(self: *const GeoBox) f64 {
        return self.southWest.lat;
    }
    pub inline fn north(self: *const GeoBox) f64 {
        return self.northEast.lat;
    }
    pub inline fn west(self: *const GeoBox) f64 {
        return self.southWest.lon;
    }
    pub inline fn east(self: *const GeoBox) f64 {
        return self.northEast.lon;
    }
    pub inline fn southWest(self: *const GeoBox) Cartographic {
        return self.southWest;
    }
    pub inline fn southEast(self: *const GeoBox) Cartographic {
        return Cartographic.new(
            self.east(),
            self.south(),
        );
    }
    pub inline fn northWest(self: *const GeoBox) Cartographic {
        return Cartographic.new(
            self.west(),
            self.north(),
        );
    }
    pub inline fn northEast(self: *const GeoBox) Cartographic {
        return self.northEast;
    }
    fn getAltitudeHelper(self: *const GeoBox) f64 {
        const min_altitude_v = self.minAltitude();
        const altitude_span_v = self.altitudeSpan();
        if (min_altitude_v != 0 and altitude_span_v != 0) {
            const a = min_altitude_v;
            const b = altitude_span_v;
            return a + b * 0.5;
        } else {
            return 0;
        }
    }
    pub fn center(self: *const GeoBox) Cartographic {
        const east_v = self.east();
        const west_v = self.west();
        const north_v = self.north();
        const south_v = self.south();
        const latitude_v = (south_v + north_v) * 0.5;
        const altitude_v = self.getAltitudeHelper();
        if (west_v <= east_v) {
            return Cartographic.fromRadians((west_v + east_v) * 0.5, latitude_v, altitude_v);
        }
        var longitude_v = (std.math.tau + east_v + west_v) * 0.5;

        if (longitude_v > std.math.tau) {
            longitude_v -= std.math.tau;
        }
        return Cartographic.fromRadians(longitude_v, latitude_v, altitude_v);
    }
    pub inline fn latitudeSpan(self: *const GeoBox) f64 {
        return self.north() - self.south();
    }
    pub inline fn altitudeSpan(self: *const GeoBox) f64 {
        const max_altitude_v = self.maxAltitude();
        const min_altitude_v = self.minAltitude();
        return max_altitude_v - min_altitude_v;
    }
    pub inline fn longitudeSpan(self: *const GeoBox) f64 {
        var width = self.east() - self.west();
        if (width < 0.0) {
            width += std.math.tau;
        }
        return width;
    }
    pub inline fn clone(self: *const GeoBox) GeoBox {
        return GeoBox.new(self.southWest, self.northEast);
    }
    pub fn contains(self: *const GeoBox, point: Cartographic) bool {
        const min_altitude_v = self.minAltitude();
        const max_altitude_v = self.maxAltitude();
        if (point.height == 0 or min_altitude_v == 0 or max_altitude_v == 0) {
            return self.containsHelper(point);
        }
        const min_altitude_h = min_altitude_v;
        const max_altitude_h = max_altitude_v;
        const point_altitude = point.height;
        const isFlat = min_altitude_h == max_altitude_h;
        const isSameAltitude = min_altitude_h == point_altitude;
        const isWithinAltitudeRange =
            min_altitude_h <= point_altitude and max_altitude_h > point_altitude;

        if (if (isFlat) isSameAltitude else isWithinAltitudeRange) {
            return self.containsHelper(point);
        }
        return false;
    }
    pub fn containsHelper(self: *const GeoBox, point: Cartographic) bool {
        if (point.lat < self.southWest.lat or point.lat >= self.northEast.lat) {
            return false;
        }
        const east_v: f64 = self.east();
        const west_v: f64 = self.west();

        var longitude = point.lon;
        if (east_v > MAX_LONGITUDE) {
            while (longitude < west_v) {
                longitude = longitude + std.math.tau;
            }
        }

        if (longitude > east_v) {
            while (longitude > west_v + std.math.tau) {
                longitude = longitude - std.math.tau;
            }
        }

        return longitude >= west_v and longitude < east_v;
    }
    pub fn growToContain(self: *GeoBox, point: Cartographic) void {
        self.southWest.lat = @min(self.southWest.lat, point.lat);
        self.southWest.lon = @min(self.southWest.lon, point.lon);

        if (self.southWest.height != 0 and point.height != 0) {
            self.southWest.height = @min(self.southWest.height, point.height);
        } else if (self.southWest.height != 0) {
            self.southWest.height = self.southWest.height;
        } else if (point.height != 0) {
            self.southWest.height = point.height;
        } else {
            self.southWest.height = 0;
        }

        self.northEast.lat = @max(self.northEast.lat, point.lat);
        self.northEast.lon = @max(self.northEast.lon, point.lon);
        if (self.northEast.height != 0 and point.height != 0) {
            self.northEast.height = @max(self.northEast.height, point.height);
        } else if (self.northEast.height != 0) {
            self.northEast.height = self.northEast.height;
        } else if (point.height != 0) {
            self.northEast.height = point.height;
        } else {
            self.northEast.height = 0;
        }
    }
};
const GEOCOORDS_epsilon = 0.000001;
test "GeoBox.center" {
    const testing = @import("std").testing;
    const t = std.math.degreesToRadians;
    const g = GeoBox.new(Cartographic.fromDegrees(170, -10, 0), Cartographic.fromDegrees(-160, 10, 0));
    try testing.expectEqual(g.west(), t(170));
    try testing.expectEqual(g.east(), t(200));
    try testing.expectEqual(g.north(), t(10));
    try testing.expectEqual(g.south(), t(-10));
    const center = g.center();
    try testing.expectApproxEqAbs(center.lon, t(185), GEOCOORDS_epsilon);
    try testing.expectApproxEqAbs(center.lat, t(0), GEOCOORDS_epsilon);
    try testing.expectApproxEqAbs(g.longitudeSpan(), t(30), GEOCOORDS_epsilon);
    try testing.expectApproxEqAbs(g.latitudeSpan(), t(20), GEOCOORDS_epsilon);

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
