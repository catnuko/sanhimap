const std = @import("std");
const time = @import("std").time;
const sanhi = @import("./lib.zig");
const ecs = sanhi.ecs;
const sokol = sanhi.sokol;
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const plugins = sanhi.plugins;

pub const Plugin = struct {
    name: [:0]const u8,
    isUnique: bool = true,
    build: *const fn (app: *App) void,
    ready: ?*const fn (app: *App) void = null,
    finish: ?*const fn (app: *App) void = null,
    cleanup: ?*const fn (app: *App) void = null,
};
pub const AppConfig = struct {
    title: [:0]const u8 = "SanHi",
    width: i32 = 900,
    height: i32 = 900,
    target_fps: f32 = 60,
};

pub const AppContext = struct {
    app: *App,
};
pub const App = struct {
    world: *ecs.world_t,
    target_fps: f32,
    title: [:0]const u8 = "sanhi",
    width: i32 = 900,
    height: i32 = 900,
    plugin_registry: std.StringHashMap(Plugin),
    pub fn init(cfg: AppConfig) !App {
        sanhi.mem.init(sanhi.mem.createDefaultAllocator());
        const world = ecs.init();
        const appa = App{
            .title = cfg.title,
            .width = cfg.width,
            .height = cfg.height,
            .target_fps = cfg.target_fps,
            .world = world,
            .plugin_registry = std.StringHashMap(Plugin).init(sanhi.mem.getAllocator()),
        };
        return appa;
    }
    pub fn deinit(self: *App) void {
        self.plugin_registry.deinit();
        _ = ecs.fini(self.world);
        sanhi.mem.deinit();
    }
    pub fn add_plugin(self: *App, plugin: Plugin) !void {
        if (plugin.isUnique and self.plugin_registry.contains(plugin.name)) {
            unreachable;
        }
        self.plugin_registry.put(plugin.name, plugin) catch unreachable;
    }
    pub fn add_plugins(self: *App, pluginss: []Plugin) !void {
        for (pluginss) |plugin| {
            try self.add_plugin(plugin);
        }
    }
    pub fn finish(self: *App) void {
        const ps = self.plugin_registry.iterator();
        for (ps) |plugin| {
            if (plugin.finish) {
                plugin.finish(&self.app_backend);
            }
        }
    }
    pub fn cleanup(self: *App) void {
        const ps = self.plugin_registry.iterator();
        for (ps) |plugin| {
            if (plugin.cleanup) {
                plugin.cleanup(&self.app_backend);
            }
        }
    }
    pub fn getPlugin(self: *App, name: []const u8) ?Plugin {
        return self.plugin_registry.get(name);
    }
    pub fn get_width(self: *App) i32 {
        return self.app_backend.width;
    }
    pub fn get_height(self: *App) i32 {
        return self.app_backend.height;
    }
    pub fn run(self: *App) void {
        var desc = sanhi.flecs_addon.ecs_app_desc_t{
            .target_fps = self.target_fps,
        };
        var sokol_app_ctx = SokolAppContext{
            .world = self.world,
            .app = self,
            .desc = &desc,
        };

        sokol.app.run(.{
            .init_userdata_cb = sokol_init_action,
            .frame_userdata_cb = sokol_frame_action,
            .event_userdata_cb = sokol_input_action,
            .user_data = &sokol_app_ctx,
            .width = self.width,
            .height = self.height,
            .icon = .{ .sokol_default = true },
            .window_title = self.title,
            .logger = .{ .func = sokol.log.func },
        });
    }
};
export fn sokol_init_action(c: ?*anyopaque) void {
    const ctx: *SokolAppContext = @ptrCast(@alignCast(c));
    sg.setup(.{
        .pipeline_pool_size = 20,
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });
    var ps = ctx.app.plugin_registry.iterator();
    while (ps.next()) |entry| {
        entry.value_ptr.build(ctx.app);
    }
}
export fn sokol_input_action(e: [*c]const sokol.app.Event, c: ?*anyopaque) void {
    const ctx: *SokolAppContext = @ptrCast(@alignCast(c));
    const world = ctx.world;
    var input = ecs.singleton_get_mut(world, plugins.input.EcsInput).?;
    const evt = e.*;
    switch (evt.type) {
        sokol.app.EventType.MOUSE_DOWN => {
            if (evt.mouse_button == sokol.app.Mousebutton.LEFT) {
                mouse_down(&input.mouse.left);
            }
            if (evt.mouse_button == sokol.app.Mousebutton.RIGHT) {
                mouse_down(&input.mouse.right);
            }
        },
        sokol.app.EventType.MOUSE_UP => {
            if (evt.mouse_button == sokol.app.Mousebutton.LEFT) {
                mouse_up(&input.mouse.left);
            }

            if (evt.mouse_button == sokol.app.Mousebutton.RIGHT) {
                mouse_up(&input.mouse.right);
            }
        },
        sokol.app.EventType.MOUSE_SCROLL => {},
        sokol.app.EventType.KEY_UP => key_up(key_get(input, @intCast(key_code(evt.key_code)))),
        sokol.app.EventType.KEY_DOWN => key_down(key_get(input, @intCast(key_code(evt.key_code)))),
        sokol.app.EventType.RESIZED => {},
        else => {},
    }
}
fn key_get(input: *plugins.input.EcsInput, key: usize) *plugins.input.ecs_key_state_t {
    return &input.keys[key];
}
fn key_down(key: *plugins.input.ecs_key_state_t) void {
    if (key.state) {
        key.down = false;
    } else {
        key.down = true;
    }

    key.state = true;
    key.current = true;
}

