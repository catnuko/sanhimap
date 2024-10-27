const backend = @import("./backend.zig");
const modules = @import("./modules.zig");
const mem = @import("./mem.zig");
const std = @import("std");
const time = @import("std").time;

const NS_PER_SECOND: i64 = 1_000_000_000;
const NS_PER_SECOND_F: f32 = 1_000_000_000.0;
const NS_FPS_LIMIT_OVERHEAD = 1_250_000; // tuned to ensure consistent frame pacing

const DeltaTime = struct {
    f_delta_time: f32,
    ns_delta_time: u64,
};

const updateState = struct {
    // FPS cap vars, if set
    var target_fps: ?u64 = null;
    var target_fps_ns: u64 = undefined;

    // Fixed timestep length - defaults to 40 per second
    var fixed_timestep_delta_ns: ?u64 = @intFromFloat((1.0 / 40.0) * NS_PER_SECOND_F);
    var fixed_timestep_delta_f: f32 = 1.0 / 40.0;
    var fixed_timestep_lerp: f32 = 0.0;

    // game loop timers
    var game_loop_timer: time.Timer = undefined;
    var fps_update_timer: time.Timer = undefined;
    var did_limit_fps: bool = false;

    // delta time vars
    var reset_delta: bool = true;

    // fixed tick game loops need to keep track of a time accumulator
    var time_accumulator_ns: u64 = 0;

    // current fps, updated every second
    var fps: i32 = 0;
    var fps_framecount: i64 = 0;

    // current tick
    var tick: u64 = 0;

    // current delta time
    var delta_time: f32 = 0.0;

    // current elapsed time
    var game_time: f64 = 0.0;

    var mouse_captured: bool = false;

    const Self = @This();
    pub fn resetDeltaTime() void {
        reset_delta = true;
    }
    pub fn setTargetFPS(fps_target: i32) void {
        target_fps = @intCast(fps_target);
        const target_fps_f: f64 = @floatFromInt(target_fps.?);
        target_fps_ns = @intFromFloat((1.0 / target_fps_f) * NS_PER_SECOND);
    }
    pub fn setFixedTimestep(timestep_delta: f32) void {
        fixed_timestep_delta_ns = @intFromFloat(timestep_delta * NS_PER_SECOND_F);
        fixed_timestep_delta_f = timestep_delta;
    }
    pub fn getFixedTimestepLerp(include_delta: bool) f32 {
        if (include_delta)
            return fixed_timestep_delta_f * fixed_timestep_lerp;

        return fixed_timestep_lerp;
    }
    fn calcDeltaTime() DeltaTime {
        if (reset_delta) {
            reset_delta = false;
            game_loop_timer.reset();
            return DeltaTime{ .f_delta_time = 1.0 / 60.0, .ns_delta_time = 60 / NS_PER_SECOND };
        }

        // calculate the fps by counting frames each second
        const nanos_since_tick = game_loop_timer.lap();
        const nanos_since_fps = fps_update_timer.read();

        if (nanos_since_fps >= NS_PER_SECOND) {
            fps = @intCast(fps_framecount);
            fps_update_timer.reset();
            fps_framecount = 0;
        }

        // if(did_limit_fps) {
        //     return DeltaTime{
        //         .f_delta_time = (@as(f32, @floatFromInt(target_fps_ns)) / NS_PER_SECOND_F),
        //         .ns_delta_time = target_fps_ns,
        //     };
        // }

        return DeltaTime{
            .f_delta_time = @as(f32, @floatFromInt(nanos_since_tick)) / NS_PER_SECOND_F,
            .ns_delta_time = nanos_since_tick,
        };
    }

    fn limitFps() bool {
        if (target_fps == null)
            return false;

        // Try to hit our target FPS!

        // Easy case, just stop here if we are under the target frame length
        const initial_frame_ns = game_loop_timer.read();
        if (initial_frame_ns >= target_fps_ns)
            return false;

        // Harder case, we are faster than the target frame length.
        // Note: time.sleep does not ensure consistent timing.
        // Due to this we need to sleep most of the time, but busy loop the rest.

        const frame_len_ns = initial_frame_ns + NS_FPS_LIMIT_OVERHEAD;
        if (frame_len_ns < target_fps_ns) {
            time.sleep(target_fps_ns - frame_len_ns);
        }

        // Eat up the rest of the time in a busy loop to ensure consistent frame pacing
        while (true) {
            const cur_frame_len_ns = game_loop_timer.read();
            if (cur_frame_len_ns + 500 >= target_fps_ns)
                break;
        }

        return true;
    }
};
var app_backend: backend.AppBackend = undefined;
pub const AppConfig = struct {
    title: [:0]const u8 = "SanHi",
    width: i32 = 900,
    height: i32 = 600,

    target_fps: ?i32 = null,
    use_fixed_timestep: bool = false,
    fixed_timestep_delta: f32 = 1.0 / 60.0,
};
pub fn init(cfg: AppConfig) !void {
    mem.init(mem.createDefaultAllocator());
    std.debug.print("App platform starting\n", .{});
    app_backend = backend.AppBackend{
        .on_init_fn = on_init,
        .on_deinit_fn = on_deinit,
        .on_update_fn = on_update,
        .width = cfg.width,
        .height = cfg.height,
        .title = cfg.title,
    };

    updateState.game_loop_timer = try time.Timer.start();
    updateState.fps_update_timer = try time.Timer.start();

    if (cfg.target_fps) |target|
        updateState.setTargetFPS(target);

    if (cfg.use_fixed_timestep)
        updateState.setFixedTimestep(cfg.fixed_timestep_delta);
    try app_backend.init(mem.getAllocator());
}
pub fn addPlugin(plugin: anytype) !void {
    try modules.registerModule(&app_backend, plugin.module());
}
pub fn deinit() void {
    std.debug.print("App platform stopping", .{});
    app_backend.deinit();
    mem.deinit();
}

fn on_init() void {
    modules.startModules();
}

pub fn startMainLoop() void {
    app_backend.startMainLoop();
}

fn on_deinit() void {
    modules.stopModules();
    modules.cleanupModules();
    modules.deinit();
}

fn on_update() void {
    // time management!
    const delta = updateState.calcDeltaTime();
    updateState.delta_time = delta.f_delta_time;
    updateState.game_time += updateState.delta_time;

    updateState.tick += 1;
    updateState.fps_framecount += 1;

    if (updateState.fixed_timestep_delta_ns) |fixed_delta_ns| {
        updateState.time_accumulator_ns += delta.ns_delta_time;

        // keep ticking until we catch up to the actual time
        while (updateState.time_accumulator_ns >= fixed_delta_ns) {
            // fixed timestamp, tick at our constant rate
            modules.fixedTickModules(updateState.fixed_timestep_delta_f);
            updateState.time_accumulator_ns -= fixed_delta_ns;
        }

        // store how far to the next fixed timestep we are
        updateState.fixed_timestep_lerp = @as(f32, @floatFromInt(updateState.time_accumulator_ns)) / @as(f32, @floatFromInt(fixed_delta_ns));
    }

    modules.tickModules(updateState.delta_time);
    // tell modules we are getting ready to draw!
    modules.preDrawModules(&app_backend);

    // then draw!
    modules.drawModules(&app_backend);

    // tell modules this frame is done
    modules.postDrawModules(&app_backend);

    // keep under our FPS limit, if needed
    updateState.did_limit_fps = updateState.limitFps();
}
