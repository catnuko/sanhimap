const std = @import("std");
const math = @import("math");
const Vec3 = math.Vec3d;
const Mat4 = math.Mat4x4d;
const Mat3 = math.Mat3x3d;
const Cartographic = @import("../Cartographic.zig").Cartographic;
const earth = @import("./Earth.zig");
const ProjectionImpl = @import("./Projection.zig").Projection;
const ProjectionType = @import("./ProjectionType.zig").ProjectionType;
const webMercatorProjection = @import("./WebMercatorProjection.zig").webMercatorProjection;
const mercatorProjection = @import("./MercatorProjection.zig").mercatorProjection;
const AABB = @import("../AABB.zig").AABB;
const OBB = @import("../OBB.zig").OBB;
const GeoBox = @import("../GeoBox.zig").GeoBox;
/// convert geo coordinate to world point
pub fn innerProject(geoPoint: *const Cartographic, unitScale: f64) Vec3 {
    const radius = unitScale + geoPoint.height;
    const latitude = geoPoint.lat;
    const longitude = geoPoint.lon;
    const cosLatitude = math.cos(latitude);
    return Vec3.new(
        radius * cosLatitude * math.cos(longitude),
        radius * cosLatitude * math.sin(longitude),
        radius * math.sin(latitude),
    );
}
const SphereProjection = @This();
const Self = SphereProjection;

unitScale: f64,
projectionType: ProjectionType = ProjectionType.Spherical,

pub fn new(unitScale: f64) Self {
    return .{ .unitScale = unitScale };
}
pub fn getType(self: *const Self) ProjectionType {
    return self.projectionType;
}
pub fn worldExtent(self: *const Self, _: f64, max_elevation: f64) AABB {
    const radius = self.unitScale + max_elevation;
    const min = Vec3.new(-radius, -radius, -radius);
    const max = Vec3.new(radius, radius, radius);
    return AABB.new(min, max);
}
pub fn project(self: *const Self, geoPoint: *const Cartographic) Vec3 {
    return innerProject(geoPoint, self.unitScale);
}
pub fn unproject(self: *const Self, worldPoint: *const Vec3) Cartographic {
    const parallelRadiusSq = worldPoint.x() * worldPoint.x() + worldPoint.y() * worldPoint.y();
    const parallelRadius = math.sqrt(parallelRadiusSq);
    const v = worldPoint.z() / parallelRadius;

    if (math.isNan(v)) {
        return Cartographic.new(0, 0, -self.unitScale);
    }
    const radius = math.sqrt(parallelRadiusSq + worldPoint.z() * worldPoint.z());
    return Cartographic.new(math.atan2(worldPoint.y(), worldPoint.x()), math.atan(v), radius - self.unitScale);
}
pub fn reproject(self: *const Self, comptime P: type, sourceProjection: *const P, worldPoint: *const Vec3) Vec3 {
    if (sourceProjection == webMercatorProjection or sourceProjection == mercatorProjection) {
        const xx = worldPoint.x();
        const yy = worldPoint.y();
        const zz = worldPoint.z();
        const r = self.unitScale;
        const mx = xx / r - math.pi;
        const my = yy / r - math.pi;
        const w = math.exp(my);
        const d = w * w;
        const gx = (2 * w) / (d + 1);
        const gy = (d - 1) / (d + 1);
        const scale = r + zz;

        const x = math.cos(mx) * gx * scale;
        const y = math.sin(mx) * gx * scale;
        var z = gy * scale;

        if (sourceProjection == webMercatorProjection) {
            z = -z;
        }
        return Vec3.new(x, y, z);
    } else {
        if (self == sourceProjection) {
            return worldPoint.clone();
        }
        const t = sourceProjection.unProject(worldPoint);
        return self.project(&t);
    }
}
fn getLongitudeQuadrant(longitude: f64) usize {
    const oneOverPI = 1.0 / math.pi;
    const quadrantIndex = math.floor(2.0 * (longitude * oneOverPI + 1.0));
    const res: usize = @intFromFloat(math.clamp(quadrantIndex, 0, 4));
    return res;
}
fn makeBox3(self: *const Self, geoBox: *const GeoBox) AABB {
    const halfEquatorialRadius = (self.unitScale + geoBox.maxAltitude()) * 0.5;

    const minLongitude = geoBox.west();
    const maxLongitude = geoBox.east();

    const minLongitudeQuadrant = getLongitudeQuadrant(minLongitude);
    const maxLongitudeQuadrant = getLongitudeQuadrant(maxLongitude);

    var xMin = math.cos(minLongitude);
    var xMax = xMin;
    var yMin = math.sin(minLongitude);
    var yMax = yMin;
    for ((minLongitudeQuadrant + 1)..maxLongitudeQuadrant) |quadrantIndex| {
        const a1: f64 = @floatFromInt((quadrantIndex + 1) & 1);
        const a2: f64 = @floatFromInt(quadrantIndex & 1);
        const a3: f64 = @floatFromInt(quadrantIndex & 2);

        const x: f64 = a1 * (a3 - 1);
        xMin = @min(x, xMin);
        xMax = @max(x, xMax);
        const y: f64 = a2 * (a3 - 1);
        yMin = @min(y, yMin);
        yMax = @max(y, yMax);
    }

    const cosMaxLongitude = math.cos(maxLongitude);
    xMin = @min(cosMaxLongitude, xMin);
    xMax = @max(cosMaxLongitude, xMax);

    const sinMaxLongitude = math.sin(maxLongitude);
    yMin = @min(sinMaxLongitude, yMin);
    yMax = @max(sinMaxLongitude, yMax);

    const xCenter = (xMax + xMin) * halfEquatorialRadius;
    const xExtent = (xMax - xMin) * halfEquatorialRadius;

    const yCenter = (yMax + yMin) * halfEquatorialRadius;
    const yExtent = (yMax - yMin) * halfEquatorialRadius;

    // Calculate Z boundaries.
    const minLatitude = geoBox.south();
    const maxLatutide = geoBox.north();

    const zMax = math.sin(maxLatutide);
    const zMin = math.sin(minLatitude);

    const zCenter = (zMax + zMin) * halfEquatorialRadius;
    const zExtent = (zMax - zMin) * halfEquatorialRadius;

    const min = Vec3.new(xCenter - xExtent, yCenter - yExtent, zCenter - zExtent);
    const max = Vec3.new(xCenter + xExtent, yCenter + yExtent, zCenter + zExtent);

    return AABB.new(min, max);
}

