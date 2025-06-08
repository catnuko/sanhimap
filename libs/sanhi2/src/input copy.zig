const lib = @import("./lib.zig");
const mem = @import("./mem.zig");
const zglfw = lib.zglfw;
const plugins = lib.plugins;
const math = lib.math;
const backend = lib.backend;
const std = lib.std;

const state = struct {
    var mouse: [2]f64 = .{ 0, 0 };
    var lastMouse: [2]f64 = .{ 0, 0 };
    var delta: [2]f64 = .{ 0, 0 };
};
const ListenerList = std.ArrayList(*const fn (point: [2]f64) void);
var leftClickEventListenerList: ListenerList = undefined;
var middleClickEventListenerList: ListenerList = undefined;
var rightClickEventListenerList: ListenerList = undefined;
var mouseMoveEventListenerList: ListenerList = undefined;

pub fn init(_: *backend.AppBackend) !void {
    const allocator = mem.getAllocator();
    leftClickEventListenerList = ListenerList.init(allocator);
    middleClickEventListenerList = ListenerList.init(allocator);
    rightClickEventListenerList = ListenerList.init(allocator);
    mouseMoveEventListenerList = ListenerList.init(allocator);
}
pub fn deinit() !void {
    leftClickEventListenerList.deinit();
    middleClickEventListenerList.deinit();
    rightClickEventListenerList.deinit();
    mouseMoveEventListenerList.deinit();
}
pub fn addEventListener(ty: []const u8, func: *const fn (point: [2]f64) void) void {
    if (std.mem.eql(u8, ty, "left")) {
        leftClickEventListenerList.append(func) catch unreachable;
    } else if (std.mem.eql(u8, ty, "middle")) {
        middleClickEventListenerList.append(func) catch unreachable;
    } else if (std.mem.eql(u8, ty, "right")) {
        rightClickEventListenerList.append(func) catch unreachable;
    } else if (std.mem.eql(u8, ty, "mousemove")) {
        mouseMoveEventListenerList.append(func) catch unreachable;
    }
}
pub fn removeEventListener(ty: []const u8, func: *const fn (point: [2]f64) void) bool {
    var i: usize = -1;
    var list: ListenerList = undefined;
    if (std.mem.eql(u8, ty, "left")) {
        list = leftClickEventListenerList;
    } else if (std.mem.eql(u8, ty, "middle")) {
        list = middleClickEventListenerList;
    } else if (std.mem.eql(u8, ty, "right")) {
        list = rightClickEventListenerList;
    } else if (std.mem.eql(u8, ty, "mousemove")) {
        list = mouseMoveEventListenerList;
    }

    for (list.items, 0..) |innerFunc, j| {
        if (innerFunc == func) {
            i = j;
            break;
        }
    }
    if (i != -1) {
        list.swapRemove(i);
        return true;
    }
    return false;
}
/// Registers the input subsystem as a plugin
pub fn plugin() plugins.Plugin {
    const inputSubsystem = plugins.Plugin{
        .name = "input",
        .pre_draw_fn = on_update,
        .init_fn = init,
        .cleanup_fn = deinit,
    };
    return inputSubsystem;
}
var isLeftPress: bool = false;
var isMiddlePress: bool = false;
var isRightPress: bool = false;
var mouseInWindow: bool = false;
pub fn on_update(appBackend: *backend.AppBackend) void {
    const window: *zglfw.Window = appBackend.window;
    const cursor_pos = window.getCursorPos();
    switch (window.getMouseButton(.left)) {
        .press => isLeftPress = true,
        .release => {
            if (isLeftPress) {
                for (leftClickEventListenerList.items) |func| {
                    func(cursor_pos);
                }
                isLeftPress = false;
            }
        },
        else => {},
    }
    switch (window.getMouseButton(.middle)) {
        .press => isMiddlePress = true,
        .release => {
            if (isMiddlePress) {
                for (middleClickEventListenerList.items) |func| {
                    func(cursor_pos);
                }
                isMiddlePress = false;
            }
        },
        else => {},
    }
    switch (window.getMouseButton(.right)) {
        .press => isRightPress = true,
        .release => {
            if (isRightPress) {
                for (rightClickEventListenerList.items) |func| {
                    func(cursor_pos);
                }
                isRightPress = false;
            }
        },
        else => {},
    }
    if (mouseMoveEventListenerList.items.len == 0) return;
    const size = window.getSize();
    const dif_x = cursor_pos[0] - @as(f64, @floatFromInt(size[0]));
    const dif_y = cursor_pos[1] - @as(f64, @floatFromInt(size[1]));
    if (dif_x <= 0 and dif_y <= 0) {
        mouseInWindow = true;
        for (mouseMoveEventListenerList.items) |func| {
            func(cursor_pos);
        }
    } else {
        mouseInWindow = false;
    }
}
