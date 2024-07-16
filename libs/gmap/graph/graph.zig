const std = @import("std");
const graph = @import("index.zig");
const Node = graph.Node;
const SlotInfoArrayList = graph.SlotInfoArrayList;
const NodeRunError = graph.NodeRunError;
const Edge = graph.Edge;
const SlotEdge = graph.SlotEdge;
const NodeEdge = graph.NodeEdge;
const SlotInfo = graph.SlotInfo;
const SlotType = graph.SlotType;
const StaticStr = graph.StaticStr;
const EdgeExistence = graph.EdgeExistence;
const RenderGraphContext = graph.RenderGraphContext;
const StringArrayHashMap = std.StringArrayHashMap;
pub const Context = struct {};
pub const RenderGraphError = error{
    InvalidNode,
    InvalidOutputNodeSlot,
    InvalidInputNodeSlot,
    WrongNodeType,
    MismatchedNodeSlots,
    EdgeAlreadyExists,
    EdgeDoesNotExist,
    UnconnectedNodeInputSlot,
    UnconnectedNodeOutputSlot,
    NodeInputSlotAlreadyOccupied,
};
pub const RenderGraph = struct {
    nodes: StringArrayHashMap(Node),
    subGraphs: StringArrayHashMap(*RenderGraph),
    inputNode: ?*Node = undefined,
    allocator: std.mem.Allocator,
    const Self = @This();
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .nodes = StringArrayHashMap(Node).init(allocator),
            .subGraphs = StringArrayHashMap(*RenderGraph).init(allocator),
        };
    }
    pub fn deinit(self: *Self) void {
        for (self.nodes.values()) |*value| {
            value.deinit();
        }
        var subGraphIt = self.subGraphs.iterator();
        while (subGraphIt.next()) |value| {
            value.value_ptr.*.deinit();
        }
        self.nodes.deinit();
        self.subGraphs.deinit();
        if (self.inputNode) |node| {
            node.deinit();
        }
    }
    pub fn update(self: *Self, context: Context) void {
        var it = self.nodes.valueIterator();
        while (it.next()) |node| {
            node.update(context);
        }
        var subIt = self.subGraphs.valueIterator();
        while (subIt.next()) |subGraph| {
            subGraph.update(context);
        }
    }
    pub fn setInput(self: *Self, inputs: SlotInfoArrayList) void {
        self.addNode(GraphInputNode{ .inputs = inputs });
    }
    pub fn addNode(self: *Self, node: Node) void {
        // var nodeMut = node;
        // nodeMut.name = name;
        self.nodes.put(node.name, node) catch unreachable;
    }
    pub fn getNode(self: *Self, name: StaticStr) RenderGraphError!*Node {
        if (self.nodes.getPtr(name)) |value| {
            return value;
        } else {
            return RenderGraphError.InvalidNode;
        }
    }
    pub fn addNodeEdge(self: *Self, outputId: StaticStr, inputId: StaticStr) RenderGraphError!void {
        const inputNode = try self.getNode(inputId);
        const outputNode = try self.getNode(outputId);
        var edge = Edge{ .NodeEdge = NodeEdge{
            .inputNode = inputNode,
            .outputNode = outputNode,
        } };
        try self.validateEdge(&edge, EdgeExistence.DoesNotExist);
        try outputNode.edges.addOutputEdge(edge);
        try inputNode.edges.addInputEdge(edge);
    }
    pub fn addNodeEdges(self: *Self, edges: []StaticStr) !void {
        for (0..edges.len - 1) |i| {
            const input = edges[i];
            const output = edges[i + 1];
            self.addNodeEdge(input, output) catch unreachable;
        }
    }
    pub fn removeNodeEdge(self: *Self, inputId: StaticStr, outputId: StaticStr) void {
        const inputNode = self.getNode(inputId).?;
        const outputNode = self.getNode(outputId).?;
        var edge = Edge{ .NodeEdge = NodeEdge{
            .inputNode = inputNode,
            .outputNode = outputNode,
        } };
        try self.validateEdge(&edge, EdgeExistence.Exists);
        outputNode.edges.removeOutputEdge(&edge);
        inputNode.edges.removeInputEdge(&edge);
    }
    pub fn removeNde(self: *Self, name: StaticStr) bool {
        return self.nodes.remove(name);
    }
    pub fn addSlotEdge(self: *Self, outputNodeId: StaticStr, outputSlotName: StaticStr, inputNodeId: StaticStr, inputSlotName: StaticStr) RenderGraphError!void {
        var inputNode = try self.getNode(inputNodeId);
        var outputNode = try self.getNode(outputNodeId);
        const outputSlotIndex = try outputNode.findOutputSlotIndex(outputSlotName);
        const inputSlotIndex = try inputNode.findInputSlotIndex(inputSlotName);
        var edge = Edge{ .SlotEdge = SlotEdge{
            .inputNode = inputNode,
            .outputNode = outputNode,
            .inputSlotIndex = inputSlotIndex,
            .outputSlotIndex = outputSlotIndex,
        } };
        try self.validateEdge(&edge, EdgeExistence.DoesNotExist);
        try outputNode.edges.addOutputEdge(edge);
        try inputNode.edges.addInputEdge(edge);
    }
    pub fn removeSlotEdge(self: *Self, outputNodeId: StaticStr, outputSlotName: StaticStr, inputNodeId: StaticStr, inputSlotName: StaticStr) void {
        var inputNode = try self.getNode(inputNodeId);
        var outputNode = try self.getNode(outputNodeId);
        const outputSlotIndex = try outputNode.findOutputSlotIndex(outputSlotName);
        const inputSlotIndex = try inputNode.findInputSlotIndex(inputSlotName);
        var edge = Edge{ .SlotEdge = SlotEdge{
            .inputNode = inputNode,
            .outputNode = outputNode,
            .inputSlotIndex = inputSlotIndex,
            .outputSlotIndex = outputSlotIndex,
        } };
        try self.validateEdge(&edge, EdgeExistence.Exists);
        try outputNode.edges.removeOutputEdge(&edge);
        try inputNode.edges.removeInputEdge(&edge);
    }
    pub fn validateEdge(self: *Self, edge: *Edge, shouldEixst: EdgeExistence) RenderGraphError!void {
        if (shouldEixst == EdgeExistence.Exists and !self.hasEdge(edge)) {
            return RenderGraphError.EdgeDoesNotExist;
        } else if (shouldEixst == EdgeExistence.DoesNotExist and self.hasEdge(edge)) {
            return RenderGraphError.EdgeAlreadyExists;
        }
        switch (edge.*) {
            Edge.SlotEdge => |*edgeV| {
                const outputSlot = edgeV.outputNode.outputs().items[edgeV.outputSlotIndex];
                const inputSlot = edgeV.outputNode.outputs().items[edgeV.inputSlotIndex];
                const inputNode = edgeV.inputNode;
                for (inputNode.edges.inputEdges.arrayList.items) |v| {
                    switch (v) {
                        Edge.SlotEdge => |vv| {
                            if (edgeV.inputSlotIndex == vv.inputSlotIndex and shouldEixst == EdgeExistence.DoesNotExist) {
                                return RenderGraphError.NodeInputSlotAlreadyOccupied;
                            }
                        },
                        else => {},
                    }
                }
                if (outputSlot.slotType != inputSlot.slotType) {
                    return RenderGraphError.MismatchedNodeSlots;
                }
            },
            Edge.NodeEdge => {},
        }
    }

    pub fn hasEdge(self: Self, edge: *Edge) bool {
        _ = self;
        const outputNode = edge.getOutputNode();
        const inputNode = edge.getInputNode();
        const res = outputNode.edges.outputEdges.has(edge) and inputNode.edges.inputEdges.has(edge);
        return res;
    }
    pub fn addSubGraph(self: *Self, name: StaticStr, subGraph: RenderGraph) !void {
        return self.subGraphs.put(name, subGraph);
    }
    pub fn removeSubGraph(self: *Self, name: StaticStr) bool {
        return self.subGraphs.remove(name);
    }
    pub fn getSubGraph(self: *Self, name: StaticStr) ?RenderGraph {
        return self.subGraphs.get(name);
    }

    pub fn getSubGraphPtr(self: *Self, name: StaticStr) ?*RenderGraph {
        return self.subGraphs.getPtr(name);
    }
    pub const Entry = struct {
        edgePtr: *Edge,
        nodePtr: *Node,
    };
    // find all output nodes of a node
    // A------L------>B
    // A is output node,B is input node.
    // L is in a A.outputEdges
    // A is output node of L
    // B is input node of L
    pub fn iterNodeOutputs(self: *Self, name: StaticStr) RenderGraphError!std.ArrayList(Entry) {
        const node = try self.getNode(name);
        const outputEdges = node.edges.outputEdges.arrayList;
        var resultList = std.ArrayList(Entry).initCapacity(self.allocator, outputEdges.items.len) catch unreachable;
        for (outputEdges.items) |*edge| {
            const inputNode = edge.getInputNode();
            resultList.appendAssumeCapacity(Entry{
                .edgePtr = edge,
                .nodePtr = inputNode,
            });
        }
        return resultList;
    }
    // find all input nodes of a node
    pub fn iterNodeInputs(self: *Self, name: StaticStr) RenderGraphError!std.ArrayList(Entry) {
        const node = try self.getNode(name);
        const inputEdges = node.edges.inputEdges.arrayList;
        var resultList = std.ArrayList(Entry).initCapacity(self.allocator, inputEdges.items.len) catch unreachable;
        for (inputEdges.items) |*edge| {
            const outputNode = edge.getOutputNode();
            resultList.appendAssumeCapacity(Entry{
                .edgePtr = edge,
                .nodePtr = outputNode,
            });
        }
        return resultList;
    }
};

