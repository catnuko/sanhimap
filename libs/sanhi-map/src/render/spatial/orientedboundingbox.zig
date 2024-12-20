const std = @import("std");
const math = @import("../math.zig");
const debug = @import("../debug.zig");
const graphics = @import("../platform/graphics.zig");
const plane = @import("plane.zig");
const assert = std.debug.assert;

const Vector3 = math.Vector3;
const Mat4 = math.Mat4;
const Plane = plane.Plane;
const BoundingBox = @import("boundingbox.zig").BoundingBox;

// Using the implementation from https://www.jkh.me/files/tutorials/Separating%20Axis%20Theorem%20for%20Oriented%20Bounding%20Boxes.pdf

/// A bounding box oriented using a transform matrix
pub const OrientedBoundingBox = struct {
    min: Vector3,
    max: Vector3,
    center: Vector3,
    transform: Mat4 = math.Mat4.fromIdentity,

    // transformed axes and vertex positions will get cached on update
    vertices: [8]Vector3 = undefined,
    axes: [3]Vector3 = undefined,

    /// Creates a new bounding box based on a position and size
    pub fn init(position: Vector3, size: Vector3, transform_matrix: Mat4) OrientedBoundingBox {
        const half_size = size.scale(0.5);
        var ret = OrientedBoundingBox{
            .center = position,
            .min = position.subtract(half_size),
            .max = position.add(half_size),
            .transform = transform_matrix,
        };

        ret.update();
        return ret;
    }

    /// Caches the vertices and axes
    pub fn update(self: *OrientedBoundingBox) void {
        self.vertices = self.getCorners();
        self.axes = self.getAxes();
    }

    /// Scale this bounding box
    pub fn scale(self: *const OrientedBoundingBox, scale_by: f32) OrientedBoundingBox {
        var ret = self.*;
        ret.min = ret.min.scale(scale_by);
        ret.max = ret.max.scale(scale_by);
        ret.update();
        return ret;
    }

    /// Translate this bounding box
    pub fn translate(self: *const OrientedBoundingBox, move_by: Vector3) OrientedBoundingBox {
        var ret = self.*;
        ret.center = ret.center.add(move_by);
        ret.min = ret.min.add(move_by);
        ret.max = ret.max.add(move_by);
        ret.update();
        return ret;
    }

    /// Increase the size of this bounding box
    pub fn inflate(self: *const OrientedBoundingBox, amount: f32) OrientedBoundingBox {
        const increase_by = Vector3.new(amount, amount, amount);

        var ret = self.*;
        ret.min = ret.min.subtract(increase_by);
        ret.max = ret.max.add(increase_by);
        ret.update();
        return ret;
    }

    /// Transforms this bounding box by a matrix
    pub fn transform(self: *const OrientedBoundingBox, transform_mat: math.Mat4) OrientedBoundingBox {
        var ret = self.*;
        ret.transform = self.transform.multiply(transform_mat);
        ret.update();
        return ret;
    }

    /// Checks if two oriented bounding boxes overlap
    pub fn intersectsOBB(self: *const OrientedBoundingBox, other: OrientedBoundingBox) bool {
        const a_axes: [3]Vector3 = self.axes;
        const b_axes: [3]Vector3 = other.axes;

        const all_axes: [15]Vector3 = [_]Vector3{
            a_axes[0],
            a_axes[1],
            a_axes[2],
            b_axes[0],
            b_axes[1],
            b_axes[2],
            a_axes[0].cross(b_axes[0]),
            a_axes[0].cross(b_axes[1]),
            a_axes[0].cross(b_axes[2]),
            a_axes[1].cross(b_axes[0]),
            a_axes[1].cross(b_axes[1]),
            a_axes[1].cross(b_axes[2]),
            a_axes[2].cross(b_axes[0]),
            a_axes[2].cross(b_axes[1]),
            a_axes[2].cross(b_axes[2]),
        };

        var a_corners = self.vertices;
        var b_corners = other.vertices;

        return intersects(&all_axes, &a_corners, &b_corners);
    }

    pub fn intersectsAABB(self: *const OrientedBoundingBox, other: BoundingBox) bool {
        const a_axes: [3]Vector3 = self.axes;
        const b_axes: [3]Vector3 = [3]Vector3{ Vector3.x_axis, Vector3.y_axis, Vector3.z_axis };

        const all_axes: [15]Vector3 = [_]Vector3{
            a_axes[0],
            a_axes[1],
            a_axes[2],
            b_axes[0],
            b_axes[1],
            b_axes[2],
            a_axes[0].cross(b_axes[0]),
            a_axes[0].cross(b_axes[1]),
            a_axes[0].cross(b_axes[2]),
            a_axes[1].cross(b_axes[0]),
            a_axes[1].cross(b_axes[1]),
            a_axes[1].cross(b_axes[2]),
            a_axes[2].cross(b_axes[0]),
            a_axes[2].cross(b_axes[1]),
            a_axes[2].cross(b_axes[2]),
        };

        var a_corners = self.vertices;
        var b_corners = other.getCorners();

        return intersects(&all_axes, &a_corners, &b_corners);
    }

    /// Checks if two geometries are intersecting, using the seperating axes theorem.
    fn intersects(check_axes: []const Vector3, a_vertices: []const Vector3, b_vertices: []const Vector3) bool {
        for (check_axes) |axis| {
            var min_a: f32 = std.math.floatMax(f32);
            var max_a: f32 = -std.math.floatMax(f32);

            // project shape A on an axis
            for (a_vertices) |vert| {
                const p = vert.dot(axis);
                min_a = @min(min_a, p);
                max_a = @max(max_a, p);
            }

            var min_b: f32 = std.math.floatMax(f32);
            var max_b: f32 = -std.math.floatMax(f32);

            // project shape A on an axis
            for (b_vertices) |vert| {
                const p = vert.dot(axis);
                min_b = @min(min_b, p);
                max_b = @max(max_b, p);
            }

            if (max_a < min_b or max_b < min_a) {
                // found a separating axis, so not intersecting
                return false;
            }
        }

        // found no separating axes, so these shapes must be overlapping!
        return true;
    }

    /// Returns locations of all the corners
    pub fn getCorners(self: *const OrientedBoundingBox) [8]Vector3 {
        return [8]Vector3{
            Vector3.new(self.min.x, self.max.y, self.min.z).mulMat4(self.transform),
            Vector3.new(self.max.x, self.max.y, self.max.z).mulMat4(self.transform),
            Vector3.new(self.max.x, self.max.y, self.min.z).mulMat4(self.transform),
            Vector3.new(self.min.x, self.max.y, self.max.z).mulMat4(self.transform),
            Vector3.new(self.min.x, self.min.y, self.min.z).mulMat4(self.transform),
            Vector3.new(self.max.x, self.min.y, self.max.z).mulMat4(self.transform),
            Vector3.new(self.max.x, self.min.y, self.min.z).mulMat4(self.transform),
            Vector3.new(self.min.x, self.min.y, self.max.z).mulMat4(self.transform),
        };
    }

    /// Gets our planes, transformed by our orientation
    pub fn getPlanes(self: *const OrientedBoundingBox) [6]Plane {
        const axes = self.getAxes();
        return [6]Plane{
            Plane.init(axes[0], Vector3.new(self.max.x, self.center.y, self.center.z).mulMat4(self.transform)),
            Plane.init(axes[0].scale(-1.0), Vector3.new(self.min.x, self.center.y, self.center.z).mulMat4(self.transform)),
            Plane.init(axes[1], Vector3.new(self.center.x, self.max.y, self.center.z).mulMat4(self.transform)),
            Plane.init(axes[1].scale(-1.0), Vector3.new(self.center.x, self.min.y, self.center.z).mulMat4(self.transform)),
            Plane.init(axes[2], Vector3.new(self.center.x, self.center.y, self.max.z).mulMat4(self.transform)),
            Plane.init(axes[2].scale(-1.0), Vector3.new(self.center.x, self.center.y, self.min.z).mulMat4(self.transform)),
        };
    }

    /// Gets the planes, but unoriented
    pub fn getUntransformedPlanes(self: *const OrientedBoundingBox) [6]Plane {
        return [6]Plane{
            Plane.init(Vector3.new(1, 0, 0), Vector3.new(self.max.x, self.center.y, self.center.z)),
            Plane.init(Vector3.new(-1, 0, 0), Vector3.new(self.min.x, self.center.y, self.center.z)),
            Plane.init(Vector3.new(0, 1, 0), Vector3.new(self.center.x, self.max.y, self.center.z)),
            Plane.init(Vector3.new(0, -1, 0), Vector3.new(self.center.x, self.min.y, self.center.z)),
            Plane.init(Vector3.new(0, 0, 1), Vector3.new(self.center.x, self.center.y, self.max.z)),
            Plane.init(Vector3.new(0, 0, -1), Vector3.new(self.center.x, self.center.y, self.min.z)),
        };
    }

    /// Get the X, Y, and Z normals transformed by our transform matrix
    pub fn getAxes(self: *const OrientedBoundingBox) [3]Vector3 {
        return [_]Vector3{
            Vector3.new(self.transform.m[0][0], self.transform.m[0][1], self.transform.m[0][2]).norm(),
            Vector3.new(self.transform.m[1][0], self.transform.m[1][1], self.transform.m[1][2]).norm(),
            Vector3.new(self.transform.m[2][0], self.transform.m[2][1], self.transform.m[2][2]).norm(),
        };
    }

    /// Check to see if this bounding box contains a point
    pub fn contains(self: *const OrientedBoundingBox, point: Vector3) bool {
        const p = point.mulMat4(self.transform.invert());
        return p.x >= self.min.x and p.y >= self.min.y and p.z >= self.min.z and
            p.x <= self.max.x and p.y <= self.max.y and p.z <= self.max.z;
    }

    /// Check to see if this bounding box completely encloses another
    pub fn containsOBB(self: *const OrientedBoundingBox, other: OrientedBoundingBox) bool {
        const inverse_transform = self.transform.invert();
        for (other.vertices) |point| {
            const p = point.mulMat4(inverse_transform);
            const in = p.x >= self.min.x and p.y >= self.min.y and p.z >= self.min.z and
                p.x <= self.max.x and p.y <= self.max.y and p.z <= self.max.z;

            if (!in)
                return false;
        }
        return true;
    }

    pub fn containsAABB(self: *const OrientedBoundingBox, other: BoundingBox) bool {
        const inverse_transform = self.transform.invert();
        for (other.getCorners()) |point| {
            const p = point.mulMat4(inverse_transform);
            const in = p.x >= self.min.x and p.y >= self.min.y and p.z >= self.min.z and
                p.x <= self.max.x and p.y <= self.max.y and p.z <= self.max.z;

            if (!in)
                return false;
        }
        return true;
    }
};
