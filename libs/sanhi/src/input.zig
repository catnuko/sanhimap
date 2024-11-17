const lib = @import("./lib.zig");
const modules = lib.modules;
const zglfw = lib.zglfw;
const math = @import("math");
const Vector2D = math.Vector2D;
const Vector3D = math.Vector3D;
const Mat4 = math.Matrix4;
const Mat3 = math.Matrix3D;
const QuaternionD = math.QuaternionD;
const MouseButton = zglfw.MouseButton;
const Action = zglfw.Action;
const Window = zglfw.Window;
const Mods = zglfw.Mods;
const Event = lib.Event;
pub var event: Event = undefined;

pub const MouseEvent = extern struct {
    button: MouseButton,
    ctrlKey: bool = false,
    shiftKey: bool = false,
    metaKey: bool = false,
    clientX: f32,
    clientY: f32,
};
fn on_mouse_button(window: *Window, button: MouseButton, action: Action, mod: Mods) callconv(.C) void {
    const cursor_pos = window.getCursorPos();
    const clientX = @as(f32, @floatCast(cursor_pos[0]));
    const clientY = @as(f32, @floatCast(cursor_pos[1]));
    var userData = MouseEvent{
        .button = button,
        .ctrlKey = mod.control,
        .shiftKey = mod.shift,
        .clientX = clientX,
        .clientY = clientY,
    };
    if (action == Action.press) {
        // lib.print("mousedown:{},{}\n",.{clientX,clientY});
        // const size = window.getSize();
        // lib.print("getSize:{},{}\n",.{size[0],size[1]});
        // const pos = window.getPos();
        // lib.print("getPos:{},{}\n",.{pos[0],pos[1]});
        event.emit("mousedown", &userData);
    } else if (action == Action.release) {
        // lib.print("mouseup:{},{}\n",.{clientX,clientY});
        event.emit("mouseup", &userData);
    }
}
pub const MouseMove = struct {
    clientX: f32,
    clientY: f32,
};
fn on_mouse_move(_: *Window, xpos: f64, ypos: f64) callconv(.C) void {
    const clientX = @as(f32, @floatCast(xpos));
    const clientY = @as(f32, @floatCast(ypos));
    var userData = MouseMove{
        .clientX = clientX,
        .clientY = clientY,
    };
    // lib.print("mousemove:{},{}\n",.{clientX,clientY});
    event.emit("mousemove", &userData);
}
pub const ScrollEvent = struct {
    xoffset: f32,
    yoffset: f32,
};
fn on_scroll(_: *Window, xoffset: f64, yoffset: f64) callconv(.C) void {
    var userData = ScrollEvent{
        .xoffset = @as(f32, @floatCast(xoffset)),
        .yoffset = @as(f32, @floatCast(yoffset)),
    };
    // lib.print("wheel:{},{}\n",.{userData.xoffset,userData.yoffset});
    event.emit("wheel", &userData);
}
pub fn init(app_backend: *lib.backend.AppBackend) !void {
    const alloc = lib.mem.getAllocator();
    event = Event.new(alloc);
    _ = app_backend.window.setMouseButtonCallback(on_mouse_button);
    _ = app_backend.window.setCursorPosCallback(on_mouse_move);
    _ = app_backend.window.setScrollCallback(on_scroll);
}
pub fn deinit() !void {
    event.deinit();
}
pub fn module() modules.Module {
    const inputSubsystem = modules.Module{
        .name = "input",
        .init_fn = init,
        .cleanup_fn = deinit,
    };
    return inputSubsystem;
}