fn apply(xAxis: *const Vec3, yAxis: *const Vec3, zAxis: *const Vec3, v: *const Vec3) Vec3 {
    const x = xAxis.x() * v.x() + yAxis.x() * v.y() + zAxis.x() * v.z();
    const y = xAxis.y() * v.x() + yAxis.y() * v.y() + zAxis.y() * v.z();
    const z = xAxis.z() * v.x() + yAxis.z() * v.y() + zAxis.z() * v.z();
    return Vec3.new(x, y, z);
}

pub fn projectBox(self: *const Self, geoBox: *const GeoBox, comptime ResultBoxType: type) ResultBoxType {
    if (ResultBoxType == AABB) {
        return self.makeBox3(geoBox);
    } else if (ResultBoxType == OBB) {
        if (geoBox.longitudeSpan() >= math.pi) {
            const bounds = self.makeBox3(geoBox);
            var x = (bounds.max.x() + bounds.min.x()) * 0.5;
            var y = (bounds.max.y() + bounds.min.y()) * 0.5;
            var z = (bounds.max.z() + bounds.min.z()) * 0.5;

            const center = Vec3.new(x, y, z);

            x = (bounds.max.x() - bounds.min.x()) * 0.5;
            y = (bounds.max.y() - bounds.min.y()) * 0.5;
            z = (bounds.max.z() - bounds.min.z()) * 0.5;

            const scale = Vec3.new(x, y, z);
            var halfAxes = Mat3.ident.clone();
            halfAxes.setScale(&scale);

            return OBB.new(center, halfAxes);
        }
        const south = geoBox.south();
        const west = geoBox.west();
        const north = geoBox.north();
        const east = geoBox.east();
        const mid = geoBox.center();
        const midX = mid.lon;
        const midY = mid.lat;

        const cosSouth = math.cos(south);
        const sinSouth = math.sin(south);
        const cosWest = math.cos(west);
        const sinWest = math.sin(west);
        const cosNorth = math.cos(north);
        const sinNorth = math.sin(north);
        const cosEast = math.cos(east);
        const sinEast = math.sin(east);
        const cosMidX = math.cos(midX);
        const sinMidX = math.sin(midX);
        const cosMidY = math.cos(midY);
        const sinMidY = math.sin(midY);

        const zAxis = Vec3.new(cosMidX * cosMidY, sinMidX * cosMidY, sinMidY);
        const xAxis = Vec3.new(-sinMidX, cosMidX, 0);
        const yAxis = Vec3.new(-cosMidX * sinMidY, -sinMidX * sinMidY, cosMidY);

        var width: f64 = 0;
        var minY: f64 = 0;
        var maxY: f64 = 0;
        if (south >= 0) {
            // abs(dot(southWest - southEast, xAxis))
            width = math.abs(cosSouth * (cosMidX * (sinWest - sinEast) + sinMidX * (cosEast - cosWest)));
            // dot(south, yAxis)
            minY = cosMidY * sinSouth - sinMidY * cosSouth;
            // dot(northEast, zAxis)
            maxY = cosMidY * sinNorth - sinMidY * cosNorth * (cosMidX * cosEast + sinMidX * sinEast);
        } else {
            if (north <= 0) {
                // abs(dot(northWest - northEast, xAxis))
                width = math.abs(cosNorth * (cosMidX * (sinWest - sinEast) + sinMidX * (cosEast - cosWest)));
                // dot(north, yAxis)
                maxY = cosMidY * sinNorth - sinMidY * cosNorth;
            } else {
                // abs(dot(west - east, xAxis))
                width = math.abs(cosMidX * (sinWest - sinEast) + sinMidX * (cosEast - cosWest));
                // dot(northEast, yAxis)
                maxY = cosMidY * sinNorth - sinMidY * cosNorth * (sinMidX * sinEast + cosMidX * cosEast);
            }
            // dot(southEast, yAxis)
            minY = cosMidY * sinSouth - sinMidY * cosSouth * (cosMidX * cosEast + sinMidX * sinEast);
        }
        const rMax = (self.unitScale + geoBox.maxAltitude()) * 0.5;
        const rMin = (self.unitScale + geoBox.minAltitude()) * 0.5;

        // min(dot(southEast, zAxis), dot(northEast, zAxis))

        const d = cosMidY * (cosMidX * cosEast + sinMidX * sinEast);
        const minZ = @min(cosNorth * d + sinNorth * sinMidY, cosSouth * d + sinSouth * sinMidY);
        const extents = Vec3.new(width * rMax, (maxY - minY) * rMax, rMax - minZ * rMin);
        var positionTemp = Vec3.new(0, (minY + maxY) * rMax, rMax + rMax);

        positionTemp = apply(&xAxis, &yAxis, &zAxis, &positionTemp);

        const x = positionTemp.x() - zAxis.x() * extents.z();
        const y = positionTemp.y() - zAxis.y() * extents.z();
        const z = positionTemp.z() - zAxis.z() * extents.z();
        const position = Vec3.new(x, y, z);

        var halfAxes = Mat3.new(&xAxis, &yAxis, &zAxis).transpose();
        halfAxes.setScale(&extents);
        return OBB.new(position, halfAxes);
    } else {
        @compileError("invalid bounding box");
    }
}
// pub fn unprojectBox(_: *const Self, _: *const OBB) GeoBox {
//     @compileError("unprojectBox not implemented");
// }
pub fn unprojectAltitude(_: *const Self, worldPoint: *const Vec3) f64 {
    return worldPoint.len() - earth.EQUATORIAL_RADIUS;
}
pub fn getScaleFactor(_: *const Self, _: *const Vec3) f64 {
    return 1;
}
pub fn surfaceNormal(_: *const Self, worldPoint: *const Vec3) Vec3 {
    var length = worldPoint.len();
    if (length == 0) {
        length = 1.0;
    }
    const scale = 1 / length;
    return worldPoint.mulScalar(scale);
}
pub fn groundDistance(self: *const Self, worldPoint: *const Vec3) f64 {
    return worldPoint.len() - self.unitScale;
}
pub fn scalePointToSurface(self: *const Self, worldPoint: *const Vec3) Vec3 {
    var length = worldPoint.len();
    if (length == 0) {
        length = 1.0;
    }
    const scale = self.unitScale / length;
    return worldPoint.mulScalar(scale);
}
pub fn localTangentSpace(self: *const Self, geoPoint: *const Cartographic) Mat4 {
    const world_point = self.project(geoPoint);
    const latitude = geoPoint.lat;
    const longitude = geoPoint.lon;
    const cosLongitude = math.cos(longitude);
    const sinLongitude = math.sin(longitude);
    const cosLatitude = math.cos(latitude);
    const sinLatitude = math.sin(latitude);
    var slice = [1]f64{0} ** 16;
    //x axis
    slice[0] = -sinLongitude;
    slice[1] = cosLongitude;
    slice[2] = 0;
    slice[3] = 0;
    //y axis
    slice[4] = -cosLongitude * sinLongitude;
    slice[5] = -sinLongitude * sinLatitude;
    slice[6] = cosLatitude;
    slice[7] = 0;
    //z axis
    slice[8] = cosLongitude * cosLatitude;
    slice[9] = sinLongitude * cosLatitude;
    slice[10] = sinLatitude;
    slice[11] = 0;
    //point
    slice[12] = world_point.x();
    slice[13] = world_point.y();
    slice[14] = world_point.z();
    slice[15] = 1;
    return Mat4.fromArray(&slice);
}
pub const sphereProjection = ProjectionImpl(SphereProjection).new(earth.EQUATORIAL_RADIUS);

