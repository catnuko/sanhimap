const std = @import("std");
const lib = @import("./lib.zig");
pub fn to_list(comptime T: type, constList: anytype) lib.ArrayList(T) {
    const allocator = lib.mem.getAllocator(); // 使用合适的内存分配器
    var list = lib.ArrayList(T).initCapacity(allocator, constList.len) catch unreachable;
    for (0..constList.len) |i| {
        list.appendAssumeCapacity(constList[i]);
    }
    return list;
}

pub fn erase_list(allocator: std.mem.Allocator, comptime T: type, data: []const T) []u8 {
    const gpu_data = @as([*]const u8, @ptrCast(data.ptr));
    const size = @as(u64, @intCast(data.len)) * @sizeOf(T);
    const buffer_cloned = allocator.alloc(u8, size) catch unreachable;
    @memcpy(buffer_cloned[0..], gpu_data[0..size]);
    return buffer_cloned;
}
