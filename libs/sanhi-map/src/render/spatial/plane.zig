const std = @import("std");
const math = @import("../math.zig");
const debug = @import("../debug.zig");
const boundingbox = @import("boundingbox.zig");
const assert = std.debug.assert;

const Vector3 = math.Vector3;

// Based a lot on the LibGdx plane class

pub const PlaneFacing = enum(i32) { ON_PLANE, BACK, FRONT };

pub const Plane = struct {
    normal: Vector3,
    d: f32,

    /// Creates a plane from a normal and a point on the plane
    pub fn init(normal: Vector3, point: Vector3) Plane {
        const norm = normal.norm();
        return Plane{
            .normal = norm,
            .d = -norm.dot(point),
        };
    }

    /// Creates a plane from a normal and distance to the origin
    pub fn initFromDistance(normal: Vector3, distance: f32) Plane {
        return Plane{
            .normal = normal.norm(),
            .d = distance,
        };
    }

    /// Creates a plane from three points
    /// Calculated via a cross product between (point1-point2)x(point2-point3)
    pub fn initFromTriangle(v0: Vector3, v1: Vector3, v2: Vector3) Plane {
        const norm: Vector3 = v0.subtract(v1).cross(v1.subtract(v2)).norm();
        const d: f32 = -v0.dot(norm);

        return Plane{
            .normal = norm,
            .d = d,
        };
    }

    /// Returns the shortest distance between the plane and the point
    pub fn distanceToPoint(self: *const Plane, point: Vector3) f32 {
        return self.normal.dot(point) + self.d;
    }

    /// Returns which side of the plane this point is on
    pub fn testPoint(self: *const Plane, point: Vector3) PlaneFacing {
        const distance = self.distanceToPoint(point);

        if (distance == 0) {
            return .ON_PLANE;
        } else if (distance < 0) {
            return .BACK;
        } else {
            return .FRONT;
        }
    }

    /// Returns which side of the plane this bounding box is on, or ON_PLANE for intersections
    pub fn testBoundingBox(self: *const Plane, bounds: boundingbox.BoundingBox) PlaneFacing {
        var facing: ?PlaneFacing = null;

        for (bounds.getCorners()) |point| {
            const distance = self.distanceToPoint(point);

            var this_facing: PlaneFacing = undefined;
            if (distance == 0) {
                this_facing = .ON_PLANE;
            } else if (distance < 0) {
                this_facing = .BACK;
            } else {
                this_facing = .FRONT;
            }

            if (facing == null) {
                facing = this_facing;
            } else if (facing != this_facing) {
                // facing changed, we must be intersecting!
                return .ON_PLANE;
            }
        }

        return facing.?;
    }

    /// If direction is a camera direction, this returns true if the front of the plane would be
    /// visible from the camera.
    pub fn facesDirection(self: *const Plane, direction: Vector3) bool {
        return self.normal.dot(direction) <= 0;
    }

    /// Returns an intersection point if a line crosses a plane
    pub fn intersectLine(self: *const Plane, start: Vector3, end: Vector3) ?Vector3 {
        const dir = end.subtract(start);
        const denom = dir.dot(self.normal);

        if (denom == 0)
            return null;

        const t = -(start.dot(self.normal) + self.d) / denom;
        if (t < 0 or t > 1)
            return null;

        return start.add(dir.scale(t));
    }

    /// Returns an intersection point if a ray crosses a plane
    pub fn intersectRay(self: *const Plane, start: Vector3, dir: Vector3) ?Vector3 {
        var norm_dir = dir.norm();
        const denom = norm_dir.dot(self.normal);

        if (denom == 0)
            return null;

        const t = -(start.dot(self.normal) + self.d) / denom;

        // ignore intersections behind the ray
        if (t < 0)
            return null;

        return start.add(norm_dir.scale(t));
    }

    /// Returns the intersection point of three non-parallel planes
    /// From the Celeste64 source
    pub fn planeIntersectPoint(a: Plane, b: Plane, c: Plane) Vector3 {
        // Formula used
        //                d1 ( N2 * N3 ) + d2 ( N3 * N1 ) + d3 ( N1 * N2 )
        //P =   -------------------------------------------------------------------------
        //                             N1 . ( N2 * N3 )
        //
        // Note: N refers to the normal, d refers to the displacement. '.' means dot product. '*' means cross product

        const f = -a.normal.dot(b.normal.cross(c.normal));
        const v1 = b.normal.cross(c.normal).scale(a.d);
        const v2 = c.normal.cross(a.normal).scale(b.d);
        const v3 = a.normal.cross(b.normal).scale(c.d);

        // (v1 + v2 + v3) / f
        const ret = v1.add(v2).add(v3);
        return ret.scale(1.0 / f);
    }

    pub fn normalize(self: *const Plane) Plane {
        var ret = self.*;
        const scale = 1.0 / self.normal.length();

        // normalize the normal, and adjust d the same amount
        ret.normal = ret.normal.norm();
        ret.d *= scale;

        return ret;
    }

    pub fn mulMat4(self: *const Plane, transform: math.Mat4) Plane {
        const origin = self.normal.scale(self.d);
        const along = origin.add(self.normal);

        // get a transformed origin and point down the plane normal direction
        const origin_trans = origin.mulMat4(transform);
        const along_trans = along.mulMat4(transform);

        // make the new normal based on the new direction
        const normal = along_trans.subtract(origin_trans).norm();

        return Plane.init(normal, origin_trans.scale(-1));
    }
};