const testing = @import("std").testing;
const debug = @import("std").debug;
test "SphereProjection.projectAndunproject" {
    const geoPoint = Cartographic.fromDegrees(-122.4410209359072, 37.8178183439856, 12.0);
    try testing.expectEqual(geoPoint.lon, std.math.degreesToRadians(-122.4410209359072));
    const epsilon = 0.000000001;
    const worldPoint = sphereProjection.project(&geoPoint);
    const geoPoint2 = sphereProjection.unproject(&worldPoint);
    try testing.expectApproxEqAbs(geoPoint.lat, geoPoint2.lat, epsilon);
    try testing.expectApproxEqAbs(geoPoint.lon, geoPoint2.lon, epsilon);
    try testing.expectApproxEqAbs(geoPoint.height, geoPoint2.height, epsilon);
}

test "SphereProjection.groundDistance" {
    const geoPoint = Cartographic.fromDegrees(-122.4410209359072, 37.8178183439856, 12.0);
    const epsilon = 0.000000001;
    const worldPoint = sphereProjection.project(&geoPoint);
    try testing.expectApproxEqAbs(sphereProjection.groundDistance(&worldPoint), 12, epsilon);
}

test "SphereProjection.scalePointToSurface" {
    const geoPoint = Cartographic.fromDegrees(-122.4410209359072, 37.8178183439856, 12.0);
    const epsilon = 0.000000001;
    const worldPoint = sphereProjection.project(&geoPoint);
    const worldPoint2 = sphereProjection.scalePointToSurface(&worldPoint);
    try testing.expectApproxEqAbs(sphereProjection.groundDistance(&worldPoint2), 0, epsilon);
}

