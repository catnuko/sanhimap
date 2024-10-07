const std = @import("std");
const graph = @import("./index.zig");
pub const RunSubGraphError = error{ MissingSubGraph, SubGraphHasNoInputs, MissingInput, MismatchedInputSlotType };
pub const OutputSlotError = error{ InvalidSlot, MismatchedSlotType };
pub const InputSlotError = error{ InvalidSlot, MismatchedSlotType };
pub const RunSubGraph = struct {
    name: []const u8,
    inputs: std.ArrayList(graph.SlotValue),
};
pub const RenderGraphContext = struct {
    graph: *const graph.RenderGraph,
    node: *const graph.Node,
    inputs: *const []graph.SlotValue,
    outputs: *std.ArrayList(?graph.SlotValue),
    runSubGraphs: std.ArrayList(RunSubGraph),
    const Self = @This();
    pub fn init(
        allocator: std.mem.Allocator,
        graphv: *const graph.RenderGraph,
        node: *const graph.Node,
        inputs: *const []graph.SlotValue,
        outputs: *std.ArrayList(graph.SlotValue),
    ) Self {
        return .{
            .graph = graphv,
            .node = node,
            .inputs = inputs,
            .outputs = *outputs,
            .runSubGraph = std.ArrayList(RunSubGraph).init(allocator),
        };
    }
    pub fn runSubGraph(
        self: *Self,
        name: []const u8,
        inputs: std.ArrayList(graph.SlotValue),
    ) RunSubGraphError!void {
        if (self.graph.getSubGraph(name)) |subGraph| {
            if (subGraph.inputNode) |inputNode| {
                for (inputNode.inputs().items, 0..) |inputSlot, i| {
                    if (inputs.items.len != i) {
                        return RunSubGraphError.MissingInput;
                    }
                    const inputValue = inputs.items[i];
                    if (inputSlot.slotType != inputValue.slotType()) {
                        return RunSubGraphError.MismatchedInputSlotType;
                    }
                }
            } else if (inputs.items != 0) {
                return RunSubGraphError.SubGraphHasNoInputs;
            }
        } else {
            return RunSubGraphError.MissingSubGraph;
        }
        self.runSubGraphs.append(RunSubGraph{
            .inputs = inputs,
            .name = name,
        });
    }
    pub fn finish(self: *Self) *std.ArrayList(RunSubGraph) {
        return self.runSubGraphs;
    }
    pub fn deinit(self: *Self) void {
        self.runSubGraphs.deinit();
    }
};