pub const GraphInputNode = struct {
    inputs: SlotInfoArrayList,
    allocator: std.mem.Allocator,
    pub fn init(allocator: std.mem.Allocator) GraphInputNode {
        return .{
            .inputs = SlotInfoArrayList.init(allocator),
            .allocator = allocator,
        };
    }
    pub fn input(ctx: *anyopaque) ?SlotInfoArrayList {
        const self: *GraphInputNode = @ptrCast(@alignCast(ctx));
        return self.inputs;
    }
    pub fn output(ctx: *anyopaque) ?SlotInfoArrayList {
        const self: *GraphInputNode = @ptrCast(@alignCast(ctx));
        return self.inputs;
    }
    pub fn run(ctx: *anyopaque) ?NodeRunError {
        const self: *GraphInputNode = @ptrCast(@alignCast(ctx));
        _ = self;
    }
    pub fn nodeI(self: *GraphInputNode) Node {
        return Node.init(
            self.allocator,
            @typeName(GraphInputNode),
            self,
            &.{
                .input = input,
                .outpupt = output,
                .run = run,
            },
        );
    }
};

const indexStrList = [_]*const [1:0]u8{
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
};
pub const TestNode = struct {
    const Self = @This();
    inputSlots: SlotInfoArrayList,
    outputSlots: SlotInfoArrayList,
    allocator: std.mem.Allocator,
    pub fn init(allocator: std.mem.Allocator) Self {
        const self: Self = .{
            .allocator = allocator,
            .inputSlots = SlotInfoArrayList.init(allocator),
            .outputSlots = SlotInfoArrayList.init(allocator),
        };
        return self;
    }
    pub fn debug(self: *Self) void {
        for (self.inputSlots.items, 0..) |item, i| {
            std.debug.print("input index={d} name={s}\n", .{ i, item.name });
        }
        for (self.outputSlots.items, 0..) |item, i| {
            std.debug.print("output index={d} name={s}\n", .{ i, item.name });
        }
    }
    pub fn deinit(ctx: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        self.inputSlots.deinit();
        self.outputSlots.deinit();
    }
    pub fn run(ctx: *anyopaque, context: *RenderGraphContext) NodeRunError!void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        _ = self;
        _ = context;
    }
    pub fn inputs(ctx: *anyopaque) *SlotInfoArrayList {
        const self: *Self = @ptrCast(@alignCast(ctx));
        return &self.inputSlots;
    }
    pub fn outputs(ctx: *anyopaque) *SlotInfoArrayList {
        const self: *Self = @ptrCast(@alignCast(ctx));
        return &self.outputSlots;
    }
    pub fn nodeI(self: *Self, name: []const u8) Node {
        return Node.init(
            self.allocator,
            name,
            @typeName(Self),
            self,
            &.{
                .deinit = deinit,
                .run = run,
                .update = null,
                .inputs = inputs,
                .outputs = outputs,
            },
        );
    }
};
fn output_nodes(allocator: std.mem.Allocator, graphv: *RenderGraph, name: []const u8) !std.ArrayList(*Node) {
    const outputs = try graphv.iterNodeOutputs(name);
    defer outputs.deinit();
    var array = std.ArrayList(*Node).initCapacity(allocator, outputs.items.len) catch unreachable;
    for (outputs.items) |item| {
        array.appendAssumeCapacity(item.nodePtr);
    }
    return array;
}
fn input_nodes(allocator: std.mem.Allocator, graphv: *RenderGraph, name: []const u8) !std.ArrayList(*Node) {
    const inputs = try graphv.iterNodeInputs(name);
    defer inputs.deinit();
    var array = std.ArrayList(*Node).initCapacity(allocator, inputs.items.len) catch unreachable;
    for (inputs.items) |item| {
        array.appendAssumeCapacity(item.nodePtr);
    }
    return array;
}
test "graph.graph.default" {
    const allocator = std.testing.allocator;
    var graphv = RenderGraph.init(allocator);
    defer graphv.deinit();
    var n0 = TestNode.init(allocator);
    _ = try n0.outputSlots.append(SlotInfo{ .name = "out_0", .slotType = SlotType.TextureView });
    var A = n0.nodeI("A");
    graphv.addNode(A);

    var n1 = TestNode.init(allocator);
    _ = try n1.outputSlots.append(SlotInfo{ .name = "out_0", .slotType = SlotType.TextureView });
    var B = n1.nodeI("B");
    graphv.addNode(B);

    var n2 = TestNode.init(allocator);
    _ = try n2.outputSlots.append(SlotInfo{ .name = "out_0", .slotType = SlotType.TextureView });
    _ = try n2.inputSlots.append(SlotInfo{ .name = "in_0", .slotType = SlotType.TextureView });
    var C = n2.nodeI("C");
    graphv.addNode(C);

    var n3 = TestNode.init(allocator);
    _ = try n3.inputSlots.append(SlotInfo{ .name = "in_0", .slotType = SlotType.TextureView });
    var D = n3.nodeI("D");
    graphv.addNode(D);

    const testing = @import("std").testing;
    try testing.expectEqual(graphv.nodes.count(), 4);
    try graphv.addSlotEdge("A", "out_0", "C", "in_0");
    try graphv.addNodeEdge("B", "C");
    try graphv.addSlotEdge("C", "out_0", "D", "in_0");

    {
        try testing.expectEqual(A.inputs().items.len, 0);
        const outputs = try output_nodes(std.testing.allocator, &graphv, "A");
        defer outputs.deinit();
        try std.testing.expect(std.mem.eql(u8, outputs.items[0].name, "C"));
    }
    {
        try testing.expectEqual(B.inputs().items.len, 0);
        const outputs = try output_nodes(std.testing.allocator, &graphv, "B");
        defer outputs.deinit();
        try std.testing.expect(std.mem.eql(u8, outputs.items[0].name, "C"));
    }
    {
        try testing.expectEqual(C.outputs().items.len, 1);
        const inputs = try input_nodes(std.testing.allocator, &graphv, "C");
        defer inputs.deinit();
        try std.testing.expect(std.mem.eql(u8, inputs.items[0].name, "A"));
        try std.testing.expect(std.mem.eql(u8, inputs.items[1].name, "B"));

        const outputs = try output_nodes(std.testing.allocator, &graphv, "C");
        defer outputs.deinit();
        try std.testing.expect(std.mem.eql(u8, outputs.items[0].name, "D"));
    }
    {
        try testing.expectEqual(D.outputs().items.len, 0);
        const inputs = try input_nodes(std.testing.allocator, &graphv, "D");
        defer inputs.deinit();
        try std.testing.expect(std.mem.eql(u8, inputs.items[0].name, "C"));
    }
}

