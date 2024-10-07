const std = @import("std");
const math = @import("math");
const Vec3 = math.Vec3d;
const Mat4 = math.Mat4x4d;
const Cartographic = @import("../Cartographic.zig").Cartographic;
const AABB = @import("../AABB.zig").AABB;
const GeoBox = @import("../GeoBox.zig").GeoBox;
const ProjectionType = @import("./ProjectionType.zig").ProjectionType;
pub fn Projection(comptime Impl: type) type {
    return struct {
        impl: Impl,
        const This = @This();
        pub fn new(uintScale: f64) This {
            const impl = Impl.new(uintScale);
            return .{ .impl = impl };
        }
        pub fn getType(this: This) ProjectionType {
            return this.impl.getType();
        }
        pub fn worldExtent(this: This, minElevation: f64, maxElevation: f64) AABB {
            return this.impl.worldExtent(minElevation, maxElevation);
        }

        pub fn project(this: This, geoPoint: *const Cartographic) Vec3 {
            return this.impl.project(geoPoint);
        }
        pub fn unproject(this: This, worldPoint: *const Vec3) Cartographic {
            return this.impl.unproject(worldPoint);
        }

        pub fn reproject(this: This, comptime P: type, sourceProjection: *const P, geoPoint: *const Vec3) Vec3 {
            return this.impl.reproject(sourceProjection, geoPoint);
        }

        pub fn projectBox(this: This, geoBox: *const GeoBox, comptime ResultBoxType: type) ResultBoxType {
            return this.impl.projectBox(geoBox, ResultBoxType);
        }
        pub fn unprojectBox(this: This, worldBox: *const AABB) GeoBox {
            return this.impl.unprojectBox(worldBox);
        }

        pub fn unprojectAltitude(this: This, worldPoint: *const Vec3) f64 {
            return this.impl.unprojectAltitude(worldPoint);
        }

        pub fn getScaleFactor(this: This, worldPoint: *const Vec3) f64 {
            return this.impl.getScaleFactor(worldPoint);
        }
        pub fn surfaceNormal(this: This, worldPoint: *const Vec3) f64 {
            return this.impl.surfaceNormal(worldPoint);
        }
        pub fn groundDistance(this: This, worldPoint: *const Vec3) f64 {
            return this.impl.groundDistance(worldPoint);
        }
        pub fn scalePointToSurface(this: This, worldPoint: *const Vec3) Vec3 {
            return this.impl.scalePointToSurface(worldPoint);
        }
        pub fn localTangentSpace(this: This, geoPoint: *const Cartographic) Mat4 {
            return this.impl.localTangentSpace(geoPoint);
        }
    };
}
