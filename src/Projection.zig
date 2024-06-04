const lib = @import("lib.zig");
const assert = @import("std").debug.assert;
const Vec3 = lib.math.Vec3;
const Mat4 = lib.math.Mat4;
const GeoCoordinates = lib.GeoCoordinates;
pub const Projection = struct {
    const This = @This();
    ptr: *anyopaque,
    vtable: *const VTable,
    const VTable = struct {
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
    // 将具体实现类型/对象转换为接口
    // pub fn init(obj: anytype) This {
    //     const Ptr = @TypeOf(obj);
    //     const PtrInfo = @typeInfo(Ptr);
    //     assert(PtrInfo == .Pointer); // 必须是指针
    //     assert(PtrInfo.Pointer.size == .One); // 必须是单项指针
    //     assert(@typeInfo(PtrInfo.Pointer.child) == .Struct); // 必须指向一个结构体
    //     const impl = struct {
    //         fn draw(ptr: *anyopaque) void {
    //             const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
    //             self.draw();
    //         }
    //         fn move(ptr: *anyopaque, dx: i32, dy: i32) void {
    //             const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
    //             self.move(dx, dy);
    //         }
    //     };
    //     return .{
    //         .ptr = obj,
    //         .vtab = &.{
    //             .draw = @ptrCast(obj),
    //             .move = impl.move,
    //         },
    //     };
    // }
};
fn MakeProjection(comptime T: type, ctx: *T) Projection {
    return .{
        .ptr = ctx,
        .vtable = &.{
            .worldExtent = T.worldExtent,
            .projectPoint = T.projectPoint,
            .unprojectPoint = T.unprojectPoint,
            .unprojectAltitude = T.unprojectAltitude,
            .groundDistance = T.groundDistance,
            .scalePointToSurface = T.scalePointToSurface,
            .localTagentSpace = T.localTagentSpace,
        },
    };
}
