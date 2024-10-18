const std = @import("std");
const ArrayList = std.ArrayList;
const graph = @import("./index.zig");
const SlotInfo = graph.SlotInfo;
const SlotInfoArrayList = graph.SlotInfoArrayList;
const RenderGraphError = graph.RenderGraphError;
const RenderGraphContext = graph.RenderGraphContext;
const findSlotIndex = graph.findSlotIndex;
pub const NodeRunError = error{
    InputSlotError,
    OutputSlotError,
    RunSubGraphError,
};
pub const StaticStr = []const u8;
pub const Node = struct {
    const Self = @This();
    pub const VTable = struct {
        update: ?*const fn (ctx: *anyopaque) void = null,
        run: *const fn (ctx: *anyopaque, ctx: *RenderGraphContext) NodeRunError!void,
        deinit: *const fn (ctx: *anyopaque) void,
        inputs: *const fn (ctx: *anyopaque) *SlotInfoArrayList,
        outputs: *const fn (ctx: *anyopaque) *SlotInfoArrayList,
    };
    edges: Edges,
    name: StaticStr,
    ptr: *anyopaque,
    vtable: *const VTable,
    allocator: std.mem.Allocator,
    pub fn init(allocator: std.mem.Allocator, name: []const u8, ptr: *anyopaque, vtable: *const VTable) Self {
        const self: Self = .{
            .allocator = allocator,
            .edges = Edges.init(allocator),
            .ptr = ptr,
            .vtable = vtable,
            .name = name,
        };
        return self;
    }
    pub fn update(self: *Self) void {
        if (self.vtable.update) |func| {
            return func(self.ptr);
        }
    }
    pub fn findInputSlotIndex(self: *Self, slotName: StaticStr) RenderGraphError!usize {
        const slots = self.inputs();
        return findSlotIndex(slots, slotName, RenderGraphError.InvalidInputNodeSlot);
    }
    pub fn findOutputSlotIndex(self: *Self, slotName: StaticStr) RenderGraphError!usize {
        const slots = self.outputs();
        return findSlotIndex(slots, slotName, RenderGraphError.InvalidOutputNodeSlot);
    }
    pub fn inputs(self: *Self) *SlotInfoArrayList {
        return self.vtable.inputs(self.ptr);
    }
    pub fn outputs(self: *Self) *SlotInfoArrayList {
        return self.vtable.outputs(self.ptr);
    }
    pub fn run(self: *Self, ctx: *RenderGraphContext) NodeRunError!void {
        return self.vtable.run(self.ptr, ctx);
    }
    pub fn deinit(self: *Self) void {
        self.vtable.deinit(self.ptr); //destroy ptr,sync lifetime
        self.edges.deinit();
    }
};
pub const SlotEdge = struct {
    inputNode: *Node,
    inputSlotIndex: usize,
    outputNode: *Node,
    outputSlotIndex: usize,
    pub fn eq(self: SlotEdge, other: SlotEdge) bool {
        return self.inputNode == other.inputNode and self.outputNode == other.outputNode and self.inputSlotIndex == other.inputSlotIndex and self.outputSlotIndex == other.outputSlotIndex;
    }
};
pub const NodeEdge = struct {
    inputNode: *Node,
    outputNode: *Node,
    pub fn eq(self: NodeEdge, other: NodeEdge) bool {
        return self.inputNode == other.inputNode and self.outputNode == other.outputNode;
    }
};
pub const EdgeEnum = enum {
    SlotEdge,
    NodeEdge,
};
pub const Edge = union(EdgeEnum) {
    SlotEdge: SlotEdge,
    NodeEdge: NodeEdge,
    pub fn debug(self: Edge) void {
        switch (self) {
            Edge.NodeEdge => |edge| {
                std.debug.print("Edge.NodeEdge,output(.name={s}),input(.name={s})\n", .{ edge.outputNode.name, edge.inputNode.name });
            },
            Edge.SlotEdge => |edge| {
                std.debug.print("Edge.SlotEdge,output(.name={s}.slot={s}),input(.name={s}.slot={s})\n", .{ edge.outputNode.name, edge.outputSlot.name, edge.inputNode.name, edge.inputSlot.name });
            },
        }
    }
    pub fn getInputNode(self: Edge) *Node {
        const node = switch (self) {
            Edge.NodeEdge => |edge| edge.inputNode,
            Edge.SlotEdge => |edge| edge.inputNode,
        };
        return node;
    }
    pub fn getOutputNode(self: Edge) *Node {
        const node = switch (self) {
            Edge.NodeEdge => |edge| edge.outputNode,
            Edge.SlotEdge => |edge| edge.outputNode,
        };
        return node;
    }
    pub fn eq(self: Edge, other: *const Edge) bool {
        if (@as(EdgeEnum, self) == @as(EdgeEnum, other.*)) {
            switch (self) {
                Edge.SlotEdge => return self.SlotEdge.eq(other.SlotEdge),
                Edge.NodeEdge => return self.NodeEdge.eq(other.NodeEdge),
            }
        } else {
            return false;
        }
    }
};
pub const EdgeArrayList = struct {
    arrayList: ArrayList(Edge),
    const Self = @This();
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .arrayList = ArrayList(Edge).init(allocator),
        };
    }
    pub fn has(self: *Self, edge: *const Edge) bool {
        var res = false;
        for (self.arrayList.items) |value| {
            if (value.eq(edge)) {
                res = true;
                break;
            }
        }
        return res;
    }
    pub fn remvoe(self: *Self, edge: *Edge) RenderGraphError!void {
        const len = self.arrayList.items.len;
        for (0..len) |i| {
            const innerEdge = self.arrayList.items[i];
            if (innerEdge.eq(edge)) {
                _ = self.arrayList.swapRemove(i);
                break;
            }
        }
        return RenderGraphError.EdgeDoesNotExist;
    }
    pub fn append(self: *Self, edge: Edge) void {
        return self.arrayList.append(edge) catch unreachable;
    }
    pub fn deinit(self: *Self) void {
        self.arrayList.deinit();
    }
};
pub const EdgeExistence = union(enum) {
    Exists,
    DoesNotExist,
};
pub const Edges = struct {
    inputEdges: EdgeArrayList,
    outputEdges: EdgeArrayList,
    pub fn init(allocator: std.mem.Allocator) Edges {
        return .{
            .inputEdges = EdgeArrayList.init(allocator),
            .outputEdges = EdgeArrayList.init(allocator),
        };
    }
    pub inline fn addInputEdge(self: *Edges, edge: Edge) RenderGraphError!void {
        if (self.inputEdges.has(&edge)) {
            return RenderGraphError.EdgeAlreadyExists;
        } else {
            self.inputEdges.append(edge);
        }
    }
    pub inline fn addOutputEdge(self: *Edges, edge: Edge) RenderGraphError!void {
        if (self.outputEdges.has(&edge)) {
            return RenderGraphError.EdgeAlreadyExists;
        } else {
            self.outputEdges.append(edge);
        }
    }
    pub inline fn removeInputEdge(self: *Edges, edge: *Edge) RenderGraphError!void {
        try self.inputEdges.remvoe(edge);
    }
    pub inline fn removeOutputEdge(self: *Edges, edge: *Edge) RenderGraphError!void {
        try self.outputEdges.remvoe(edge);
    }
    pub inline fn has(self: *Edges, edge: *Edge) bool {
        return self.inputEdges.has(edge) or self.outputEdges.has(edge);
    }
    pub fn deinit(self: *Edges) void {
        self.inputEdges.deinit();
        self.outputEdges.deinit();
    }
};
pub const EmptyNode = struct {
    slots: SlotInfoArrayList,
    allocator: std.mem.Allocator,
    const Self = @This();
    pub fn new(allocator: std.mem.Allocator) *Self {
        const self = allocator.create(Self) catch unreachable;
        self.* = .{
            .slots = SlotInfoArrayList.init(allocator),
            .allocator = allocator,
        };
        return self;
    }
    pub fn deinit(ctx: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        self.slots.deinit();
        self.allocator.destroy(self);
    }
    pub fn inputs(ctx: *anyopaque) *SlotInfoArrayList {
        const self: *Self = @ptrCast(@alignCast(ctx));
        return &self.slots;
    }
    pub fn outputs(ctx: *anyopaque) *SlotInfoArrayList {
        const self: *Self = @ptrCast(@alignCast(ctx));
        return &self.slots;
    }
    pub fn run(_: *anyopaque, _: *graph.RenderGraphContext) graph.NodeRunError!void {}
    pub fn node(self: *Self, name: []const u8) graph.Node {
        return graph.Node.init(
            self.allocator,
            name,
            self,
            &.{
                .run = run,
                .deinit = deinit,
                .inputs = inputs,
                .outputs = outputs,
            },
        );
    }
};
