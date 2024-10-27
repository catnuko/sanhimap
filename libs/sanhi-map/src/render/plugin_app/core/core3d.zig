const render = @import("../index.zig");
const graph = render.graph;
const App = render.App;
const core = render.core;
const Plugin = render.Plugin;
pub const CORE_3D = struct {
    pub const NAME: []const u8 = "core3d";
    pub const PREPASS: []const u8 = "prepass";
    pub const START_MAIN_PASS: []const u8 = "start_main_pass";
    pub const MAIN_OPAQUE_PASS: []const u8 = "main_opaque_pass";
    pub const MAIN_TRANSPARENT_PASS: []const u8 = "main_transparent_pass";
    pub const END_MAIN_PASS: []const u8 = "end_main_pass";
};

pub const Core3dPlugin = struct {
    const Self = @This();
    pub fn new() Self {
        return .{};
    }
    pub fn build(_: *anyopaque, app: *App) void {
        app.addSubGraph(CORE_3D.NAME);

        var prepass = core.PrepassNode.new(app.alloc);
        app.addNode(CORE_3D.NAME, prepass.node(CORE_3D.PREPASS));

        var startMainPass = core.MainNode.new(app.alloc);
        app.addNode(CORE_3D.NAME, startMainPass.node(CORE_3D.START_MAIN_PASS));

        var mainpass = core.MainNode.new(app.alloc);
        app.addNode(CORE_3D.NAME, mainpass.node(CORE_3D.MAIN_OPAQUE_PASS));

        var endMainPass = graph.EmptyNode.new(app.alloc);
        app.addNode(CORE_3D.NAME, endMainPass.node(CORE_3D.END_MAIN_PASS));

        var edges = app.alloc.alloc([]const u8, 4) catch unreachable;
        defer app.alloc.free(edges);
        edges[0] = CORE_3D.PREPASS;
        edges[1] = CORE_3D.START_MAIN_PASS;
        edges[2] = CORE_3D.MAIN_OPAQUE_PASS;
        edges[3] = CORE_3D.END_MAIN_PASS;
        app.addEdges(
            CORE_3D.NAME,
            edges,
        );
    }
    pub fn setup(_: *anyopaque, _: *App) void {}
    pub fn plugin(
        self: *Self,
    ) Plugin {
        return Plugin.new(
            @typeName(Self),
            self,
            &.{
                .build = build,
                .setup = setup,
            },
        );
    }
};