test "graph.graph.slotAlreadyOccupied" {
    const allocator = std.testing.allocator;
    var graphv = RenderGraph.init(allocator);
    defer graphv.deinit();
    var n0 = TestNode.init(allocator);
    _ = try n0.outputSlots.append(SlotInfo{ .name = "out_0", .slotType = SlotType.TextureView });
    const A = n0.nodeI("A");
    graphv.addNode(A);

    var n1 = TestNode.init(allocator);
    _ = try n1.outputSlots.append(SlotInfo{ .name = "out_0", .slotType = SlotType.TextureView });
    const B = n1.nodeI("B");
    graphv.addNode(B);

    var n2 = TestNode.init(allocator);
    _ = try n2.outputSlots.append(SlotInfo{ .name = "out_0", .slotType = SlotType.TextureView });
    _ = try n2.inputSlots.append(SlotInfo{ .name = "in_0", .slotType = SlotType.TextureView });
    const C = n2.nodeI("C");
    graphv.addNode(C);

    try graphv.addSlotEdge("A", "out_0", "C", "in_0");
    const result = graphv.addSlotEdge("B", "out_0", "C", "in_0");
    try std.testing.expect(RenderGraphError.NodeInputSlotAlreadyOccupied == result);
}

test "graph.graph.edgeAlreadyExists" {
    const allocator = std.testing.allocator;
    var graphv = RenderGraph.init(allocator);
    defer graphv.deinit();
    var n0 = TestNode.init(allocator);
    const A = n0.nodeI("A");
    graphv.addNode(A);

    var n1 = TestNode.init(allocator);
    const B = n1.nodeI("B");
    graphv.addNode(B);

    var n2 = TestNode.init(allocator);
    const C = n2.nodeI("C");
    graphv.addNode(C);

    var edges = [_][]const u8{ "A", "B", "C" };
    try graphv.addNodeEdges(&edges);

    {
        const list = try output_nodes(std.testing.allocator, &graphv, "A");
        defer list.deinit();
        try std.testing.expect(std.mem.eql(u8, list.items[0].name, "B"));
    }
    {
        const list = try input_nodes(std.testing.allocator, &graphv, "B");
        defer list.deinit();
        try std.testing.expect(std.mem.eql(u8, list.items[0].name, "A"));
    }
    {
        const list = try output_nodes(std.testing.allocator, &graphv, "B");
        defer list.deinit();
        try std.testing.expect(std.mem.eql(u8, list.items[0].name, "C"));
    }
    {
        const list = try input_nodes(std.testing.allocator, &graphv, "C");
        defer list.deinit();
        try std.testing.expect(std.mem.eql(u8, list.items[0].name, "B"));
    }
}
const SimpleNode = struct {
    pub fn deinit(ctx: *anyopaque) void {
        const self: *SimpleNode = @ptrCast(@alignCast(ctx));
        _ = self;
    }
    fn nodeI(self: *SimpleNode, name: []const u8, allocator: std.mem.Allocator) Node {
        return Node.init(allocator, name, @typeName(SimpleNode), self, &.{ .deinit = deinit });
    }
};
test "graph.graph.addNodeEdge" {
    const allocator = std.testing.allocator;
    var graphv = RenderGraph.init(allocator);
    defer graphv.deinit();
}
const T = struct { name: []const u8 };
test "std.mem.eql" {
    var t = T{ .name = "hello" };
    const a = [_]*T{&t};
    const b = [_]*T{&t};
    try std.testing.expect(std.mem.eql(*T, &a, &b));
    const c = a[0..a.len];
    try std.testing.expect(std.mem.eql(*T, c, &b));
}
