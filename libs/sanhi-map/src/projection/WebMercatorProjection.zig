const std = @import("std");
const math = @import("../math.zig");
const Vector3 = math.Vector3;
const Mat4 = math.Matrix4;
const Mat3 = math.Matrix3;
const Cartographic = @import("../Cartographic.zig").Cartographic;
const earth = @import("./Earth.zig");
const ProjectionImpl = @import("./Projection.zig").Projection;
const ProjectionType = @import("./ProjectionType.zig").ProjectionType;
const MercatorProjection = @import("./MercatorProjection.zig");
const mercatorProjection = MercatorProjection.mercatorProjection;
const AABB = @import("../AABB.zig").AABB;
const OBB = @import("../OBB.zig").OBB;
const GeoBox = @import("../GeoBox.zig").GeoBox;

unitScale: f64,
const WebMercatorProjection = @This();
const Self = WebMercatorProjection;

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
    const sy = math.sin(MercatorProjection.latitudeClamp(geoPoint.lat));
    const y = (0.5 - math.log(f64, math.eps_f64, (1 + sy) / (1 - sy)) / (4 * stdmath.pi)) * self.unitScale;
    const z = geoPoint.height;
    return Vector3.new(x, y, z);
}
pub fn unproject(self: *const Self, worldPoint: *const Vector3) Cartographic {
    const x = worldPoint.x() / self.unitScale - 0.5;
    const y = 0.5 - worldPoint.y() / self.unitScale;
    const lon = stdmath.tau * x;
    //todo may bug
    const lat = stdmath.pi - (stdmath.tau * math.atan(math.exp(-y * 2 * stdmath.pi))) / stdmath.pi;
    return Cartographic.new(lon, lat, worldPoint.z());
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
    var r = self.projectBox(geoBox, ResultBoxType);
    if (ResultBoxType == AABB) {
        const maxY = r.max.y;
        r.max.setY(self.unitScale - r.min.y());
        r.min.setY(self.unitScale - maxY);
        return r;
    } else if (ResultBoxType == OBB) {
        var slice = [1]f64{0} ** 9;
        //x axis
        slice[0] = 1;
        slice[1] = 0;
        slice[2] = 0;
        //y axis
        slice[3] = 0;
        slice[4] = -1;
        slice[5] = 0;
        //z axis
        slice[6] = 0;
        slice[7] = 0;
        slice[8] = -1;
        r.halfAxes = Mat3.fromColumnMajorArray(&slice);
        r.center.setY(self.unitScale - r.center.y());
        return r;
    } else {
        @compileError("invalid bounding box");
    }
}
pub fn unprojectBox(self: *const Self, worldBox: *const AABB) GeoBox {
    const minGeo = self.unproject(&worldBox.min);
    const maxGeo = self.unproject(&worldBox.max);
    return GeoBox.new(
        Cartographic.new(minGeo.lon, maxGeo.lat, minGeo.height),
        Cartographic.new(maxGeo.lon, minGeo.lat, maxGeo.height),
    );
}
//same to MercatorProjection
pub fn unprojectAltitude(_: *const Self, worldPoint: *const Vector3) f64 {
    return worldPoint.z();
}
//same to MercatorProjection
pub fn getScaleFactor(self: *const Self, worldPoint: *const Vector3) f64 {
    return math.cosh(2 * stdmath.pi * (worldPoint.y() / self.unitScale - 0.5));
}
pub fn surfaceNormal(_: *const Self) Vector3 {
    return Vector3.new(0.0, 0.0, -1.0);
}
//same to MercatorProjection
pub fn groundDistance(_: *const Self, worldPoint: *const Vector3) f64 {
    return worldPoint.z();
}
//same to MercatorProjection
pub fn scalePointToSurface(_: *const Self, worldPoint: *const Vector3) Vector3 {
    return Vector3.new(worldPoint.x(), worldPoint.y(), 0);
}
//same to MercatorProjection
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
pub const webMercatorProjection = ProjectionImpl(WebMercatorProjection).new(earth.EQUATORIAL_RADIUS);
test "WebMercatorProjection" {}
