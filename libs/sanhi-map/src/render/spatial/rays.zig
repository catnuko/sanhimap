const std = @import("std");
const math = @import("../math.zig");
const debug = @import("../debug.zig");
const assert = std.debug.assert;

const Vector3 = math.Vector3;
const Plane = @import("plane.zig").Plane;
const BoundingBox = @import("boundingbox.zig").BoundingBox;
const OrientedBoundingBox = @import("orientedboundingbox.zig").OrientedBoundingBox;

pub const RayIntersection = struct {
    hit_pos: Vector3,
    normal: Vector3,
};

pub const Ray = struct {
    pos: Vector3,
    dir: Vector3,

    /// Creates a new ray based on a start position and direction
    pub fn init(position: Vector3, direction: Vector3) Ray {
        return Ray{
            .pos = position,
            .dir = direction,
        };
    }

    /// Returns an intersection point if a ray crosses a plane
    pub fn intersectPlane(self: *const Ray, plane: Plane, ignore_backfacing: bool) ?RayIntersection {
        const denom = self.dir.dot(plane.normal);

        if (denom == 0)
            return null;

        if (ignore_backfacing and denom > 0)
            return null;

        const t = -(self.pos.dot(plane.normal) + plane.d) / denom;

        // ignore intersections behind the ray
        if (t < 0)
            return null;

        return .{ .hit_pos = self.pos.add(self.dir.scale(t)), .normal = plane.normal };
    }

    /// Returns an intersection point if a ray crosses an axis aligned bounding box
    pub fn intersectBoundingBox(self: *const Ray, bounds: BoundingBox) ?RayIntersection {
        if (bounds.contains(self.pos)) {
            return .{ .hit_pos = self.pos, .normal = self.dir.scale(-1) };
        }

        // Find the first intersection point.
        // Since we're ignoring backfaces and clipping the plane, we don't have to check for the closest hit.
        const planes = bounds.getPlanes();

        // +X and -X
        for (0..2) |idx| {
            const p = planes[idx];
            const intersection = self.intersectPlane(p, true);
            if (intersection) |i| {
                const h = i.hit_pos;
                if (h.y <= bounds.max.y and h.y >= bounds.min.y and h.z <= bounds.max.z and h.z >= bounds.min.z) {
                    return .{ .hit_pos = h, .normal = p.normal };
                }
            }
        }

        // +Y and -Y
        for (2..4) |idx| {
            const p = planes[idx];
            const intersection = self.intersectPlane(p, true);
            if (intersection) |i| {
                const h = i.hit_pos;
                if (h.x <= bounds.max.x and h.x >= bounds.min.x and h.z <= bounds.max.z and h.z >= bounds.min.z) {
                    return .{ .hit_pos = h, .normal = p.normal };
                }
            }
        }

        // +Z and -Z
        for (4..6) |idx| {
            const p = planes[idx];
            const intersection = self.intersectPlane(p, true);
            if (intersection) |i| {
                const h = i.hit_pos;
                if (h.y <= bounds.max.y and h.y >= bounds.min.y and h.x <= bounds.max.x and h.x >= bounds.min.x) {
                    return .{ .hit_pos = h, .normal = p.normal };
                }
            }
        }

        return null;
    }

    /// Returns an intersection point if a ray crosses an axis aligned bounding box
    pub fn intersectOrientedBoundingBox(self: *const Ray, bounds: OrientedBoundingBox) ?RayIntersection {
        if (bounds.contains(self.pos)) {
            return .{ .hit_pos = self.pos, .normal = self.dir.scale(-1) };
        }

        // we should probably be caching this in the oriented bounding box
        const inv_transform = bounds.transform.invert();

        // get a point pointing down our direction
        const downrange = self.pos.add(self.dir);

        // get our inverted start and direction vectors
        const inv_start = self.pos.mulMat4(inv_transform);
        const inv_dir = downrange.mulMat4(inv_transform).subtract(inv_start).norm();

        // Make a ray that is the inverse of ourselves
        const inv_ray = Ray.init(inv_start, inv_dir);

        // Find the first intersection point.
        // Since we're ignoring backfaces and clipping the plane, we don't have to check for the closest hit.
        const planes = bounds.getUntransformedPlanes();

        // +X and -X
        for (0..2) |idx| {
            const p = planes[idx];
            const intersection = inv_ray.intersectPlane(p, true);
            if (intersection) |i| {
                const h = i.hit_pos;
                if (h.y <= bounds.max.y and h.y >= bounds.min.y and h.z <= bounds.max.z and h.z >= bounds.min.z) {
                    return .{ .hit_pos = h.mulMat4(bounds.transform), .normal = p.normal };
                }
            }
        }

        // +Y and -Y
        for (2..4) |idx| {
            const p = planes[idx];
            const intersection = inv_ray.intersectPlane(p, true);
            if (intersection) |i| {
                const h = i.hit_pos;
                if (h.x <= bounds.max.x and h.x >= bounds.min.x and h.z <= bounds.max.z and h.z >= bounds.min.z) {
                    return .{ .hit_pos = h.mulMat4(bounds.transform), .normal = p.normal };
                }
            }
        }

        // +Z and -Z
        for (4..6) |idx| {
            const p = planes[idx];
            const intersection = inv_ray.intersectPlane(p, true);
            if (intersection) |i| {
                const h = i.hit_pos;
                if (h.y <= bounds.max.y and h.y >= bounds.min.y and h.x <= bounds.max.x and h.x >= bounds.min.x) {
                    return .{ .hit_pos = h.mulMat4(bounds.transform), .normal = p.normal };
                }
            }
        }

        return null;
    }
};

