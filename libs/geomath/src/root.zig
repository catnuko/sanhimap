const std = @import("std");
const math = @import("math");
pub const Cartographic = @import("./Cartographic.zig").Cartographic;
pub const GeoBox = @import("./GeoBox.zig").GeoBox;
pub const Ellipsoid = @import("Ellipsoid.zig").Ellipsoid;
pub const geodesic = @import("geodesic/root.zig");
pub const SphereProjection = @import("SphereProjection.zig").SphereProjection;

test {
    const testing = std.testing;
    testing.refAllDeclsRecursive(@This()); //只有pub修饰的结构体才会被导入到此处，递归会递归执行非顶级test，就是带名字的test
}
