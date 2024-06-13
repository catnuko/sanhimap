const std = @import("std");
const ArrayList = std.ArrayList;
const graph = @import("index.zig");
const StaticStr = graph.StaticStr;
pub const SlotValue = union(enum) {
    Buffer,
    TextureView,
    Sampler,
    Entity,
    pub fn slotType(self: SlotValue) SlotType {
        switch (self) {
            SlotValue.Buffer => SlotType.Buffer,
            SlotValue.TextureView => SlotType.TextureView,
            SlotValue.Sampler => SlotType.Sampler,
            SlotValue.Entity => SlotType.Entity,
        }
    }
};
pub const SlotType = enum {
    /// A GPU-accessible [`Buffer`].
    Buffer,
    /// A [`TextureView`] describes a texture used in a pipeline.
    TextureView,
    /// A texture [`Sampler`] defines how a pipeline will sample from a [`TextureView`].
    Sampler,
    /// An entity from the ECS.
    Entity,
};
pub const SlotInfo = struct {
    name: StaticStr,
    slotType: SlotType,
    pub fn init(name: StaticStr, slotType: SlotType) SlotInfo {
        // std.debug.print("slotinfo {s}\n", .{name});
        return .{
            .name = name,
            .slotType = slotType,
        };
    }
};
pub const SlotInfoArrayList = ArrayList(SlotInfo);
pub fn findSlotByName(slotInfoArrayList: *const SlotInfoArrayList, slotInfoName: StaticStr, err: graph.RenderGraphError) graph.RenderGraphError!*SlotInfo {
    for (slotInfoArrayList.items) |*item| {
        if (std.mem.eql(u8, item.name, slotInfoName)) {
            return item;
        }
    }
    return err;
}
