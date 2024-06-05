const lib = @import("lib.zig");
const assert = @import("std").debug.assert;
const Vec3 = lib.math.Vec3;
const Mat4 = lib.math.Mat4;
const GeoCoordinates = lib.GeoCoordinates;
pub const Projection = struct {
    const This = @This();
    ptr: *anyopaque,
    vtable: *const VTable,
    pub const VTable = struct {
        worldExtent: *const fn (ctx: *anyopaque, minElevation: f64, maxElevation: f64) lib.Box3,
        projectPoint: *const fn (ctx: *anyopaque, geoPoint: GeoCoordinates) Vec3,
        unprojectPoint: *const fn (ctx: *anyopaque, worldPoint: Vec3) GeoCoordinates,
        unprojectAltitude: *const fn (ctx: *anyopaque, worldPoint: Vec3) f64,
        groundDistance: *const fn (ctx: *anyopaque, worldPoint: Vec3) f64,
        scalePointToSurface: *const fn (ctx: *anyopaque, worldPoint: Vec3) Vec3,
        localTagentSpace: *const fn (ctx: *anyopaque, geoPoint: GeoCoordinates) Mat4,
    };
    pub fn worldExtent(this: This, minElevation: f64, maxElevation: f64) lib.Box3 {
        return this.vtable.worldExtent(this.ptr, minElevation, maxElevation);
    }
    pub fn projectPoint(this: This, geoPoint: GeoCoordinates) Vec3 {
        return this.vtable.projectPoint(this.ptr, geoPoint);
    }
    pub fn unprojectPoint(this: This, worldPoint: Vec3) GeoCoordinates {
        return this.vtable.unprojectPoint(this.ptr, worldPoint);
    }
    pub fn unprojectAltitude(this: This, worldPoint: Vec3) f64 {
        return this.vtable.unprojectAltitude(this.ptr, worldPoint);
    }
    pub fn groundDistance(this: This, worldPoint: Vec3) f64 {
        return this.vtable.groundDistance(this.ptr, worldPoint);
    }
    pub fn scalePointToSurface(this: This, worldPoint: Vec3) Vec3 {
        return this.vtable.scalePointToSurface(this.ptr, worldPoint);
    }
    pub fn localTagentSpace(this: This, geoPoint: GeoCoordinates) Mat4 {
        return this.vtable.localTagentSpace(this.ptr, geoPoint);
    }
};
