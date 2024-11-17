const math = @import("../math.zig");
const Cartographic = @import("../Cartographic.zig").Cartographic;
const AxisAlignedBoundingBox = @import("../AxisAlignedBoundingBox.zig").AxisAlignedBoundingBox;
pub const Projection = struct {
    const This = @This();
    pub const VTable = struct {
        worldExtent: *const fn (ctx: *anyopaque, minElevation: f64, maxElevation: f64) AxisAlignedBoundingBox,
        project: *const fn (ctx: *anyopaque, geoPoint: *const Cartographic) math.Vector3,
        unproject: *const fn (ctx: *anyopaque, worldPoint: *const math.Vector3) Cartographic,
        unprojectAltitude: *const fn (ctx: *anyopaque, worldPoint: *const math.Vector3) f64,
        groundDistance: *const fn (ctx: *anyopaque, worldPoint: *const math.Vector3) f64,
        scalePointToSurface: *const fn (ctx: *anyopaque, worldPoint: *const math.Vector3) math.Vector3,
        localTagentSpace: *const fn (ctx: *anyopaque, geoPoint: *const Cartographic) math.Matrix4D,
    };
    ptr: *anyopaque,
    vtable: *const VTable,
    pub fn new(ptr: anytype) Projection {
        const T = @TypeOf(ptr);
        const ptr_info = @typeInfo(T);

        const gen = struct {
            pub fn worldExtent(ctx: *anyopaque, minElevation: f64, maxElevation: f64) AxisAlignedBoundingBox {
                const self: T = @ptrCast(@alignCast(ctx));
                return ptr_info.Pointer.child.worldExtent(self, minElevation, maxElevation);
            }
            pub fn project(ctx: *anyopaque, geoPoint: *const Cartographic) math.Vector3 {
                const self: T = @ptrCast(@alignCast(ctx));
                return ptr_info.Pointer.child.project(self, geoPoint);
            }
            pub fn unproject(ctx: *anyopaque, worldPoint: *const math.Vector3) Cartographic {
                const self: T = @ptrCast(@alignCast(ctx));
                return ptr_info.Pointer.child.unproject(self, worldPoint);
            }
            pub fn unprojectAltitude(ctx: *anyopaque, worldPoint: *const math.Vector3) f64 {
                const self: T = @ptrCast(@alignCast(ctx));
                return ptr_info.Pointer.child.unprojectAltitude(self, worldPoint);
            }
            pub fn groundDistance(ctx: *anyopaque, worldPoint: *const math.Vector3) f64 {
                const self: T = @ptrCast(@alignCast(ctx));
                return ptr_info.Pointer.child.groundDistance(self, worldPoint);
            }
            pub fn scalePointToSurface(ctx: *anyopaque, worldPoint: *const math.Vector3) math.Vector3 {
                const self: T = @ptrCast(@alignCast(ctx));
                return ptr_info.Pointer.child.scalePointToSurface(self, worldPoint);
            }
            pub fn localTagentSpace(ctx: *anyopaque, geoPoint: *const Cartographic) math.Matrix4D {
                const self: T = @ptrCast(@alignCast(ctx));
                return ptr_info.Pointer.child.localTagentSpace(self, geoPoint);
            }
        };
        return .{
            .ptr = ptr,
            .vtable = &.{
                .worldExtent = gen.worldExtent,
                .project = gen.project,
                .unproject = gen.unproject,
                .unprojectAltitude = gen.unprojectAltitude,
                .groundDistance = gen.groundDistance,
                .scalePointToSurface = gen.scalePointToSurface,
                .localTagentSpace = gen.localTagentSpace,
            },
        };
    }
    pub fn worldExtent(this: This, minElevation: f64, maxElevation: f64) AxisAlignedBoundingBox {
        return this.vtable.worldExtent(this.ptr, minElevation, maxElevation);
    }
    pub fn project(this: This, geoPoint: *const Cartographic) math.Vector3 {
        return this.vtable.project(this.ptr, geoPoint);
    }
    pub fn unproject(this: This, worldPoint: *const math.Vector3) Cartographic {
        return this.vtable.unproject(this.ptr, worldPoint);
    }
    pub fn unprojectAltitude(this: This, worldPoint: *const math.Vector3) f64 {
        return this.vtable.unprojectAltitude(this.ptr, worldPoint);
    }
    pub fn groundDistance(this: This, worldPoint: *const math.Vector3) f64 {
        return this.vtable.groundDistance(this.ptr, worldPoint);
    }
    pub fn scalePointToSurface(this: This, worldPoint: *const math.Vector3) math.Vector3 {
        return this.vtable.scalePointToSurface(this.ptr, worldPoint);
    }
    pub fn localTagentSpace(this: This, geoPoint: *const Cartographic) math.Matrix4D {
        return this.vtable.localTagentSpace(this.ptr, geoPoint);
    }
};