test "Plane.distanceToPoint" {
    const plane = Plane.init(Vector3.new(0, 1, 0), Vector3.new(0, 10, 0));

    assert(plane.testPoint(Vector3.new(0, 10, 0)) == .ON_PLANE);
    assert(plane.distanceToPoint(Vector3.new(0, 15, 0)) == 5);
    assert(plane.distanceToPoint(Vector3.new(110, 15, 2000)) == 5);
    assert(plane.distanceToPoint(Vector3.new(110, 5, 2000)) == -5);
}

test "Plane.testPoint" {
    const plane = Plane.init(Vector3.new(0, 0, 1), Vector3.new(0, 10, 5));

    assert(plane.testPoint(Vector3.new(0, 10, 5)) == .ON_PLANE);
    assert(plane.testPoint(Vector3.new(0, 10, 7)) == .FRONT);
    assert(plane.testPoint(Vector3.new(0, 10, -5)) == .BACK);
}

test "Plane.testBoundingBox" {
    const plane = Plane.init(Vector3.new(0, 0, 1), Vector3.new(0, 0, 0));

    // intersects
    const bounds1 = boundingbox.BoundingBox.init(Vector3.new(0, 0, 0), Vector3.new(2, 2, 2));
    assert(plane.testBoundingBox(bounds1) == .ON_PLANE);

    // in front
    const bounds2 = boundingbox.BoundingBox.init(Vector3.new(0, 0, 8), Vector3.new(2, 2, 2));
    assert(plane.testBoundingBox(bounds2) == .FRONT);

    // behind
    const bounds3 = boundingbox.BoundingBox.init(Vector3.new(0, 0, -8), Vector3.new(2, 2, 2));
    assert(plane.testBoundingBox(bounds3) == .BACK);
}

test "Plane.facesDirection" {
    const plane = Plane.init(Vector3.new(0, 0, 1), Vector3.new(0, 0, 0));

    assert(plane.facesDirection(Vector3.new(0, 0, 1)) == false);
    assert(plane.facesDirection(Vector3.new(0, 0, -1)) == true);
}

test "Plane.intersectLine" {
    const plane = Plane.init(Vector3.new(0, 0, 1), Vector3.new(0, 0, 5));

    assert(plane.intersectLine(Vector3.new(0, 0, 0), Vector3.new(10, 0, 0)) == null);
    assert(plane.intersectLine(Vector3.new(0, 0, -5), Vector3.new(10, 0, 10)) != null);
    assert(std.meta.eql(plane.intersectLine(Vector3.new(0, 0, -5), Vector3.new(0, 0, 15)).?, Vector3.new(0, 0, 5)));
}

test "Plane.intersectRay" {
    const plane = Plane.init(Vector3.new(0, 0, 1), Vector3.new(0, 0, 5));

    assert(plane.intersectRay(Vector3.new(0, 0, 0), Vector3.new(0, 1, 0)) == null);
    assert(std.meta.eql(plane.intersectRay(Vector3.new(0, 0, 0), Vector3.new(0, 0, 1)), Vector3.new(0, 0, 5)));
    assert(plane.intersectRay(Vector3.new(0, 0, 0), Vector3.new(0, 0, -1)) == null);
    assert(std.meta.eql(plane.intersectRay(Vector3.new(0, 0, 10), Vector3.new(0, 0, -1)), Vector3.new(0, 0, 5)));
}

test "Plane.planeIntersectPoint" {
    const plane1 = Plane.init(Vector3.new(0, 0, 1), Vector3.new(1, 0, 5));
    const plane2 = Plane.init(Vector3.new(1, 0, 0), Vector3.new(1, 1, 5));
    const plane3 = Plane.init(Vector3.new(0, 1, 0), Vector3.new(0, 4, 5));

    const intersect = Plane.planeIntersectPoint(plane1, plane2, plane3);
    assert(intersect.x == 1);
    assert(intersect.y == 4);
    assert(intersect.z == 5);
}

test "Plane.mulMat4" {
    const plane = Plane.init(Vector3.new(0, 0, 1), Vector3.new(1, 1, 1));

    // multiplying by the fromIdentity should result in an identical plane
    const t1 = plane.mulMat4(math.Mat4.fromIdentity);
    assert(std.meta.eql(plane, t1));

    // scaling should keep the normal, but increase the distance
    const t2 = plane.mulMat4(math.Mat4.scale(Vector3.new(2, 2, 2)));
    assert(std.meta.eql(plane.normal, t2.normal));
    assert(t2.d == plane.d * 2);

    // translating should also just change the distance
    const t3 = plane.mulMat4(math.Mat4.translate(Vector3.new(1, 1, 1)));
    assert(std.meta.eql(plane.normal, t3.normal));
    assert(t3.d == 0);

    // rotating should just change the normal
    const t4 = plane.mulMat4(math.Mat4.rotate(45, Vector3.new(1, 1, 1)));
    assert(t4.d == plane.d);
}