fn key_up(key: *plugins.input.ecs_key_state_t) void {
    key.current = false;
}

fn key_reset(state: *plugins.input.ecs_key_state_t) void {
    if (!state.current) {
        state.state = false;
        state.down = false;
    } else if (state.state) {
        state.down = false;
    }
}

fn keys_reset(input: *plugins.input.EcsInput) void {
    for (0..128) |i| {
        key_reset(&input.keys[i]);
    }
}

fn mouse_down(mouse: *plugins.input.ecs_key_state_t) void {
    if (mouse.state) {
        mouse.down = false;
    } else {
        mouse.down = true;
    }

    mouse.state = true;
    mouse.current = true;
}
fn mouse_up(mouse: *plugins.input.ecs_key_state_t) void {
    mouse.current = false;
}
pub const SokolAppContext = struct {
    world: *ecs.world_t,
    app: *App,
    desc: *sanhi.flecs_addon.ecs_app_desc_t,
};

fn mouse_button_reset(mouse: *plugins.input.ecs_key_state_t) void {
    if (!mouse.current) {
        mouse.state = false;
        mouse.down = false;
    } else if (mouse.state) {
        mouse.down = false;
    }
}
fn mouse_reset(input: *plugins.input.EcsInput) void {
    mouse_button_reset(&input.mouse.left);
    mouse_button_reset(&input.mouse.right);
}
export fn sokol_frame_action(c: ?*anyopaque) void {
    const ctx: *SokolAppContext = @ptrCast(@alignCast(c));
    if (ecs.should_quit(ctx.world)) {
        sokol.app.quit();
    }
    _ = sanhi.flecs_addon.app_run_frame(ctx.world, ctx.desc);
    const input = ecs.singleton_get_mut(ctx.world, plugins.input.EcsInput).?;
    keys_reset(input);
    mouse_reset(input);
}
pub const ECS_KEY_UNKNOWN = 0;
pub const ECS_KEY_RETURN = '\r';
pub const ECS_KEY_ESCAPE = '\x1B';
pub const ECS_KEY_BACKSPACE = '\x08';
pub const ECS_KEY_TAB = '\t';
pub const ECS_KEY_SPACE = ' ';
pub const ECS_KEY_EXCLAIM = '!';
pub const ECS_KEY_QUOTEDBL = '"';
pub const ECS_KEY_HASH = '#';
pub const ECS_KEY_PERCENT = '%';
pub const ECS_KEY_DOLLAR = '$';
pub const ECS_KEY_AMPERSAND = '&';
pub const ECS_KEY_QUOTE = '\'';
pub const ECS_KEY_LEFT_PAREN = '(';
pub const ECS_KEY_RIGHT_PAREN = ')';
pub const ECS_KEY_ASTERISK = '*';
pub const ECS_KEY_PLUS = '+';
pub const ECS_KEY_COMMA = ',';
pub const ECS_KEY_MINUS = '-';
pub const ECS_KEY_PERIOD = '.';
pub const ECS_KEY_SLASH = '/';

