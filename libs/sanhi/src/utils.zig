const lib = @import("./lib.zig");
pub fn to_list(comptime T: type, constList: anytype) lib.ArrayList(T) {
    const allocator = lib.mem.getAllocator(); // 使用合适的内存分配器
    var list = lib.ArrayList(T).initCapacity(allocator, constList.len) catch unreachable;
    for (0..constList.len) |i| {
        list.appendAssumeCapacity(constList[i]);
    }
    return list;
}
