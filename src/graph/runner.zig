// const std = @import("std");
// const graph = @import("./index.zig");
// const RenderGraphError = graph.RenderGraphError;
// const StaticStr = graph.StaticStr;
// const SlotValue = graph.SlotValue;
// const RenderGraph = graph.RenderGraph;
// const Node = graph.Node;
// const Edge = graph.Edge;
// pub const RenderGraphRunnerError = error{
//     EmptyNodeOutputSlot,
//     MissingInput,
//     MismatchedInputSlotType,
//     MismatchedInputCount,
// };
// const NodeQueue = std.TailQueue(*Node);
// pub const GraphRunner = struct {
//     allocator: std.mem.Allocator,
//     graph: *RenderGraph,
//     pub fn init(allocator: std.mem.Allocator, graphv: *RenderGraph) GraphRunner {
//         return .{ .allocator = allocator, .graph = graphv };
//     }
//     pub fn runGraph(self: *GraphRunner, inputs: []const SlotValue) RenderGraphRunnerError!void {
//         var nodeOutputs = std.AutoHashMap(
//             StaticStr,
//             std.ArrayList(SlotValue),
//         ).init(self.allocator);
//         defer nodeOutputs.deinit();
//         const graph = self.graph;
//         var nodeQueue = NodeQueue{};
//         //pass input into graph
//         if (graph.inputNode) |inputNode| {
//             var inputValues = std.ArrayList(SlotValue).initCapacity(self.allocator, 4) catch unreachable;
//             for (inputNode.inputs(), 0..) |inputSlot, i| {
//                 if (i < inputs.len) {
//                     const input = inputs[i];
//                     if (inputSlot.slotType != inputValue.slotType()) {
//                         return RenderGraphRunnerError.MismatchedInputSlotType;
//                     }
//                     inputValues.append(input);
//                 } else {
//                     return RenderGraphRunnerError.MissingInput;
//                 }
//             }
//             nodeOutputs.put(inputNode.name, inputValues);
//             const outputs = graph.iterNodeOutputs(inputNode.name) catch unreachable;
//             defer outputs.deinit();
//             for (outputs) |entry| {
//                 var node = NodeQueue.Node{ .data = entry.nodePtr };
//                 nodeQueue.prepend(&node);
//             }
//         }
//         const Entry = struct {
//             inputSlot: *SlotValue,
//             input: SlotValue,
//         };
//         handleNode: while (nodeQueue.pop()) |queueNode| {
//             const node = queueNode.data;
//             //skip nodes that are already processed
//             if (nodeOutputs.contains(node.name)) {
//                 continue;
//             }
//             var slotIndicesAndInputs = std.ArrayList(Entry).initCapacity(self.allocator, 4) catch unreachable;
//             //check if all dependencies have finished running
//             for (graph.iterNodeInputs(node.name) catch unreachable) |entry| {
//                 const edge = entry.edgePtr;
//                 const inputNode = entry.nodePtr;
//                 switch (edge) {
//                     Edge.SlotEdge => |edgeV| {
//                         if (nodeOutputs.get(inputNode.name)) |inputNodeOutputs| {
//                             slotIndicesAndInputs.append(Entry{
//                                 .inputSlot = edgeV.inputSlot,
//                                 // .input = outputs.items[]
//                             }) catch unreachable;
//                         }
//                     },
//                     Edge.NodeEdge => |edgeV| {},
//                 }
//             }
//         }
//     }
// };

// test "graph.runner.slice" {
//     const slice = [_]u8{ 1, 2, 3 };
//     try std.testing.expectEqual(slice[0], 1);
//     const v = slice[2];
//     try std.testing.expectEqual(v, 3);
// }
