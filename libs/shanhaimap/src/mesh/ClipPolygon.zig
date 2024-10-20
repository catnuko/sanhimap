const math = @import("../math.zig");
const Vec2 = math.Vec2;
const Vec3 = math.Vec3;
const ArrayList = @import("std").ArrayList;
const Allocator = @import("std").mem.Allocator;
pub const LineString = ArrayList(Vec2);
pub const LineStrings = ArrayList(ArrayList(Vec2));

pub const Polygon = ArrayList(Vec2);
pub fn clipPolygon(polygon: *Polygon, extent: f64) Polygon {}
