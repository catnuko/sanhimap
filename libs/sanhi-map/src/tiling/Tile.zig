const math = @import("../math.zig");
const TileKey = @import("./TileKey.zig");
const GeoBox = @import("../GeoBox.zig").GeoBox;
const OBB = @import("../OBB.zig").OBB;
pub fn Tile(comptime DataSourceImpl: type) type {
    return struct {
        const Self = @This();
        pub const DataSource = DataSourceImpl;
        pub const Projection = DataSource.Projection;
        dataSource: *const DataSource,
        tileKey: TileKey,
        geoBox: GeoBox,
        boundingBox: OBB,
        forceHasGeometry: bool = false,
        localTangentSpace: bool = false,
        maxGeometryHeight: f64,
        minGeometryHeight: f64,
        uniqueKey: usize,
        // offset: f64,
        // frameNumLastRequested: usize = -1,
        // frameNumVisible: usize = -1,
        // frameNumLastVisible: usize = -1,
        // numFramesVisible: usize = -1,
        // visibilityCounter: usize = -1,
        pub fn new(
            dataSource: *const DataSource,
            tileKey: TileKey,
        ) Self {
            var self = .{
                .geoBox = dataSource.tilingScheme().getGeoBox(&tileKey),
                .tileKey = tileKey,
                .dataSource = dataSource,
            };
            self.updateBoundingBox();
            return self;
        }
        pub inline fn center(self: *const Self) *const math.Vec3 {
            return &self.boundingBox.center;
        }
        pub inline fn projection(self: *const Self) *const DataSource.Projection {
            return self.dataSource.projection();
        }
        pub inline fn map(self: *const Self) *const DataSource.Map {
            return self.dataSource.map();
        }
        pub fn updateBoundingBox(self: *Self) void {
            self.boundingBox = self.projection().projectBox(&self.geoBox, OBB);
        }
    };
}
