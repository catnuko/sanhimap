const std = @import("std");
const print = std.debug.print;
const testing = std.testing;
const coord = @import("./GeoCoordinates.zig");
const GeoCoordinates = coord.GeoCoordinates;
const MAX_LONGITUDE = coord.MAX_LONGITUDE;
pub const GeoBox = struct {
    southWest: GeoCoordinates,
    northEast: GeoCoordinates,
    pub fn new(
        southWestP: GeoCoordinates,
        northEastP: GeoCoordinates,
    ) GeoBox {
        var news = GeoBox{
            .southWest = southWestP,
            .northEast = northEastP,
        };
        if (news.west() > news.east()) {
            news.northEast.longitude += std.math.tau;
        }
        return news;
    }
    pub fn fromCenterAndExtents(center_v: GeoCoordinates, extents: GeoBox) GeoBox {
        return GeoBox.new(
            GeoCoordinates.fromRadians(
                center_v.longitude - extents.longitudeSpan() / 2,
                center_v.latitude - extents.latitudeSpan() / 2,
            ),
            GeoCoordinates.fromRadians(
                center_v.longitude + extents.longitudeSpan() / 2,
                center_v.latitude + extents.latitudeSpan() / 2,
            ),
        );
    }
    pub inline fn minAltitude(self: GeoBox) ?f64 {
        if (self.southWest.altitude == null or self.northEast.altitude == null) {
            return null;
        }
        return @min(self.southWest.altitude.?, self.northEast.altitude.?);
    }
    pub inline fn maxAltitude(self: GeoBox) ?f64 {
        if (self.southWest.altitude == null or self.northEast.altitude == null) {
            return null;
        }
        return @max(self.southWest.altitude.?, self.northEast.altitude.?);
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
    pub inline fn southWest(self: GeoBox) GeoCoordinates {
        return self.southWest;
    }
    pub inline fn southEast(self: GeoBox) GeoCoordinates {
        return GeoCoordinates.new(
            self.east(),
            self.south(),
        );
    }
    pub inline fn northWest(self: GeoBox) GeoCoordinates {
        return GeoCoordinates.new(
            self.west(),
            self.north(),
        );
    }
    pub inline fn northEast(self: GeoBox) GeoCoordinates {
        return self.northEast;
    }
    fn getAltitudeHelper(self: GeoBox) ?f64 {
        const min_altitude_v = self.minAltitude();
        const altitude_span_v = self.altitudeSpan();
        if (min_altitude_v != null and altitude_span_v != null) {
            const a = min_altitude_v.?;
            const b = altitude_span_v.?;
            return a + b * 0.5;
        } else {
            return null;
        }
    }
    pub fn center(self: GeoBox) GeoCoordinates {
        const east_v = self.east();
        const west_v = self.west();
        const north_v = self.north();
        const south_v = self.south();
        const latitude_v = (south_v + north_v) * 0.5;
        const altitude_v = self.getAltitudeHelper();
        if (west_v <= east_v) {
            return GeoCoordinates.fromRadians((west_v + east_v) * 0.5, latitude_v, altitude_v);
        }
        var longitude_v = (std.math.tau + east_v + west_v) * 0.5;

        if (longitude_v > std.math.tau) {
            longitude_v -= std.math.tau;
        }
        return GeoCoordinates.fromRadians(longitude_v, latitude_v, altitude_v);
    }
    pub inline fn latitudeSpan(self: GeoBox) f64 {
        return self.north() - self.south();
    }
    pub inline fn altitudeSpan(self: GeoBox) ?f64 {
        const max_altitude_v = self.maxAltitude();
        const min_altitude_v = self.minAltitude();
        if (max_altitude_v == null or min_altitude_v == null) {
            return null;
        }
        return max_altitude_v.? - min_altitude_v.?;
    }
    pub inline fn longitudeSpan(self: GeoBox) f64 {
        var width = self.east() - self.west();
        if (width < 0.0) {
            width += std.math.tau;
        }
        return width;
    }
    pub inline fn clone(self: GeoBox) GeoBox {
        return GeoBox.new(self.southWest, self.northEast);
    }
    pub fn contains(self: GeoBox, point: GeoCoordinates) bool {
        const min_altitude_v = self.minAltitude();
        const max_altitude_v = self.maxAltitude();
        if (point.altitude == null or min_altitude_v == null or max_altitude_v == null) {
            return self.containsHelper(point);
        }
        const min_altitude_h = min_altitude_v.?;
        const max_altitude_h = max_altitude_v.?;
        const point_altitude = point.altitude.?;
        const isFlat = min_altitude_h == max_altitude_h;
        const isSameAltitude = min_altitude_h == point_altitude;
        const isWithinAltitudeRange =
            min_altitude_h <= point_altitude and max_altitude_h > point_altitude;

        if (if (isFlat) isSameAltitude else isWithinAltitudeRange) {
            return self.containsHelper(point);
        }
        return false;
    }
    pub fn containsHelper(self: GeoBox, point: GeoCoordinates) bool {
        if (point.latitude < self.southWest.latitude or point.latitude >= self.northEast.latitude) {
            return false;
        }
        const east_v: f64 = self.east();
        const west_v: f64 = self.west();

        var longitude = point.longitude;
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
    pub fn growToContain(self: *GeoBox, point: GeoCoordinates) void {
        self.southWest.latitude = @min(self.southWest.latitude, point.latitude);
        self.southWest.longitude = @min(self.southWest.longitude, point.longitude);
        self.southWest.altitude = {
            if (self.southWest.altitude != null and point.altitude != null) {
                @min(self.southWest.altitude, point.altitude);
            } else if (self.southWest.altitude != null) {
                self.southWest.altitude;
            } else if (point.altitude != null) {
                point.altitude;
            } else {
                null;
            }
        };
        self.northEast.latitude = @max(self.northEast.latitude, point.latitude);
        self.northEast.longitude = @max(self.northEast.longitude, point.longitude);
        self.northEast.altitude = {
            if (self.northEast.altitude != null and point.altitude != null) {
                @max(self.northEast.altitude, point.altitude);
            } else if (self.northEast.altitude != null) {
                self.northEast.altitude;
            } else if (point.altitude != null) {
                point.altitude;
            } else {
                null;
            }
        };
    }
};
const GEOCOORDS_EPSILON = 0.000001;
test "Geo.GeoBox.center" {
    const t = std.math.degreesToRadians;
    const g = GeoBox.new(GeoCoordinates.fromDegrees(170, -10, null), GeoCoordinates.fromDegrees(-160, 10, null));
    try testing.expectEqual(g.west(), t(170));
    try testing.expectEqual(g.east(), t(200));
    try testing.expectEqual(g.north(), t(10));
    try testing.expectEqual(g.south(), t(-10));
    const center = g.center();
    try testing.expectApproxEqAbs(center.longitude, t(185), GEOCOORDS_EPSILON);
    try testing.expectApproxEqAbs(center.latitude, t(0), GEOCOORDS_EPSILON);
    try testing.expectApproxEqAbs(g.longitudeSpan(), t(30), GEOCOORDS_EPSILON);
    try testing.expectApproxEqAbs(g.latitudeSpan(), t(20), GEOCOORDS_EPSILON);

    try testing.expect(g.contains(GeoCoordinates.fromDegrees(180, 0, null)));
    try testing.expect(g.contains(GeoCoordinates.fromDegrees(190, 0, null)));
    try testing.expect(g.contains(GeoCoordinates.fromDegrees(-170, 0, null)));
    try testing.expect(g.contains(GeoCoordinates.fromDegrees(-530, 0, null)));
    try testing.expect(g.contains(GeoCoordinates.fromDegrees(540, 0, null)));

    try testing.expect(!g.contains(GeoCoordinates.fromDegrees(
        -159,
        0,
        null,
    )));
    try testing.expect(!g.contains(GeoCoordinates.fromDegrees(
        201,
        0,
        null,
    )));
    try testing.expect(!g.contains(GeoCoordinates.fromDegrees(
        561,
        0,
        null,
    )));
    try testing.expect(!g.contains(GeoCoordinates.fromDegrees(
        -510,
        0,
        null,
    )));
}
