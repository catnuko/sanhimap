const vec = @import("./GenericVector.zig");
const Vec2 = vec.Vec2;
const Vec3 = vec.Vec3;
const Vec4 = vec.Vec4;
pub fn Mat3(comptime T: type) type {
    return extern struct {
        const Self = @This();
        const Data = [4]T;
        data: Data,
    };
}