test "Ray.intersectPlane" {
    const plane = Plane.init(Vector3.new(0, 0, 1), Vector3.new(0, 0, 5));

    const hit0 = Ray.init(Vector3.new(0, 0, 0), Vector3.new(0, 1, 0)).intersectPlane(plane, false);
    const hit1 = Ray.init(Vector3.new(0, 0, 0), Vector3.new(0, 0, 1)).intersectPlane(plane, false);
    const hit2 = Ray.init(Vector3.new(0, 0, 0), Vector3.new(0, 0, -1)).intersectPlane(plane, false);
    const hit3 = Ray.init(Vector3.new(0, 0, 10), Vector3.new(0, 0, -1)).intersectPlane(plane, false);

    assert(hit0 == null);
    assert(std.meta.eql(hit1.?.hit_pos, Vector3.new(0, 0, 5)));
    assert(hit2 == null);
    assert(std.meta.eql(hit3.?.hit_pos, Vector3.new(0, 0, 5)));
}

test "Ray.intersectBoundingBox" {
    const ray = Ray.init(Vector3.new(0, 2, 0), Vector3.x_axis);
    const box = BoundingBox.init(Vector3.new(10, 0, 0), Vector3.new(2, 4, 2));

    const hit = ray.intersectBoundingBox(box);
    assert(hit != null);
    assert(std.meta.eql(hit.?.hit_pos, Vector3.new(9.0, 2.0, 0.0)));
    assert(std.meta.eql(hit.?.normal, Vector3.new(-1.0, 0.0, 0.0)));
}

test "Ray.intersectOrientedBoundingBox" {
    const ray = Ray.init(Vector3.new(0, 2, 0), Vector3.x_axis);
    const box = OrientedBoundingBox.init(Vector3.new(10, 0, 0), Vector3.new(2, 4, 2), math.Mat4.fromIdentity);

    const hit = ray.intersectOrientedBoundingBox(box);
    assert(hit != null);
    assert(std.meta.eql(hit.?.hit_pos, Vector3.new(9.0, 2.0, 0.0)));
    assert(std.meta.eql(hit.?.normal, Vector3.new(-1.0, 0.0, 0.0)));
}
