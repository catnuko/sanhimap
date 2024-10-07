const std = @import("std");
const math = @import("math");

pub usingnamespace @import("./AABB.zig");
pub usingnamespace @import("./BoundingRectangle.zig");
pub usingnamespace @import("./BoundingSphere.zig");
pub usingnamespace @import("./Cartographic.zig");
pub usingnamespace @import("./Ellipsoid.zig");
pub usingnamespace @import("./GeoBox.zig");
pub usingnamespace @import("./OBB.zig");
pub usingnamespace @import("./Rectangle.zig");
pub usingnamespace @import("./RectangleCorner.zig");

pub const geodesic = @import("geodesic/index.zig");
pub const ui = @import("./ui/index.zig");
pub const tiling = @import("./tiling/index.zig");
pub const projection = @import("./projection/index.zig");
pub const datasource = @import("./datasource/index.zig");

pub usingnamespace @import("./MapView.zig");
test {
    const testing = std.testing;
    testing.refAllDecls(@This()); //只有pub修饰的结构体才会被导入到此处，递归会递归执行非顶级test，就是带名字的test
}
