const std = @import("std");
const lib = @import("lib");
const testing = @import("std").testing;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var mapviwe = try lib.MapView.init(allocator);
    defer mapviwe.deinit();
}
test "main" {
    var oldData = std.ArrayList(u8).init(std.testing.allocator);
    try oldData.append(1);
    var oldData2 = oldData;
    try oldData2.append(2);
    try std.testing.expectEqual(oldData.items.len, 1);
    try std.testing.expectEqual(oldData2.items.len, 2);
    //ArrayList赋值会拷贝一份ArrayList，两份ArrayList引用了同一片内存地址，所以只用掉一次deinit函数，对一个的修改胡影响另一个。
    // oldData.deinit();
    oldData2.deinit();
}
