const std = @import("std");
const math = @import("../math.zig");
const debug = @import("../debug.zig");
const graphics = @import("../platform/graphics.zig");
const plane = @import("plane.zig");
const assert = std.debug.assert;

const Vector3 = math.Vector3;
const Plane = plane.Plane;

/// An axis aligned bounding box
pub const BoundingBox = struct {
    min: Vector3,
    max: Vector3,
    center: Vector3,

    /// Creates a new bounding box based on a position and size
    pub fn init(position: Vector3, size: Vector3) BoundingBox {
        const half_size = size.scale(0.5);
        return BoundingBox{
            .center = position,
            .min = position.subtract(half_size),
            .max = position.add(half_size),
        };
    }

    /// Creates a new bounding box that fits some positions
    pub fn initFromPositions(positions: []const Vector3) BoundingBox {
        if (positions.len == 0)
            return BoundingBox{ .center = Vector3.zero, .min = Vector3.zero, .max = Vector3.zero };

        var min = positions[0];
        var max = positions[0];

        for (positions) |pos| {
            min = Vector3.min(min, pos);
            max = Vector3.max(max, pos);
        }

        return BoundingBox{
            .center = Vector3.new(min.x + (max.x - min.x) * 0.5, min.y + (max.y - min.y) * 0.5, min.z + (max.z - min.z) * 0.5),
            .min = min,
            .max = max,
        };
    }

    /// Creates a new bounding box that fits some verts
    pub fn initFromVerts(verts: []const graphics.PackedVertex) BoundingBox {
        if (verts.len == 0)
            return BoundingBox{ .center = Vector3.zero, .min = Vector3.zero, .max = Vector3.zero };

        var min = verts[0].getPosition();
        var max = verts[0].getPosition();

        for (verts) |vert| {
            const vert_pos = vert.getPosition();
            min = Vector3.min(min, vert_pos);
            max = Vector3.max(max, vert_pos);
        }

        return BoundingBox{
            .center = Vector3.new(min.x + (max.x - min.x) * 0.5, min.y + (max.y - min.y) * 0.5, min.z + (max.z - min.z) * 0.5),
            .min = min,
            .max = max,
        };
    }

    /// Scale this bounding box
    pub fn scale(self: *const BoundingBox, scale_by: f32) BoundingBox {
        var ret = self.*;
        ret.min = ret.min.scale(scale_by);
        ret.max = ret.max.scale(scale_by);
        return ret;
    }

    /// Translate this bounding box
    pub fn translate(self: *const BoundingBox, move_by: Vector3) BoundingBox {
        var ret = self.*;
        ret.center = ret.center.add(move_by);
        ret.min = ret.min.add(move_by);
        ret.max = ret.max.add(move_by);
        return ret;
    }

    /// Increase the size of this bounding box
    pub fn inflate(self: *const BoundingBox, amount: f32) BoundingBox {
        const increase_by = Vector3.new(amount, amount, amount);

        var ret = self.*;
        ret.min = ret.min.subtract(increase_by);
        ret.max = ret.max.add(increase_by);
        return ret;
    }

    /// Transforms this bounding box by a matrix
    pub fn transform(self: *const BoundingBox, transform_mat: math.Mat4) BoundingBox {
        const corners = self.getCorners();

        // Set min and max to the center to start with
        const center = self.center.mulMat4(transform_mat);
        var min = center;
        var max = center;

        // find the new min and max
        for (corners) |corner| {
            const transformed = corner.mulMat4(transform_mat);
            min = Vector3.min(min, transformed);
            max = Vector3.max(max, transformed);
        }

        return BoundingBox{
            .center = center,
            .min = min,
            .max = max,
        };
    }

    /// Returns locations of all the corners
    pub fn getCorners(self: *const BoundingBox) [8]Vector3 {
        return [8]Vector3{
            Vector3.new(self.min.x, self.max.y, self.max.z),
            Vector3.new(self.max.x, self.max.y, self.max.z),
            Vector3.new(self.min.x, self.max.y, self.min.z),
            Vector3.new(self.max.x, self.max.y, self.min.z),
            Vector3.new(self.min.x, self.min.y, self.max.z),
            Vector3.new(self.max.x, self.min.y, self.max.z),
            Vector3.new(self.min.x, self.min.y, self.min.z),
            Vector3.new(self.max.x, self.min.y, self.min.z),
        };
    }

    pub fn getPlanes(self: *const BoundingBox) [6]Plane {
        return [6]Plane{
            Plane.init(Vector3.new(1, 0, 0), Vector3.new(self.max.x, self.center.y, self.center.z)),
            Plane.init(Vector3.new(-1, 0, 0), Vector3.new(self.min.x, self.center.y, self.center.z)),
            Plane.init(Vector3.new(0, 1, 0), Vector3.new(self.center.x, self.max.y, self.center.z)),
            Plane.init(Vector3.new(0, -1, 0), Vector3.new(self.center.x, self.min.y, self.center.z)),
            Plane.init(Vector3.new(0, 0, 1), Vector3.new(self.center.x, self.center.y, self.max.z)),
            Plane.init(Vector3.new(0, 0, -1), Vector3.new(self.center.x, self.center.y, self.min.z)),
        };
    }

    /// Check to see if this bounding box contains a point
    pub fn contains(self: *const BoundingBox, point: Vector3) bool {
        return point.x >= self.min.x and point.y >= self.min.y and point.z >= self.min.z and
            point.x <= self.max.x and point.y <= self.max.y and point.z <= self.max.z;
    }

    /// Check to see if this bounding box contains part or all of another
    pub fn intersects(self: *const BoundingBox, other: BoundingBox) bool {
        return other.max.x >= self.min.x and other.max.y >= self.min.y and other.max.z >= self.min.z and
            other.min.x <= self.max.x and other.min.y <= self.max.y and other.min.z <= self.max.z;
    }
};

