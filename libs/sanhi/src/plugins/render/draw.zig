const sanhi = @import("../../lib.zig");
const ecs = sanhi.ecs;
const sokol = sanhi.sokol;
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const math = sanhi.math;
const std = sanhi.std;
const zmesh = sanhi.zmesh;
const cube_glsl = @import("../../shaders/cube.main.zig");
pub const GpuPass = struct {
    v: sg.Pass,
    pub const name = "render.GpuPass";
};
pub const GpuBinding = struct {
    v: sg.Bindings,
    base_element: u32 = 0,
    num_elements: u32,
    num_instances: u32 = 1,
    pub const name = "render.GpuBinding";
};
pub const GpuPipeline = struct {
    v: sg.Pipeline,
    pub const name = "render.GpuPipeline";
};
pub const GpuUniforms = struct {
    us: cube_glsl.VsCommon,
    pub const name = "render.GpuUniforms";
};
pub const draw_element_name = "render.draw_element";
fn draw_element(it: *ecs.iter_t) callconv(.C) void {
    const passCols = ecs.field(it, GpuPass, 0).?;
    const pipCols = ecs.field(it, GpuPipeline, 1).?;
    const usCols = ecs.field(it, GpuUniforms, 2).?;
    const bindCols = ecs.field(it, GpuBinding, 3).?;
    for (0..it.count()) |i| {
        _ = passCols[i];
        const pip = pipCols[i];
        const us = usCols[i];
        const bind = bindCols[i];
        var pass = sg.Pass{};
        pass.action.colors[0].load_action = sg.LoadAction.CLEAR;
        pass.action.colors[0].clear_value = .{ .r = 0, .g = 0, .b = 0, .a = 0 };
        pass.swapchain = sglue.swapchain();
        sg.beginPass(pass);
        sg.applyPipeline(pip.v);
        // for (0..8) |slot| {
        //     const range = us.v[slot];
        //     if (range.size == 0) {
        //         continue;
        //     }
        //     sg.applyUniforms(@intCast(slot), range);
        // }
        sg.applyUniforms(0, sg.asRange(&us.us));
        sg.applyBindings(bind.v);
        sg.draw(bind.base_element, bind.num_elements, bind.num_instances);
        sg.endPass();
        sg.commit();
    }
}

pub fn init_com(world: *ecs.world_t) void {
    ecs.COMPONENT_WITH_NAME(world, GpuPass, GpuPass.name);
    ecs.COMPONENT_WITH_NAME(world, GpuPipeline, GpuPipeline.name);
    ecs.COMPONENT_WITH_NAME(world, GpuUniforms, GpuUniforms.name);
    ecs.COMPONENT_WITH_NAME(world, GpuBinding, GpuBinding.name);
    // const OnOpaque = ecs.new_w_id(world, ecs.Phase);
    // const OnAlpha = ecs.new_w_id(world, ecs.Phase);
    // ecs.add_pair(world, OnOpaque, ecs.DependsOn, ecs.OnUpdate);
    // ecs.add_pair(world, OnAlpha, ecs.DependsOn, OnOpaque);
}
pub fn init_sys(world: *ecs.world_t) void {
    {
        var system_desc = ecs.system_desc_t{};
        system_desc.callback = draw_element;
        system_desc.query.expr =
            \\render.GpuPass,
            \\render.GpuPipeline,
            \\render.GpuUniforms,
            \\render.GpuBinding,
        ;
        _ = ecs.SYSTEM(world, draw_element_name, ecs.OnStore, &system_desc);
    }
}