test "SphereProjection.localTangentSpace" {
    // const geoPoint = Cartographic.new(-74.01154, 40.702);
}

test "SphereProjection.projectBox" {
    const southEastLow = Cartographic.fromDegrees(-10, -10, -10);
    const northWestHigh = Cartographic.fromDegrees(10, 10, 10);
    const geoBox = GeoBox.new(southEastLow, northWestHigh);
    const worldBox = sphereProjection.projectBox(&geoBox, OBB);

    const insidePoints: [7]Cartographic = .{
        Cartographic.fromDegrees(0, 0, 0),
        Cartographic.fromDegrees(0, 0, 9),
        Cartographic.fromDegrees(0, 0, -9),
        Cartographic.fromDegrees(0, 9, 0),
        Cartographic.fromDegrees(0, -9, 0),
        Cartographic.fromDegrees(9, 0, 0),
        Cartographic.fromDegrees(-9, 0, 0),
    };

    for (insidePoints) |geoPoint| {
        const p = sphereProjection.project(&geoPoint);
        try testing.expect(worldBox.contains(&p));
    }

    const outsidePoints: [5]Cartographic = .{
        Cartographic.fromDegrees(0, 0, 12),
        Cartographic.fromDegrees(0, 12, 0),
        Cartographic.fromDegrees(0, -12, 0),
        Cartographic.fromDegrees(12, 0, 0),
        Cartographic.fromDegrees(-12, 0, 0),
    };

    for (outsidePoints) |geoPoint| {
        const p = sphereProjection.project(&geoPoint);
        try testing.expect(!worldBox.contains(&p));
    }
}

test "SphereProjection.projectBox2" {
    const southEastLow = Cartographic.fromDegrees(-170, 40, -10);
    const northWestHigh = Cartographic.fromDegrees(170, 50, 10);
    const geoBox = GeoBox.new(southEastLow, northWestHigh);
    const worldBox = sphereProjection.projectBox(&geoBox, OBB);

    const insidePoints: [3]Cartographic = .{
        Cartographic.fromDegrees(0, 45, 0),
        Cartographic.fromDegrees(0, 49.9999, 10),
        Cartographic.fromDegrees(0, 40.0001, 10),
    };

    for (insidePoints) |geoPoint| {
        const p = sphereProjection.project(&geoPoint);
        try testing.expect(worldBox.contains(&p));
    }

    const outsidePoints: [1]Cartographic = .{
        Cartographic.fromDegrees(0, 60, 0),
    };

    for (outsidePoints) |geoPoint| {
        const p = sphereProjection.project(&geoPoint);
        try testing.expect(!worldBox.contains(&p));
    }
}

test "SphereProjection.vectorCopy" {
    const ele_4 = @Vector(4, i32);

    // 向量必须拥有编译期已知的长度和类型
    const a = ele_4{ 1, 2, 3, 4 };
    var d: @Vector(4, i32) = a;
    d[0] = 10;
    try testing.expectEqual(d[0], 10);
    try testing.expectEqual(a[0], 1);
}

test "SphereProjection.worldExtent" {
    const v = sphereProjection.worldExtent(0, 0);
    try testing.expectEqual(v.min.x(), -earth.EQUATORIAL_RADIUS);
}
