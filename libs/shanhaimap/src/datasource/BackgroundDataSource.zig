const Allocator = @import("std").mem.Allocator;
const shm = @import("../root.zig");
const DataSourceImpl = shm.datasource.DataSource;
const tiling = shm.tiling;
const FeatureId = shm.datasource.FeatureId;
const Value = shm.datasource.Value;
const ValueMap = shm.datasource.ValueMap;
const proj = shm.projection;
const TileKey = shm.tiling.TileKey;
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
        pub fn new(allocator: Allocator, tilingSchemev: TilingScheme) Self {
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
pub fn createGroundPlaneGeometry(
    tile: *const DefaultBackgroundDataSource.Tile,
    useLocalTargetCoords: bool,
    createTexCoords: bool,
    receiveShadow: bool,
) void {
    const corners = tiling.projectTilePlaneCorners(DefaultBackgroundDataSource.Tile, tile);
    if (useLocalTargetCoords) {
        corners.sw = corners.sw.sub(tile.center());
        corners.se = corners.se.sub(tile.center());
        corners.nw = corners.nw.sub(tile.center());
        corners.ne = corners.ne.sub(tile.center());
    }
    if (receiveShadow) {}
    if (createTexCoords) {}
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
