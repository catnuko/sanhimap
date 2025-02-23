const std = @import("std");
const shm = @import("../lib.zig");
const sanhi = @import("sanhi");
const wgpu = sanhi.wgpu;
const Mesh = sanhi.mesh.Mesh;
const Material = sanhi.mesh.Material;
const GeometryBuilder = sanhi.mesh.GeometryBuilder;
const AttributeData = sanhi.mesh.AttributeData;
const DataSourceImpl = shm.datasource.DataSource;
const tiling = shm.tiling;
const FeatureId = shm.datasource.FeatureId;
const Value = shm.datasource.Value;
const ValueMap = shm.datasource.ValueMap;
const proj = shm.projection;
const TileKey = shm.tiling.TileKey;
const modifier = @import("../modifier/index.zig");

pub fn DataSourceShared(comptime Self: type) type {
    return struct {
        pub inline fn name(self: Self) []const u8 {
            return self.dataSource.name;
        }
        pub inline fn projection(self: *const Self) *const Self.DataSource.Projection {
            return self.dataSource.projection();
        }
        pub inline fn tilingScheme(self: *const Self) *const Self.TilingScheme {
            return &self.dataSource.tilingScheme;
        }
        pub inline fn getFeatureState(self: *const Self, featureId: FeatureId) ?ValueMap {
            return self.dataSource.getFeatureState(featureId);
        }
        pub inline fn clearFeatureState(self: *Self) void {
            return self.dataSource.clearFeatureState();
        }
        pub inline fn setFeatureState(self: *Self, featureId: FeatureId, state: ValueMap) void {
            return self.dataSource.setFeatureState(featureId, state);
        }
        pub inline fn removeFeatureState(self: *Self, featureId: FeatureId) void {
            return self.dataSource.removeFeatureState(featureId);
        }
        pub inline fn setStyleName(self: *Self, styleSetName: []u8) void {
            return self.dataSource.setStyleName(styleSetName);
        }
    };
}
pub fn BackgroundDataSource(comptime TilingScheme: type) type {
    return struct {
        const Self = @This();
        pub const DataSource = DataSourceImpl(TilingScheme);
        pub const Projection = DataSource.Projection;
        pub const Map = DataSource.Map;
        pub const Tile = tiling.Tile(Self);

        dataSource: DataSource,
        pub fn new(allocator: std.mem.Allocator, tilingSchemev: TilingScheme) Self {
            var dataSource = DataSource.new(DataSource.Options{
                .name = "BackgroundDataSource",
                .tilingScheme = tilingSchemev,
                .allocator = allocator,
            });
            dataSource.enablePicking = false;
            dataSource.cacheable = true;
            dataSource.addGroundPlane = true;
            return .{
                .dataSource = dataSource,
            };
        }

        const Shared = DataSourceShared(Self);
        pub const name = Shared.name;
        pub const projection = Shared.projection;
        pub const tilingScheme = Shared.tilingScheme;
        pub const getFeatureState = Shared.getFeatureState;
        pub const clearFeatureState = Shared.clearFeatureState;
        pub const setFeatureState = Shared.setFeatureState;
        pub const removeFeatureState = Shared.removeFeatureState;
        pub const setStyleName = Shared.setStyleName;

        pub fn getTile(self: *const Self, tileKey: *const TileKey) ?Tile {
            var tile = Tile.new(&self.dataSource, tileKey);
            tile.forceHasGeometry = true;
            return tile;
        }
        pub fn deinit(self: *Self) void {
            self.dataSource.deinit();
        }
    };
}
const DefaultBackgroundDataSource = BackgroundDataSource(tiling.TilingScheme(proj.WebMercatorProjection));
pub fn createGroundPlane(
    allocator: std.mem.Allocator,
    tile: *const DefaultBackgroundDataSource.Tile,
    createTexCoords: bool,
    receiveShadow: bool,
    material: Material,
    createMultiLod: bool,
    opacity: f64,
) *Mesh {
    const source_projection = tile.projection();
    const shouldSubdivide = source_projection.getType() == .Spherical;
    const useLocalTargetCoords = !shouldSubdivide;
    const geometry_builder = createGroundPlaneGeometry(allocator, tile, useLocalTargetCoords, createTexCoords, receiveShadow);
    if (!shouldSubdivide) {
        return Mesh.new(geometry_builder.finish(), material);
    }
    const geometries = std.ArrayList(GeometryBuilder).init(allocator) catch unreachable;
    // const sphericalModifier =
    const sphericalModifier = modifier.SphericalGeometrySubdivisionModifier(DefaultBackgroundDataSource.Projection, std.math.degreesToRadians(10), source_projection);
    if (!createMultiLod) {
        sphericalModifier.modify(allocator, geometry_builder);

        return Mesh.new(geometry_builder.finish(), material);
    }
}
pub fn toLocalTargetCoords(geometry_builder: *GeometryBuilder, comptime CTile: type, src_projection: CTile.Projection, tile: CTile) void {
    var position = if (geometry_builder.getAttribute("position")) |position_attr| position_attr.data.float32x3 orelse unreachable;
    
}
pub fn createGroundPlaneGeometry(
    allocator: std.mem.Allocator,
    tile: *const DefaultBackgroundDataSource.Tile,
    useLocalTargetCoords: bool,
    createTexCoords: bool,
    receiveShadow: bool,
) *GeometryBuilder {
    const geometry_builder = GeometryBuilder.new();
    const corners = tiling.projectTilePlaneCorners(DefaultBackgroundDataSource.Tile, tile);
    if (useLocalTargetCoords) {
        corners.sw = corners.sw.subtract(tile.center());
        corners.se = corners.se.subtract(tile.center());
        corners.nw = corners.nw.subtract(tile.center());
        corners.ne = corners.ne.subtract(tile.center());
    }
    const positions = std.ArrayList([3]f64).initCapacity(allocator, 4) catch unreachable;
    positions.appendSliceAssumeCapacity(.{ corners.sw.toArray(), corners.se.toArray(), corners.nw.toArray(), corners.ne.toArray() });
    geometry_builder.setAttribute("position", AttributeData{ .float32x3 = positions });
    if (receiveShadow) {
        const source_projection = tile.projection();
        const tmpv = source_projection.surfaceNormal(&corners.sw).negate();
        const normals = std.ArrayList([3]f64).initCapacity(allocator, 4) catch unreachable;
        normals.appendSliceAssumeCapacity(.{ tmpv.toArray(), tmpv.toArray(), tmpv.toArray(), tmpv.toArray() });
        geometry_builder.setAttribute("normal", .{ .float32x3 = normals });
    }
    geometry_builder.setIndexBySlice(&.{ 0, 1, 2, 2, 1, 3 });
    if (createTexCoords) {
        geometry_builder.setAttributeBySlice("uv", [3]f32, &.{ 0, 0, 1, 0, 0, 1, 1, 1 });
    }
    return geometry_builder;
}
// fn createGroundPlaneGeometry(tile: Tile, useLocalTargetCoords: bool, createTexCoords: bool) void {}
test "BackgroundDataSource" {
    const testing = @import("std").testing;
    const backgroundDataSource = DefaultBackgroundDataSource.new(
        testing.allocator,
        shm.tiling.webMercatorTilingScheme,
    );
    try testing.expectEqual(backgroundDataSource.name(), "BackgroundDataSource");
}
