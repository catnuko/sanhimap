const std = @import("std");
const graph = @import("../index.zig").graph;
const SlotInfoArrayList = graph.SlotInfoArrayList;
pub const PrepassNode = struct {
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
