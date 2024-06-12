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
        // if (self.inputNode) |node| {
        //     node.deinit();
        // }
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
    pub fn getInput(self: Self) ?Node {
        return self.inputNode;
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
    pub fn addNodeEdge(self: *Self, inputId: StaticStr, outputId: StaticStr) RenderGraphError!void {
        const inputNode = try self.getNode(inputId);
        const outputNode = try self.getNode(outputId);
        const edge = Edge{ .NodeEdge = NodeEdge{
            .inputNode = inputNode,
            .outputNode = outputNode,
        } };
        try outputNode.edges.addOutputEdge(edge);
        try inputNode.edges.addInputEdge(edge);
    }
    pub fn addNodeEdges(self: *Self, edges: []StaticStr) !void {
        for (0..edges.len - 1) |i| {
            const input = edges[i];
            const output = edges[i + 1];
            self.addNodeEdge(input, output);
        }
    }
    pub fn removeNde(self: *Self, name: StaticStr) bool {
        return self.nodes.remove(name);
    }
    pub fn addSlotEdge(self: *Self, outputNodeId: StaticStr, outputSlot: StaticStr, inputNodeId: StaticStr, inputSlot: StaticStr) RenderGraphError!void {
        var inputNode = try self.getNode(inputNodeId);
        var outputNode = try self.getNode(outputNodeId);
        const outputSlotIndex = try inputNode.findInputSlotIndex(outputSlot);
        const inputSlotIndex = try outputNode.findOutputSlotIndex(inputSlot);
        const edge = Edge{ .SlotEdge = SlotEdge{
            .inputNode = inputNode,
            .outputNode = outputNode,
            .inputIndex = inputSlotIndex,
            .outputIndex = outputSlotIndex,
        } };
        try outputNode.edges.addOutputEdge(edge);
        try inputNode.edges.addInputEdge(edge);
    }
    pub fn removeSlotEdge(self: *Self, outputNodeId: StaticStr, outputSlot: StaticStr, inputNodeId: StaticStr, inputSlot: StaticStr) void {
        var inputNode = try self.getNode(inputNodeId);
        var outputNode = try self.getNode(outputNodeId);
        const outputSlotIndex = try inputNode.findInputSlotIndex(outputSlot);
        const inputSlotIndex = try outputNode.findOutputSlotIndex(inputSlot);
        var edge = Edge{ .SlotEdge = SlotEdge{
            .inputNode = inputNode,
            .outputNode = outputNode,
            .inputIndex = inputSlotIndex,
            .outputIndex = outputSlotIndex,
        } };
        try outputNode.edges.removeOutputEdge(&edge);
        try inputNode.edges.removeInputEdge(&edge);
    }
    pub fn removeNodeEdge(self: *Self, inputId: StaticStr, outputId: StaticStr) void {
        const inputNode = self.getNode(inputId).?;
        const outputNode = self.getNode(outputId).?;
        const edge = Edge{ .NodeEdge = NodeEdge{
            .inputNode = inputNode,
            .outputNode = outputNode,
        } };
        outputNode.edges.removeOutputEdge(&edge);
        inputNode.edges.removeInputEdge(&edge);
    }
    pub fn hasEdge(self: Self, edge: *Edge) bool {
        _ = self;
        const outputNode = edge.getOutputNode();
        const inputNode = edge.getInputNode();
        return outputNode.edges.outputEdges.has(edge) and inputNode.edges.inputEdges.has(edge);
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
const TestNode = struct {
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
    pub fn run(ctx: *anyopaque) NodeRunError!void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        _ = self;
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
test "render.graph.graph" {
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

    try testing.expectEqual(A.inputs().items.len, 0);
    try testing.expectEqual(B.inputs().items.len, 0);
    try testing.expectEqual(C.outputs().items.len, 1);
    try testing.expectEqual(D.outputs().items.len, 0);
}
