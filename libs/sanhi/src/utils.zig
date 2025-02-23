const std = @import("std");
const math = @import("math");
const Matrix4 = math.Matrix4;
const Matrix4D = math.Matrix4D;
const Vector3 = math.Vector3;
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

pub fn removeById(comptime T:type,list:*std.ArrayList(T),id:anytype) ?T {
    var get_it: bool = false;
    var targetIndex: usize = 0;
    for (list.items, 0..) |item, i| {
        if (item.id == id) {
            targetIndex = i;
            get_it = true;
            break;
        }
    }
    if (get_it) {
        return list.swapRemove(targetIndex);
    }
}
pub fn getByName(comptime T:type,list:*std.ArrayList(T),name:[]const u8) ?T {
    var get_it: bool = false;
    var targetIndex: usize = 0;
    for (list.items, 0..) |item, i| {
        if (std.mem.eql(u8, item.name, name)) {
            targetIndex = i;
            get_it = true;
            break;
        }
    }
    if (get_it) {
        return list.items[targetIndex];
    }
    return null;
}

// pub fn createSlicefromVector3(vec3List:[]const Vector3)[]f64{
    
// }