pub const ECS_KEY_0 = '0';
pub const ECS_KEY_1 = '1';
pub const ECS_KEY_2 = '2';
pub const ECS_KEY_3 = '3';
pub const ECS_KEY_4 = '4';
pub const ECS_KEY_5 = '5';
pub const ECS_KEY_6 = '6';
pub const ECS_KEY_7 = '7';
pub const ECS_KEY_8 = '8';
pub const ECS_KEY_9 = '9';

pub const ECS_KEY_COLON = ':';
pub const ECS_KEY_SEMICOLON = ';';
pub const ECS_KEY_LESS = '<';
pub const ECS_KEY_EQUAL = '=';
pub const ECS_KEY_GREATER = '>';
pub const ECS_KEY_QUESTION = '?';
pub const ECS_KEY_AT = '@';
pub const ECS_KEY_LEFT_BRACKET = '[';
pub const ECS_KEY_RIGHT_BRACKET = ']';
pub const ECS_KEY_BACKSLASH = '\\';
pub const ECS_KEY_CARET = '^';
pub const ECS_KEY_UNDERSCORE = '_';
pub const ECS_KEY_GRAVE_ACCENT = '`';
pub const ECS_KEY_APOSTROPHE = '\'';

pub const ECS_KEY_A = 'a';
pub const ECS_KEY_B = 'b';
pub const ECS_KEY_C = 'c';
pub const ECS_KEY_D = 'd';
pub const ECS_KEY_E = 'e';
pub const ECS_KEY_F = 'f';
pub const ECS_KEY_G = 'g';
pub const ECS_KEY_H = 'h';
pub const ECS_KEY_I = 'i';
pub const ECS_KEY_J = 'j';
pub const ECS_KEY_K = 'k';
pub const ECS_KEY_L = 'l';
pub const ECS_KEY_M = 'm';
pub const ECS_KEY_N = 'n';
pub const ECS_KEY_O = 'o';
pub const ECS_KEY_P = 'p';
pub const ECS_KEY_Q = 'q';
pub const ECS_KEY_R = 'r';
pub const ECS_KEY_S = 's';
pub const ECS_KEY_T = 't';
pub const ECS_KEY_U = 'u';
pub const ECS_KEY_V = 'v';
pub const ECS_KEY_W = 'w';
pub const ECS_KEY_X = 'x';
pub const ECS_KEY_Y = 'y';
pub const ECS_KEY_Z = 'z';
pub const ECS_KEY_DELETE = 127;

pub const ECS_KEY_RIGHT = 'R';
pub const ECS_KEY_LEFT = 'L';
pub const ECS_KEY_DOWN = 'D';
pub const ECS_KEY_UP = 'U';
pub const ECS_KEY_LEFT_CTRL = 'C';
pub const ECS_KEY_LEFT_ALT = 'A';
pub const ECS_KEY_LEFT_SHIFT = 'S';
pub const ECS_KEY_RIGHT_CTRL = 'T';
pub const ECS_KEY_RIGHT_ALT = 'Z';
pub const ECS_KEY_RIGHT_SHIFT = 'H';
pub const ECS_KEY_INSERT = 'I';
pub const ECS_KEY_HOME = 'H';
pub const ECS_KEY_END = 'E';
pub const ECS_KEY_PAGE_UP = 'O';
pub const ECS_KEY_PAGE_DOWN = 'P';