test "BoundingBox.contains" {
    const box = BoundingBox.init(Vector3.zero, Vector3.new(4, 6, 4));
    assert(box.contains(Vector3.zero) == true);
    assert(box.contains(Vector3.new(-2, 0, -2)) == true);
    assert(box.contains(Vector3.new(-2.5, 2, 2)) == false);
    assert(box.contains(Vector3.new(1.5, 3, 1)) == true);
    assert(box.contains(Vector3.new(3, 0, 0)) == false);

    const box2 = BoundingBox.init(Vector3.new(10, 5, 5), Vector3.new(4, 8, 4));
    assert(box2.contains(Vector3.zero) == false);
    assert(box2.contains(Vector3.new(10, 4, 4)) == true);
    assert(box2.contains(Vector3.new(12, 9, 7)) == true);
    assert(box2.contains(Vector3.new(8, 1, 3)) == true);
    assert(box2.contains(Vector3.new(14, 9, 7)) == false);
}

test "BoundingBox.intersects" {
    const box1 = BoundingBox.init(Vector3.zero, Vector3.new(2, 4, 2));
    const box2 = BoundingBox.init(Vector3.new(10, 5, 5), Vector3.new(2, 4, 2));
    const box3 = BoundingBox.init(Vector3.new(11, 7, 6), Vector3.new(2, 4, 2));
    const box4 = BoundingBox.init(Vector3.new(2, 2, 2), Vector3.new(20, 20, 20));

    assert(box1.intersects(box2) == false);
    assert(box2.intersects(box3) == true);
    assert(box3.intersects(box1) == false);
    assert(box4.intersects(box1) == true);
    assert(box1.intersects(box4) == true);
    assert(box4.intersects(box2) == true);
    assert(box4.intersects(box3) == true);
}

test "BoundingBox.transform" {
    const box = BoundingBox.init(Vector3.new(1, -2, 3), Vector3.new(2, 4, 2));
    const tmat = math.Mat4.translate(Vector3.new(10, 1, -2));

    const transformed = box.transform(tmat);
    assert(transformed.center.x == 11);
    assert(transformed.center.y == -1);
    assert(transformed.center.z == 1);

    assert(box.min.x == 0);
    assert(transformed.min.x == 10);
    assert(transformed.min.y == -3);
    assert(transformed.min.z == 0);

    assert(box.max.x == 2);
    assert(box.max.y == 0);
    assert(box.max.z == 4);
    assert(transformed.max.x == 12);
    assert(transformed.max.y == 1);
    assert(transformed.max.z == 2);
}

test "BoundingBox.initFromPositions" {
    const positions = &[_]Vector3{ Vector3.new(10, 5, 2), Vector3.new(20, 18, 6), Vector3.new(13, 8, 8) };

    const box = BoundingBox.initFromPositions(positions);
    assert(box.min.x == 10);
    assert(box.min.y == 5);
    assert(box.min.z == 2);
    assert(box.max.x == 20);
    assert(box.max.y == 18);
    assert(box.max.z == 8);
    assert(box.center.x == 15);
    assert(box.center.y == 11.5);
    assert(box.center.z == 5);
}
