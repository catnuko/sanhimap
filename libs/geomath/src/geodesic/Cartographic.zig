const math = @import("math");
const Vec3 = math.Vec3d;

pub const pi = math.pi;
pub const MAX_LATITUDE = math.pi_over_two;
pub const MIN_LATITUDE = -math.pi_over_two;
pub const MAX_LONGITUDE = pi;
pub const MIN_LONGITUDE = -pi;
pub const Cartographic = struct {
    const Self = @This();
    lon: f64,
    lat: f64,
    height: f64,
    pub const new = fromRadians;
    pub fn fromRadians(lon: f64, lat: f64, height: f64) Self {
        return .{ .lon = lon, .lat = lat, .height = height };
    }
    pub fn zero() Self {
        return Self.new(
            0.0,
            0.0,
            0.0,
        );
    }
    pub fn fromDegrees(lon: f64, lat: f64, height: f64) Self {
        return Self.fromRadians(math.degreesToRadians(lon), math.degreesToRadians(lat), height);
    }
    pub fn longitudeInDegrees(self: *Self) f64 {
        return math.radiansToDegrees(self.lon);
    }
    pub fn latitudeInDegreees(self: *Self) f64 {
        return math.radiansToDegrees(self.lat);
    }
    pub fn eql(self: *const Self, other: *const Self) bool {
        // return (self.lat == other.lat and
        //     self.lon == other.lon and
        //     self.height == other.height);
        const v1 = self.toVec3();
        const v2 = other.toVec3();
        return v1.eql(&v2);
    }
    pub fn eqlApprox(self: *const Self, other: *const Self, tolerance: f64) bool {
        const v1 = self.toVec3();
        const v2 = other.toVec3();
        return v1.eqlApprox(&v2, tolerance);
    }
    pub fn copy(self: *Self, other: Self) void {
        self.lat = other.lat;
        self.lon = other.lon;
        self.height = other.height;
    }
    pub fn clone(self: *const Self) Self {
        return Self.new(self.lon, self.lat, self.height);
    }
    pub fn minLongitudeSpanTo(self: *const Self, other: Self) f64 {
        const minLongitude = @min(self.lon, other.lon);
        const maxLongitude = @max(self.lon, other.lon);
        return @min(maxLongitude - minLongitude, pi + minLongitude - maxLongitude);
    }

    pub fn fromVec3(vec3: Vec3) Self {
        return Self.new(vec3.x(), vec3.y(), vec3.z());
    }
    pub fn toVec3(self: *const Self) Vec3 {
        return Vec3.new(self.lon, self.lat, self.height);
    }
    pub fn normalize(self: *const Self) Self {
        var lng = self.lon;
        var lat = self.lat;
        if (math.isNan(lng) or math.isNan(lat)) {
            return self.clone();
        }
        if (lng < -pi or lng > pi) {
            lng = (math.mod(f64, lng + pi, math.tau) catch unreachable) - pi;
        }
        lat = math.clamp(lat, -pi, pi);
        return Self.new(lat, lng, self.height);
    }
    pub fn lerp(self: *const Self, other: *const Self, factor: f64) Self {
        var v0 = self.toVec3();
        const v1 = other.toVec3();
        v0 = v0.lerp(&v1, factor);
        const res = Cartographic.fromVec3(v0);
        return res;
    }
};

test "Cartographic.fromDegrees" {
    const testing = @import("std").testing;
    const point = Cartographic.fromDegrees(120, 30, 0);
    try testing.expectApproxEqAbs(point.lon, math.degreesToRadians(120), 0.0000000001);
    try testing.expectApproxEqAbs(point.lat, math.degreesToRadians(30), 0.0000000001);
    try testing.expectEqual(point.height, 0);
}

test "Cartographic.lerp" {
    const testing = @import("std").testing;
    var p1 = Cartographic.fromDegrees(120, 30, 0);
    const p2 = Cartographic.fromDegrees(124, 34, 0);
    const res = p1.lerp(&p2, 0.5);
    const expect = Cartographic.fromDegrees(122, 32, 0);
    try testing.expect(res.eql(&expect));
}
