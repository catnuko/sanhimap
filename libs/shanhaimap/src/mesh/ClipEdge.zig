const math2d = @import("../math2d/index.zig");
const math = @import("math");
const Vec2 = math.Vec2d;
const Vec3 = math.Vec3d;
const ArrayList = @import("std").ArrayList;
const Allocator = @import("std").mem.Allocator;
pub const LineString = ArrayList(Vec2);
pub const LineStrings = ArrayList(ArrayList(Vec2));
pub const ClipEdge = struct {
    p0: Vec2,
    p1: Vec2,
    insideClosre: InsideClosure,
    const Self = @This();
    pub fn new(
        x1: f64,
        y1: f64,
        x2: f64,
        y2: f64,
        i: InsideClosure,
    ) Self {
        return Self{
            .p0 = Vec2.new(x1, y1),
            .p1 = Vec2.new(x2, y2),
            .insideClosre = i,
        };
    }
    pub inline fn inside(self: *const Self, p: *const Vec2) bool {
        return self.insideClosre.inside(p);
    }
    pub fn computeIntersection(self: *const Self, a: *const Vec2, b: *const Vec2) ?Vec2 {
        return math2d.intersectLines(
            a.x(),
            a.y(),
            b.x(),
            b.y(),
            self.p0.x(),
            self.p0.y(),
            self.p1.x(),
            self.p1.y(),
        );
    }
    pub fn clipLine(self: *const Self, allocator: Allocator, inputList: *const LineString) LineStrings {
        var lineString = inputList.clone() catch unreachable;
        defer lineString.deinit();

        var result = LineStrings.init(allocator);
        lineString.clearAndFree();
        result.append(lineString) catch unreachable;
        for (0..inputList.items.len) |i| {
            const currentPoint = inputList.items[i];
            const prevPoint: ?Vec2 = if (i > 0) inputList.items[i - 1] else null;
            if (self.inside(&currentPoint)) {
                if (prevPoint) |p| {
                    if (!self.inside(&p)) {
                        if (lineString.items.len > 0) {
                            lineString.clearAndFree();
                            result.append(lineString) catch unreachable;
                        }
                        const v = self.computeIntersection(&p, &currentPoint) orelse unreachable;
                        pushPoint(&lineString, v);
                    }
                }
                pushPoint(&lineString, currentPoint);
            } else {
                if (prevPoint) |p| {
                    if (self.inside(&p)) {
                        const v = self.computeIntersection(&p, &currentPoint) orelse unreachable;
                        pushPoint(&lineString, v);
                    }
                }
            }
        }

        if (result.getLast().items.len == 0) {
            _ = result.pop();
        }
        return result;
    }
    pub fn clipLines(self: *const Self, allocator: Allocator, lineStrings: *const LineStrings) LineStrings {
        var result = LineStrings.init(allocator);
        for (lineStrings.items) |lineString| {
            const r = self.clipLine(allocator, &lineString);
            for (r.items) |clippedLine| {
                result.append(clippedLine) catch unreachable;
            }
            r.deinit();
        }
        return result;
    }
};
fn pushPoint(lineString: *LineString, point: Vec2) void {
    if (lineString.items.len == 0 or !lineString.getLast().eql(&point)) {
        lineString.append(point) catch unreachable;
    }
}

pub fn clipLineString(alloc: Allocator, lineString: *const LineString, minX: f64, minY: f64, maxX: f64, maxY: f64) LineStrings {
    const clipEdge0 = ClipEdge.new(minX, minY, minX, maxY, InsideClosure.new(.x, .gt, minX)); // left
    const clipEdge1 = ClipEdge.new(minX, maxY, maxX, maxY, InsideClosure.new(.y, .lt, maxY)); // bottom
    const clipEdge2 = ClipEdge.new(maxX, maxY, maxX, minY, InsideClosure.new(.x, .lt, maxX)); // right
    const clipEdge3 = ClipEdge.new(maxX, minY, minX, minY, InsideClosure.new(.y, .gt, minY)); // top

    var lines = clipEdge0.clipLine(alloc, lineString);

    var lines2 = clipEdge1.clipLines(alloc, &lines);
    lines.deinit();
    lines = lines2;

    lines2 = clipEdge2.clipLines(alloc, &lines);
    lines.deinit();
    lines = lines2;

    lines2 = clipEdge3.clipLines(alloc, &lines);
    lines.deinit();
    lines = lines2;

    return lines;
}

const OpType = enum {
    gt,
    lt,
};
const XY = enum {
    x,
    y,
};
const InsideClosure = struct {
    op: OpType,
    v: f64,
    xy: XY,
    const Self = @This();
    pub fn new(a: XY, b: OpType, v: f64) Self {
        return .{
            .xy = a,
            .op = b,
            .v = v,
        };
    }
    fn inside(self: *const Self, p: *const Vec2) bool {
        const a = switch (self.xy) {
            XY.x => p.x(),
            XY.y => p.y(),
        };
        return switch (self.op) {
            .gt => a > self.v,
            .lt => a < self.v,
        };
    }
};

test "ClipEdge" {
    const testing = @import("std").testing;
    var lineString = LineString.init(testing.allocator);
    defer lineString.deinit();
    try lineString.append(Vec2.new(0, 0));
    try lineString.append(Vec2.new(10, 0));
    try lineString.append(Vec2.new(20, 0));
    const DEFAULT_BORDER: f64 = 100;
    const DEFAULT_EXTENTS: f64 = 4 * 1024;
    const clippedLineStrings = clipLineString(
        testing.allocator,
        &lineString,
        -DEFAULT_BORDER,
        -DEFAULT_BORDER,
        DEFAULT_EXTENTS + DEFAULT_BORDER,
        DEFAULT_EXTENTS + DEFAULT_BORDER,
    );
    defer clippedLineStrings.deinit();
}
