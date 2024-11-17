const math = @import("../math.zig");
const Vector2 = math.Vector2;
const Vector3 = math.Vector3;
const ArrayList = @import("std").ArrayList;
const Allocator = @import("std").mem.Allocator;
pub const LineString = ArrayList(Vector2);
pub const LineStrings = ArrayList(ArrayList(Vector2));

pub const Polygon = ArrayList(Vector2);
pub fn clipPolygon(polygon: *Polygon, extent: f64) Polygon {}
