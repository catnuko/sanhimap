const std = @import("std");
const Test = struct {
    slots: std.ArrayList(u8),
    fn new(alloc: std.mem.Allocator) Test {
        return .{ .slots = std.ArrayList(u8).init(alloc) };
    }
    fn getSlots(self: *Test) *std.ArrayList(u8) {
        return &self.slots;
    }
    fn deinit(self: *Test) void {
        self.slots.deinit();
    }
    fn printLen(self: *const Test) void {
        std.debug.print("{}", .{self.slots.items.len});
    }
};
const TT = struct {
    t: Test,
    fn new(alloc: std.mem.Allocator) TT {
        return .{ .t = Test.new(alloc) };
    }
};
pub fn boo(alloc: std.mem.Allocator) TT {
    return TT.new(alloc);
}
pub fn foo(alloc: std.mem.Allocator) Test {
    const t = Test.new(alloc);
    return t;
}
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    var t = boo(alloc);
    t.t.printLen();
}
