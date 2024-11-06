const std = @import("std");
const CallbackFunc = *const fn (userdata: ?*anyopaque) void;
const Callback = struct {
    name: []const u8,
    func: CallbackFunc,
    id: u32,
};
const ListenerList = std.ArrayList(Callback);
const Self = @This();
listeners: ListenerList,
id: u32 = 0,
pub fn new(allocator: std.mem.Allocator) Self {
    return .{
        .listeners = ListenerList.init(allocator),
    };
}
pub fn deinit(self: *Self) void {
    self.listeners.deinit();
    self.id = 0;
}
pub fn on(self: *Self, name: []const u8, func: CallbackFunc) u32 {
    const id = self.id;
    self.id += 1;
    self.listeners.append(.{ .id = id, .name = name, .func = func }) catch unreachable;
    return id;
}
pub fn emit(self: *Self, name: []const u8, userData: ?*anyopaque) void {
    for (self.listeners.items) |callback| {
        if (std.mem.eql(u8, name, callback.name)) {
            callback.func(userData);
        }
    }
}
pub fn off(self: *Self, id: u32) bool {
    var get_it: bool = false;
    var targetIndex: usize = 0;
    for (self.listeners.items, 0..) |callback, i| {
        if (callback.id == id) {
            targetIndex = i;
            get_it = true;
            break;
        }
    }
    if (get_it) {
        _ = self.listeners.swapRemove(targetIndex);
        return true;
    } else {
        return false;
    }
}
