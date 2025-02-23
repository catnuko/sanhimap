const std = @import("std");
const shm = @import("../lib.zig");
const sanhi = @import("sanhi");
const wgpu = sanhi.wgpu;
const Mesh = sanhi.mesh.Mesh;
const Vector3 = sanhi.math.Vector3;
const Material = sanhi.mesh.Material;
const GeometryBuilder = sanhi.mesh.GeometryBuilder;
const AttributeData = sanhi.mesh.AttributeData;
const DataSourceImpl = shm.datasource.DataSource;
const proj = @import("../projection/index.zig");
const sphereProjection = proj.sphereProjection;
const subdivisionModifier = @import("./subdivision_modifier.zig").subdivisionModifier;

pub fn SphericalGeometrySubdivisionModifier(comptime Projection: type,anglev:f64,projectionv:Projection) type {
    const Inner =  struct {
        const projection: Projection = sphereProjection;
        const angle: f64 = 0;
        pub fn spherical_subdivision_modifier(a: *const Vector3, b: *const Vector3, c: *const Vector3) u8 {
            const aa = sphereProjection.reprojectPoint(projection, a);
            const bb = sphereProjection.reprojectPoint(projection, b);
            const cc = sphereProjection.reprojectPoint(projection, c);

            const alpha = aa.angleTo(bb);
            const beta = bb.angleTo(cc);
            const gamma = cc.angleTo(aa);
            const m = @max(alpha, @max(beta, gamma));

            if (m < angle) {
                return 3;
            }
            if (m == alpha) {
                return 0;
            } else if (m == beta) {
                return 1;
            } else if (m == gamma) {
                return 2;
            }
            @panic("failed to split triangle");
        }
        pub fn modify(
            allocator: std.mem.Allocator,
            geometry_builder: *GeometryBuilder,
        ) void {
            return subdivisionModifier(
                allocator,
                geometry_builder,
                spherical_subdivision_modifier,
            );
        }
    };
    Inner.angle = anglev;
    Inner.projection = projectionv;
    return Inner;
}
