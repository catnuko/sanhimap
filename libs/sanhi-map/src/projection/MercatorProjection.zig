const std = @import("std");
const math = @import("../math.zig");
const Vector3 = math.Vector3;
const Mat4 = math.Matrix4;
const Mat3 = math.Matrix3;
const Cartographic = @import("../Cartographic.zig").Cartographic;
const earth = @import("./Earth.zig");
const ProjectionImpl = @import("./Projection.zig").Projection;
const ProjectionType = @import("./ProjectionType.zig").ProjectionType;
const webMercatorProjection = @import("./WebMercatorProjection.zig").webMercatorProjection;
const AABB = @import("../AABB.zig").AABB;
const OBB = @import("../OBB.zig").OBB;
const GeoBox = @import("../GeoBox.zig").GeoBox;

pub const MAXIMUM_LATITUDE: f64 = 1.4844222297453323;
unitScale: f64,
const MercatorProjection = @This();
const Self = MercatorProjection;
pub fn new(unitScale: f64) Self {
    return .{ .unitScale = unitScale };
}
pub fn worldExtent(self: *const Self, minElevation: f64, maxElevation: f64) AABB {
    return AABB.new(
        Vector3.new(0, 0, minElevation),
        Vector3.new(self.unitScale, self.unitScale, maxElevation),
    );
}
pub fn project(self: *const Self, geoPoint: *const Cartographic) Vector3 {
    const x = ((geoPoint.lon + stdmath.pi) / stdmath.tau) * self.unitScale;
    const y = (latitudeClampProject(geoPoint.lat) * 0.5 + 0.5) *
        self.unitScale;
    const z = geoPoint.height;
    return Vector3.new(x, y, z);
}
pub fn unproject(self: *const Self, worldPoint: *const Vector3) Cartographic {
    return Cartographic.fromRadians(
        (worldPoint.x() / self.unitScale) * 2 * stdmath.pi - stdmath.pi,
        unprojectLatitude((worldPoint.y() / self.unitScale - 0.5) * 2.0),
        worldPoint.z(),
    );
}
pub fn reproject(self: *const Self, comptime P: type, sourceProjection: *const P, worldPoint: *const Vector3) Vector3 {
    if ((sourceProjection != self) and (sourceProjection == webMercatorProjection or sourceProjection == mercatorProjection)) {
        return Vector3.new(worldPoint.x(), self.unitScale - worldPoint.y(), worldPoint.z());
    } else {
        if (self == sourceProjection) {
            return worldPoint.clone();
        }
        const t = sourceProjection.unProject(worldPoint);
        return self.project(&t);
    }
}
pub fn projectBox(self: *const Self, geoBox: *const GeoBox, comptime ResultBoxType: type) ResultBoxType {
    var worldCenter = self.project(&geoBox.center());
    const worldNorth = (latitudeClampProject(geoBox.northEast().lat) * 0.5 + 0.5) * self.unitScale;
    const worldSouth = (latitudeClampProject(geoBox.southWest().lat) * 0.5 + 0.5) * self.unitScale;
    const worldYCenter = (worldNorth + worldSouth) * 0.5;
    worldCenter.setY(worldYCenter);
    const latitudeSpan = worldNorth - worldSouth;
    const longitudeSpan = (geoBox.longitudeSpan() / stdmath.tau) * self.unitScale;
    if (ResultBoxType == AABB) {
        const minx = worldCenter.x() - longitudeSpan * 0.5;
        const miny = worldCenter.y() - latitudeSpan * 0.5;
        const maxx = worldCenter.x() + longitudeSpan * 0.5;
        const maxy = worldCenter.y() + latitudeSpan * 0.5;
        const altitudeSpan = geoBox.altitudeSpan;
        var minz: f64 = 0;
        var maxz: f64 = 0;
        if (altitudeSpan != 0) {
            minz = worldCenter.z - altitudeSpan * 0.5;
            maxz = worldCenter.z + altitudeSpan * 0.5;
        } else {
            minz = 0;
            maxz = 0;
        }
        return AABB.new(
            Vector3.new(minx, miny, minz),
            Vector3.new(maxx, maxy, maxz),
        );
    } else if (ResultBoxType == OBB) {
        const center = worldCenter.clone();
        const scale = Vector3.new(
            longitudeSpan * 0.5,
            latitudeSpan * 0.5,
            @max(math.eps_f64, geoBox.altitudeSpan() * 0.5),
        );
        var halfAxes = Mat3.identity.clone();
        halfAxes.setScale(&scale);
        return OBB.new(center, halfAxes);
    } else {
        @compileError("invalid bounding box");
    }
}
pub fn unprojectBox(self: *const Self, worldBox: *const AABB) GeoBox {
    const minGeo = self.unproject(&worldBox.min);
    const maxGeo = self.unproject(&worldBox.max);
    return GeoBox.new(minGeo, maxGeo);
}
pub fn unprojectAltitude(_: *const Self, worldPoint: *const Vector3) f64 {
    return worldPoint.z();
}
pub fn getScaleFactor(self: *const Self, worldPoint: *const Vector3) f64 {
    return math.cosh(2 * stdmath.pi * (worldPoint.y() / self.unitScale - 0.5));
}
pub fn surfaceNormal(_: *const Self) Vector3 {
    return Vector3.new(0.0, 0.0, 1.0);
}
pub fn groundDistance(_: *const Self, worldPoint: *const Vector3) f64 {
    return worldPoint.z();
}
pub fn scalePointToSurface(_: *const Self, worldPoint: *const Vector3) Vector3 {
    return Vector3.new(worldPoint.x(), worldPoint.y(), 0);
}
pub fn localTangentSpace(self: *const Self, geoPoint: *const Cartographic) Mat4 {
    const position = self.project(geoPoint);
    var slice = [1]f64{0} ** 16;
    //x axis
    slice[0] = 1;
    slice[1] = 0;
    slice[2] = 0;
    slice[3] = 0;
    //y axis
    slice[4] = 0;
    slice[5] = -1;
    slice[6] = 0;
    slice[7] = 0;
    //z axis
    slice[8] = 0;
    slice[9] = 0;
    slice[10] = -1;
    slice[11] = 0;
    //point
    slice[12] = position.x();
    slice[13] = position.y();
    slice[14] = position.z();
    slice[15] = 1;
    return Mat4.fromColumnMajorArray(&slice);
}
pub fn unprojectLatitude(y: f64) f64 {
    return 2.0 * math.atan(math.exp(stdmath.pi * y)) - stdmath.pi * 0.5;
}
pub fn latitudeClamp(lat: f64) f64 {
    return math.clamp(lat, -MAXIMUM_LATITUDE, MAXIMUM_LATITUDE);
}
pub fn latitudeProject(lat: f64) f64 {
    return math.log(f64, math.e, math.tan(stdmath.pi * 0.25 + lat * 0.5)) / stdmath.pi;
}
pub fn latitudeClampProject(lat: f64) f64 {
    return latitudeProject(latitudeClamp(lat));
}
pub const mercatorProjection = ProjectionImpl(MercatorProjection).new(earth.EQUATORIAL_RADIUS);
const testing = @import("std").testing;
test "MercatorProjection.projectAndunproject" {
    var geoPoint = Cartographic.fromDegrees(13.371806, 52.504951, 100);
    var worldPoint = mercatorProjection.project(&geoPoint);
    var geoPoint2 = mercatorProjection.unproject(&worldPoint);
    try testing.expectApproxEqAbs(geoPoint.lat, geoPoint2.lat, math.epsilon10);
    try testing.expectApproxEqAbs(geoPoint.lon, geoPoint2.lon, math.epsilon10);
    try testing.expectApproxEqAbs(geoPoint.height, geoPoint2.height, math.epsilon10);

    geoPoint = Cartographic.fromDegrees(373.371806, 52.504951, 0);
    worldPoint = mercatorProjection.project(&geoPoint);
    geoPoint2 = mercatorProjection.unproject(&worldPoint);
    try testing.expectApproxEqAbs(geoPoint.lat, geoPoint2.lat, math.epsilon10);
    try testing.expectApproxEqAbs(geoPoint.lon, geoPoint2.lon, math.epsilon10);
    try testing.expectApproxEqAbs(geoPoint.height, geoPoint2.height, math.epsilon10);
}

test "MercatorProjection.projectBox" {}
