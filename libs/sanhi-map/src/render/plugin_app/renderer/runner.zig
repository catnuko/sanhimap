const std = @import("std");
const graph = @import("./index.zig");
const RenderContext = @import("./context.zig").RenderContext;
const RenderGraphError = graph.RenderGraphError;
const StaticStr = graph.StaticStr;
const SlotValue = graph.SlotValue;
const RenderGraph = graph.RenderGraph;
const Node = graph.Node;
const Edge = graph.Edge;
pub const RenderGraphRunnerError = error{
    EmptyNodeOutputSlot,
    MissingInput,
    MismatchedInputSlotType,
    MismatchedInputCount,
};
const NodeQueue = std.TailQueue(*Node);
pub const GraphRunner = struct {
    pub fn run(
        allocator: std.mem.Allocator,
        graphV: *const RenderGraph,
    ) RenderGraphRunnerError!void {
        var renderContext = RenderContext{};
        try GraphRunner.runGraph(
            allocator,
            graphV,
            "",
            &renderContext,
            []SlotValue{},
        );
    }
    pub fn runGraph(
        allocator: std.mem.Allocator,
        graphV: *const RenderGraph,
        graphName: []const u8,
        renderContext: *RenderContext,
        inputs: []const SlotValue,
    ) RenderGraphRunnerError!void {
        _ = graphName;
        var nodeOutputs = std.StringHashMap(std.ArrayList(SlotValue)).init(allocator);
        defer nodeOutputs.deinit();
        var nodeQueue = NodeQueue{};
        //pass input into graph
        if (graphV.inputNode) |inputNode| {
            var inputValues = std.ArrayList(SlotValue).initCapacity(allocator, 4) catch unreachable;
            for (inputNode.inputs(), 0..) |inputSlot, i| {
                if (i < inputs.len) {
                    const input = inputs[i];
                    if (inputSlot.slotType != input.slotType()) {
                        return RenderGraphRunnerError.MismatchedInputSlotType;
                    }
                    inputValues.appendAssumeCapacity(input);
                } else {
                    return RenderGraphRunnerError.MissingInput;
                }
            }
            nodeOutputs.put(inputNode.name, inputValues);
            const outputs = graphV.iterNodeOutputs(inputNode.name) catch unreachable;
            defer outputs.deinit();
            for (outputs) |entry| {
                var node = NodeQueue.Node{ .data = entry.nodePtr };
                nodeQueue.prepend(&node);
            }
        }

        handleNode: while (nodeQueue.pop()) |queueNode| {
            const node = queueNode.data;
            //skip nodes that are already processed
            if (nodeOutputs.contains(node.name)) {
                continue;
            }
            var slotIndicesAndInputs = std.ArrayList(Entry).initCapacity(allocator, 4) catch unreachable;
            //check if all dependencies have finished running
            for (graphV.iterNodeInputs(node.name) catch unreachable) |entry| {
                const edge = entry.edgePtr;
                const inputNode = entry.nodePtr;
                switch (edge) {
                    Edge.SlotEdge => |edgeV| {
                        if (nodeOutputs.get(inputNode.name)) |outputs| {
                            slotIndicesAndInputs.append(Entry{
                                .index = edgeV.inputSlotIndex,
                                .input = outputs.items[edgeV.outputSlotIndex],
                            }) catch unreachable;
                        } else {
                            var node2 = NodeQueue.Node{ .data = node };
                            nodeQueue.prepend(&node2);
                            continue :handleNode;
                        }
                    },
                    Edge.NodeEdge => |_| {
                        if (!nodeOutputs.contains(inputNode.name)) {
                            var node2 = NodeQueue.Node{ .data = node };
                            nodeQueue.prepend(&node2);
                            continue :handleNode;
                        }
                    },
                }
            }
            var x = slotIndicesAndInputs.toOwnedSlice() catch unreachable;
            std.mem.sort(Entry, &x, {}, cmpByEntry);
            if (slotIndicesAndInputs.items.len != node.inputs().items.len) {
                return RenderGraphRunnerError.MismatchedInputCount;
            }
            const outputs = std.ArrayList(SlotValue).initCapacity(allocator, node.outputs().items.len) catch unreachable;
            var context = graph.RenderGraphContext.init(allocator, graphV, node, inputs, *outputs);
            node.run(*context, renderContext);
            for (context.finish().items) |runSubGrpah| {
                const subGraph = graphV.getSubGraph(runSubGrpah.name).?;
                GraphRunner.runGraph(subGraph, runSubGrpah.name, runSubGrpah.inputs);
            }
            nodeOutputs.put(node.name, outputs);
            const targetNodeOuputs = graphV.iterNodeOutputs(node.name) catch unreachable;
            for (targetNodeOuputs) |entry| {
                nodeQueue.prepend(entry.nodePtr);
            }
        }
    }
};
const Entry = struct {
    index: usize,
    input: SlotValue,
};
fn cmpByEntry(a: Entry, b: Entry) bool {
    if (a.index < b.index) {
        return true;
    } else {
        return false;
    }
}
