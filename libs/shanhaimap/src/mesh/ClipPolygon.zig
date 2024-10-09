const math = @import("math");
const Vec2 = math.Vec2d;
const Vec3 = math.Vec3d;
const ArrayList = @import("std").ArrayList;
const Allocator = @import("std").mem.Allocator;
pub const LineString = ArrayList(Vec2);
pub const LineStrings = ArrayList(ArrayList(Vec2));

pub const Polygon = ArrayList(Vec2);
pub fn clipPolygon(polygon: *Polygon, extent: f64) Polygon {}
