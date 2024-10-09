const Allocator = @import("std").mem.Allocator;
const debug = @import("std").debug;
const RenderGraph = @import("./graph.zig").RenderGraph;
const Node = @import("./node.zig").Node;
pub fn getSubGraph(mainGraph: *RenderGraph, subGraphName: []const u8) *RenderGraph {
    return mainGraph.getSubGraph(subGraphName) orelse {
        debug.print("SubGraph {s} not found", .{subGraphName});
        unreachable;
    };
}
pub fn addNode(mainGraph: *RenderGraph, subGraphName: []const u8, node: Node) void {
    var subGraph = getSubGraph(mainGraph, subGraphName);
    subGraph.addNode(node.name, node);
}
pub fn addSubGraph(alloc: Allocator, mainGraph: *RenderGraph, subGraphName: []const u8) void {
    mainGraph.addSubGraph(subGraphName, RenderGraph.init(alloc));
}

pub fn addEdges(mainGraph: *RenderGraph, subGraphName: []const u8, edges: [][]const u8) void {
    var subGraph = getSubGraph(mainGraph, subGraphName);
    subGraph.addNodeEdges(edges);
}
pub fn addEdge(mainGraph: *RenderGraph, subGraphName: []const u8, edge: []const u8) void {
    var subGraph = getSubGraph(mainGraph, subGraphName);
    subGraph.addNodeEdge(edge);
}
