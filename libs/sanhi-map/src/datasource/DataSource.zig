const mem = @import("std").mem;
const Allocator = mem.Allocator;
const AutoHashMap = @import("std").AutoHashMap;
const StringHashMap = @import("std").StringHashMap;

pub const ExprPool = struct {};
pub const Value = union {};
pub const FeatureId = []u8;
pub const ValueMap = StringHashMap(Value);
const MapIpml = @import("../ui/Map.zig").Map;
const TilingSchemeImpl = @import("../tiling/TilingScheme.zig");
pub fn DataSource(comptime TilingScheme: type) type {
    return struct {
        const Self = @This();
        pub const FeatureStateMap = AutoHashMap(FeatureId, ValueMap);
        pub const Projection = TilingScheme.Projection;
        pub const Map = MapIpml(Projection);
        // pub const TilingScheme = TilingSchemeImpl(Projection);
        pub const Options = struct {
            allocator: Allocator,
            tilingScheme: TilingScheme,
            enabled: ?bool = null,
            name: []const u8,
            minZoomLevel: ?u16 = null,
            maxZoomLevel: ?u16 = null,
            minDisplayLevel: ?u16 = null,
            maxDisplayLevel: ?u16 = null,
            allowOverlappingTiles: ?bool = null,
            enablePicking: ?bool = null,
            dataSourceOrder: ?u16 = null,
            styleSetName: ?[]u8 = null,
            maxGeometryHeight: ?f64 = null,
            minGeometryHeight: ?f64 = null,
            storageLevelOffset: ?f64 = null,
            languages: ?[][]u8 = null,
        };

        const uniqueNameCounter: usize = 0;
        allocator: Allocator,

        enabled: bool = true,
        cacheable: bool = false,
        useGeometryLoader: bool = false,
        name: []const u8,
        addGroundPlane: bool = false,
        minZoomLevel: u16 = 1,
        maxZoomLevel: u16 = 20,
        minDisplayLevel: u16 = 1,
        maxDisplayLevel: u16 = 20,
        allowOverlappingTiles: bool = true,
        enablePicking: bool = true,
        dataSourceOrder: u16 = 0,

        styleSetName: []u8,
        maxGeometryHeight: f64,
        minGeometryHeight: f64,
        storageLevelOffset: f64,
        exprPool: ExprPool,
        featureStateMap: FeatureStateMap,
        languages: [][]u8,

        map: *const Map,
        tilingScheme: TilingScheme,
        pub fn new(options: Options) Self {
            var res: Self = undefined;
            res.allocator = options.allocator;
            res.featureStateMap = FeatureStateMap.init(res.allocator);
            res.tilingScheme = options.tilingScheme;
            res.name = options.name;
            if (options.enabled) |v| {
                res.enabled = v;
            }
            if (options.minZoomLevel) |v| {
                res.minZoomLevel = v;
            }
            if (options.maxZoomLevel) |v| {
                res.maxZoomLevel = v;
            }
            if (options.minDisplayLevel) |v| {
                res.minDisplayLevel = v;
            }
            if (options.maxDisplayLevel) |v| {
                res.maxDisplayLevel = v;
            }
            if (options.allowOverlappingTiles) |v| {
                res.allowOverlappingTiles = v;
            }
            if (options.enablePicking) |v| {
                res.enablePicking = v;
            }
            if (options.dataSourceOrder) |v| {
                res.dataSourceOrder = v;
            }
            if (options.styleSetName) |v| {
                res.styleSetName = v;
            }
            if (options.maxGeometryHeight) |v| {
                res.maxGeometryHeight = v;
            }
            if (options.minGeometryHeight) |v| {
                res.minGeometryHeight = v;
            }
            if (options.storageLevelOffset) |v| {
                res.storageLevelOffset = v;
            }
            if (options.languages) |v| {
                res.languages = v;
            }
            return res;
        }
        pub fn getFeatureState(self: *const Self, featureId: FeatureId) ?ValueMap {
            return self.featureStateMap.get(featureId);
        }
        pub fn clearFeatureState(self: *Self) void {
            self.featureStateMap.clearAndFree();
        }
        pub fn setFeatureState(self: *Self, featureId: FeatureId, state: ValueMap) void {
            self.featureStateMap.put(featureId, state);
        }
        pub fn removeFeatureState(self: *Self, featureId: FeatureId) void {
            self.featureStateMap.remove(featureId);
        }
        pub fn setStyleName(self: *Self, styleSetName: []u8) void {
            if (!mem.eql(u8, styleSetName, self.styleSetName)) {
                self.styleSetName = styleSetName;
                self.clearCache();
                self.requestUpdate();
            }
        }
        pub fn dispose(self: *Self) void {
            _ = self;
        }
        pub fn clearCache(self: *Self) void {
            _ = self;
        }
        pub fn isFullyCovering(self: *Self) void {
            _ = self;
        }
        pub fn ready(self: *Self) void {
            _ = self;
        }
        pub fn map(self: *Self) void {
            _ = self;
        }
        pub inline fn projection(self: *const Self) *const Projection {
            return self.map.projection;
        }
        pub fn connect(self: *Self) void {
            _ = self;
        }
        pub fn attach(self: *Self) void {
            _ = self;
        }
        pub fn dettach(self: *Self) void {
            _ = self;
        }
        pub fn isDetached(self: *Self) void {
            _ = self;
        }
        pub fn setTheme(self: *Self) void {
            _ = self;
        }
        pub fn setLanguages(self: *Self) void {
            _ = self;
        }
        pub fn setPoliticalView(self: *Self) void {
            _ = self;
        }
        pub fn getTile(self: *Self) void {
            _ = self;
        }
        pub fn updateTile(self: *Self) void {
            _ = self;
        }
        pub fn shouldPreloadTiles(self: *Self) void {
            _ = self;
        }
        pub fn isVisible(self: *Self) void {
            _ = self;
        }
        pub fn canGetTile(self: *Self) void {
            _ = self;
        }
        pub fn shouldSubdivide(self: *Self) void {
            _ = self;
        }
        pub fn shouldRenderText(self: *Self) void {
            _ = self;
        }
        pub fn requestUpdate(self: *Self) void {
            _ = self;
        }
        pub fn deinit(self: *Self) void {
            self.featureStateMap.deinit();
        }
    };
}
