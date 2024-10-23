const Allocator = @import("std").mem.Allocator;
const debug = @import("std").debug;
const render = @import("./index.zig");
const graph = render.graph;
const Plugin = render.Plugin;
const ArrayList = @import("std").ArrayList;
const StringHashMap = @import("std").StringHashMap;
const RenderGraph = graph.RenderGraph;
const Node = graph.Node;
pub const GraphManager = struct {
    graph: RenderGraph,
    alloc: Allocator,
    const Self = @This();
    pub fn new(alloc: Allocator) Self {
        return .{
            .alloc = alloc,
            .graph = RenderGraph.new(alloc),
        };
    }
    pub fn getSubGraph(self: *Self, subGraphName: []const u8) *RenderGraph {
        return self.graph.getSubGraph(subGraphName) orelse {
            debug.print("SubGraph {s} not found\n", .{subGraphName});
            unreachable;
        };
    }
    pub fn addNode(self: *Self, subGraphName: []const u8, node: Node) void {
        var subGraph = self.getSubGraph(subGraphName);
        subGraph.addNode(node);
    }
    pub fn addSubGraph(self: *Self, subGraphName: []const u8) void {
        self.graph.addSubGraph(subGraphName, RenderGraph.new(self.alloc));
    }

    pub fn addEdges(self: *Self, subGraphName: []const u8, edges: [][]const u8) void {
        var subGraph = self.getSubGraph(subGraphName);
        subGraph.addNodeEdges(edges);
    }
    pub fn addEdge(self: *Self, subGraphName: []const u8, edge: []const u8) void {
        var subGraph = self.getSubGraph(subGraphName);
        subGraph.addNodeEdge(edge);
    }
    pub fn deinit(self: *Self) void {
        self.graph.deinit();
    }
};
pub const AppError = error{
    DuplicatePlugin,
};
pub const App = struct {
    const Plugins = StringHashMap(Plugin);
    graphManager: GraphManager,
    plugins: Plugins,
    alloc: Allocator,
    const Self = @This();
    pub fn new(alloc: Allocator) Self {
        return .{
            .graphManager = GraphManager.new(alloc),
            .plugins = Plugins.init(alloc),
            .alloc = alloc,
        };
    }
    pub inline fn getSubGraph(self: *Self, subGraphName: []const u8) *RenderGraph {
        return self.graphManager.getSubGraph(subGraphName);
    }
    pub inline fn addNode(self: *Self, subGraphName: []const u8, node: Node) void {
        return self.graphManager.addNode(subGraphName, node);
    }
    pub inline fn addSubGraph(self: *Self, subGraphName: []const u8) void {
        return self.graphManager.addSubGraph(subGraphName);
    }
    pub inline fn addEdges(self: *Self, subGraphName: []const u8, edges: [][]const u8) void {
        return self.graphManager.addEdges(subGraphName, edges);
    }
    pub inline fn addEdge(self: *Self, subGraphName: []const u8, edge: []const u8) void {
        return self.graphManager.addEdge(subGraphName, edge);
    }
    pub fn deinit(self: *Self) void {
        self.graphManager.deinit();
        self.plugins.deinit();
    }
    pub fn addPlugin(self: *Self, plugin: Plugin) AppError!void {
        const exist = self.plugins.contains(plugin.name);
        if (exist) {
            return AppError.DuplicatePlugin;
        }
        plugin.build(self);
        self.plugins.put(plugin.name, plugin) catch unreachable;
    }
    pub fn addPlugins(self: *Self, plugins: []Plugin) AppError!void {
        for (plugins) |plugin| {
            try self.addPlugin(plugin);
        }
    }
    pub fn setup(self: *Self) void {
        while (self.plugins.iterator().next()) |value| {
            value.value_ptr.setups(self);
        }
    }
    pub fn cleanup(self: *Self) void {
        self.deinit();
    }
};
