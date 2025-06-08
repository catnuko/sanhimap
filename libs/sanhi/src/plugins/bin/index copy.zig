const sanhi = @import("../../lib.zig");
const ecs = sanhi.ecs;
const sokol = sanhi.sokol;
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const math = sanhi.math;
const std = sanhi.std;
const scene = @import("./scene.zig");
const utils = @import("./utils.zig");
const com = @import("./com.zig");
const us = @import("./uniformState.zig");
const RenderState = @import("./RenderState.zig").RenderState;
const resource = @import("./resource.zig");

const render_name = "render.render";
///获取带有Query(Geometry)的Renderer实体，执行绘制命令
fn render(it: *ecs.iter_t) callconv(.C) void {
    const world = it.world;
    const renderer = ecs.field(it, com.Renderer, 0).?[0];
    const q_buffers = ecs.field(it, com.Query, 1).?[0];
    var state: RenderState = .{};
    const canvas = ecs.get(world, renderer.canvas, com.Canvas).?;
    state.camera = ecs.get(world, canvas.camera, com.Camera).?;
    us.initGlobeUniforms(state.camera, state.uniforms);
    scene.run_scene_pass(renderer.scene_pass, state);
}

pub const plugin_name = "render";
fn module(world: *ecs.world_t) callconv(.C) void {
    var desc = ecs.component_desc_t{ .entity = 0, .type = .{ .size = 0, .alignment = 0 } };
    _ = ecs.module_init(world, plugin_name, &desc);
    com.init_component(world);
    // ecs.COMPONENT(world, Canvas);
    const canvas = com.Canvas{
        .width = 900,
        .height = 600,
        .label = "mycanvas",
    };
    ecs.singleton_set(world, com.Canvas, canvas);
    //初始化Geometry
    const boxGeometry = ecs.new_entity(world, "boxGeometry");
    ecs.set(world, boxGeometry, com.Geometry, com.Geometry{
        .vertices = resource.sokol_buffer_box(),
        .indices = resource.sokol_buffer_box_indices(),
        .normals = resource.sokol_buffer_box_normals(),
        .index_count = resource.sokol_box_index_count(),
    });
    ecs.set(world, boxGeometry, com.GeometryQuery, com.GeometryQuery{
        .component = ecs.id(com.Box),
    });

    //RendererInst实体
    const RendererInst = ecs.new_entity(world, "RendererInst");
    ecs.set(world, RendererInst, com.Renderer, com.Renderer{
        .bg_texture = make_bg_texture(canvas.background_color, canvas.width, canvas.height),
        .scene_pass = scene.init_scene_pass(canvas.background_color, canvas.width, canvas.height, 1),
        .canvas = ecs.singleton_get(world, com.Canvas),
    });
    //为Renderer设置Materails组件
    ecs.set(world, RendererInst, com.Materials, com.Materials{ .changed = true });
    //为Renderer设置一个Query(Geometry)的查询租金
    ecs.set_pair(world, RendererInst, com.Query, ecs.id(com.Geometry), com.Query, com.Query{
        .query = ecs.query_init(world, .{ .expr = "[in] render.Geometry" }),
    });

    {
        var system_desc = ecs.system_desc_t{};
        system_desc.callback = render;
        system_desc.query.expr = "render.Renderer,(render.Query,render.Geometry)";
        _ = ecs.SYSTEM(world, render_name, ecs.OnStore, &system_desc);
    }
}

fn build(app: *sanhi.app.App) void {
    _ = ecs.import_c(app.world, module, plugin_name);
}
pub const plugin = sanhi.app.Plugin{
    .name = plugin_name,
    .build = build,
};

pub fn make_bg_texture(color: sg.Color, width: i32, height: i32) sg.Image {
    const img = sg.makeImage(.{
        .width = width,
        .height = height,
        .wrap_u = sg.Wrap.CLAMP_TO_EDGE,
        .wrap_v = sg.Wrap.CLAMP_TO_EDGE,
        .pixel_format = sg.PixelFormat.RGBA8,
        .label = "Background texture",
        .data = init: {
            var data = sg.ImageData{};
            data.subimage[0][0] = sg.asRange(&pixels: {
                var res = std.mem.zeroes([width][height]u32);
                for (0..height) |y| {
                    for (0..width) |x| {
                        const r: u32 = @intFromFloat(color.r * 256);
                        var g: u32 = @intFromFloat(color.g * 256);
                        g <<= 8;
                        var b: u32 = @intFromFloat(color.b * 256);
                        b <<= 16;
                        var a: u32 = @intFromFloat(255);
                        a <<= 24;
                        const c = r | g | b | a;

                        res[y][x] = c;
                    }
                }
                break :pixels res;
            });
            break :init data;
        },
    });

    return img;
}
