const std = @import("std");
const ArrayList = std.ArrayList;
const graph = @import("index.zig");
const StaticStr = graph.StaticStr;
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
pub fn findSlotIndex(slotInfoArrayList: *const SlotInfoArrayList, slotInfoName: StaticStr, err: graph.RenderGraphError) graph.RenderGraphError!usize {
    var i: i16 = -1;
    for (slotInfoArrayList.items) |item| {
        i = i + 1;
        if (std.mem.eql(u8, item.name, slotInfoName)) {
            break;
        }
    }
    if (i == -1) {
        return err;
    } else {
        return @intCast(i);
    }
}