fn key_code(sokol_key: sokol.app.Keycode) i32 {
    switch (sokol_key) {
        sokol.app.Keycode.SPACE => return ECS_KEY_SPACE,
        sokol.app.Keycode.APOSTROPHE => return ECS_KEY_APOSTROPHE,
        sokol.app.Keycode.COMMA => return ECS_KEY_COMMA,
        sokol.app.Keycode.MINUS => return ECS_KEY_MINUS,
        sokol.app.Keycode.PERIOD => return ECS_KEY_PERIOD,
        sokol.app.Keycode.SLASH => return ECS_KEY_SLASH,
        sokol.app.Keycode._0 => return ECS_KEY_0,
        sokol.app.Keycode._1 => return ECS_KEY_1,
        sokol.app.Keycode._2 => return ECS_KEY_2,
        sokol.app.Keycode._3 => return ECS_KEY_3,
        sokol.app.Keycode._4 => return ECS_KEY_4,
        sokol.app.Keycode._5 => return ECS_KEY_5,
        sokol.app.Keycode._6 => return ECS_KEY_6,
        sokol.app.Keycode._7 => return ECS_KEY_7,
        sokol.app.Keycode._8 => return ECS_KEY_8,
        sokol.app.Keycode._9 => return ECS_KEY_9,
        sokol.app.Keycode.SEMICOLON => return ECS_KEY_SEMICOLON,
        sokol.app.Keycode.EQUAL => return ECS_KEY_EQUAL,
        sokol.app.Keycode.A => return ECS_KEY_A,
        sokol.app.Keycode.B => return ECS_KEY_B,
        sokol.app.Keycode.C => return ECS_KEY_C,
        sokol.app.Keycode.D => return ECS_KEY_D,
        sokol.app.Keycode.E => return ECS_KEY_E,
        sokol.app.Keycode.F => return ECS_KEY_F,
        sokol.app.Keycode.G => return ECS_KEY_G,
        sokol.app.Keycode.H => return ECS_KEY_H,
        sokol.app.Keycode.I => return ECS_KEY_I,
        sokol.app.Keycode.J => return ECS_KEY_J,
        sokol.app.Keycode.K => return ECS_KEY_K,
        sokol.app.Keycode.L => return ECS_KEY_L,
        sokol.app.Keycode.M => return ECS_KEY_M,
        sokol.app.Keycode.N => return ECS_KEY_N,
        sokol.app.Keycode.O => return ECS_KEY_O,
        sokol.app.Keycode.P => return ECS_KEY_P,
        sokol.app.Keycode.Q => return ECS_KEY_Q,
        sokol.app.Keycode.R => return ECS_KEY_R,
        sokol.app.Keycode.S => return ECS_KEY_S,
        sokol.app.Keycode.T => return ECS_KEY_T,
        sokol.app.Keycode.U => return ECS_KEY_U,
        sokol.app.Keycode.V => return ECS_KEY_V,
        sokol.app.Keycode.W => return ECS_KEY_W,
        sokol.app.Keycode.X => return ECS_KEY_X,
        sokol.app.Keycode.Y => return ECS_KEY_Y,
        sokol.app.Keycode.Z => return ECS_KEY_Z,
        sokol.app.Keycode.LEFT_BRACKET => return ECS_KEY_LEFT_BRACKET,
        sokol.app.Keycode.BACKSLASH => return ECS_KEY_BACKSLASH,
        sokol.app.Keycode.RIGHT_BRACKET => return ECS_KEY_RIGHT_BRACKET,
        sokol.app.Keycode.GRAVE_ACCENT => return ECS_KEY_GRAVE_ACCENT,
        sokol.app.Keycode.ESCAPE => return ECS_KEY_ESCAPE,
        sokol.app.Keycode.ENTER => return ECS_KEY_RETURN,
        sokol.app.Keycode.TAB => return ECS_KEY_TAB,
        sokol.app.Keycode.BACKSPACE => return ECS_KEY_BACKSPACE,
        sokol.app.Keycode.INSERT => return ECS_KEY_INSERT,
        sokol.app.Keycode.DELETE => return ECS_KEY_DELETE,
        sokol.app.Keycode.RIGHT => return ECS_KEY_RIGHT,
        sokol.app.Keycode.LEFT => return ECS_KEY_LEFT,
        sokol.app.Keycode.DOWN => return ECS_KEY_DOWN,
        sokol.app.Keycode.UP => return ECS_KEY_UP,
        sokol.app.Keycode.PAGE_UP => return ECS_KEY_PAGE_UP,
        sokol.app.Keycode.PAGE_DOWN => return ECS_KEY_PAGE_DOWN,
        sokol.app.Keycode.HOME => return ECS_KEY_HOME,
        sokol.app.Keycode.END => return ECS_KEY_END,
        sokol.app.Keycode.LEFT_SHIFT => return ECS_KEY_LEFT_SHIFT,
        sokol.app.Keycode.LEFT_CONTROL => return ECS_KEY_LEFT_CTRL,
        sokol.app.Keycode.LEFT_ALT => return ECS_KEY_LEFT_ALT,
        sokol.app.Keycode.RIGHT_SHIFT => return ECS_KEY_RIGHT_SHIFT,
        sokol.app.Keycode.RIGHT_CONTROL => return ECS_KEY_RIGHT_CTRL,
        sokol.app.Keycode.RIGHT_ALT => return ECS_KEY_RIGHT_ALT,
        else => return ECS_KEY_UNKNOWN,
    }
}
