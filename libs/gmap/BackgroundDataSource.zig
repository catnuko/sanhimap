const lib = @import("lib.zig");

pub const BackgroundDataSource = struct {
    const Self = @This();
    m_tilingScheme: lib.TilingScheme,
    dataSourceI: lib.DataSource,
    const DEFAULT_TILING_SCHEME: lib.TilingScheme = lib.getWebMercatorTilingScheme();
    pub fn new() Self {
        var dataSourceI = lib.DataSource.new("BackgroundDataSource");
        dataSourceI.enablePicking = false;
        dataSourceI.cacheable = true;
        dataSourceI.addGroundPlane = true;
        var self = .{
            .dataSourceI = dataSourceI,
            .m_tilingScheme = DEFAULT_TILING_SCHEME,
        };
        //implement DataSource interface
        dataSourceI.ptr = &self;
        dataSourceI.vtable = &.{
            .getTilingScheme = getTilingScheme,
            .getTile = getTile,
        };
        return self;
    }
    pub inline fn getName(self: Self) []const u8 {
        return self.dataSourceI.name;
    }
    pub fn setTilingScheme(self: *Self, tilingScheme: ?lib.TilingScheme) void {
        const news = tilingScheme orelse DEFAULT_TILING_SCHEME;
        if (&news == &self.m_tilingScheme) {
            return;
        }
        self.m_tilingScheme = news;
    }
    pub fn getTilingScheme(ctx: *anyopaque) lib.TilingScheme {
        const self: *Self = @ptrCast(@alignCast(ctx));
        return self.m_tilingScheme;
    }
    pub fn getTile(ctx: *anyopaque, tileKey: lib.TileKey) ?lib.Tile {
        const self: *Self = @ptrCast(@alignCast(ctx));
        var tile = lib.Tile.new(&self.dataSourceI, tileKey);
        tile.forceHasGeometry = true;
        return tile;
    }
};
// fn createGroundPlaneGeometry(tile: Tile, useLocalTargetCoords: bool, createTexCoords: bool) void {}
test "BackgroundDataSource" {
    var b = BackgroundDataSource.new();
    const debug = @import("std").debug;
    const TilingScehmeT = @TypeOf(b.dataSourceI.getTilingScheme());
    debug.print("TilingScehmeT is {}\n", .{TilingScehmeT});
    const testing = @import("std").testing;
    try testing.expectEqual(b.getName(), "BackgroundDataSource");
}
