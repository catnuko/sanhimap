const sanhi = @import("../../lib.zig");
const ecs = sanhi.ecs;
const sokol = sanhi.sokol;
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const math = sanhi.math;
const std = sanhi.std;

const com = @import("./com.zig");

const sh = @import("../../shaders/index.zig");
const scene_glsl = sh.scene_glsl;
const RenderState = @import("./RenderState.zig").RenderState;

const utils = @import("./utils.zig");
pub const OffScreenPass = struct {
    pass_action: sg.PassAction,
    pass: sg.Pass,
    pip: sg.Pipeline,
    depth_target: sg.Image,
    color_target: sg.Image,
    int32_t: i32,
};
fn init_scene_pipeline(sample_count: i32) sg.Pipeline {
    var pip = sg.makePipeline(.{
        .shader = sg.makeShader(scene_glsl.sceneShaderDesc(sg.queryBackend())),
        .layout = init: {
            var l = sg.VertexLayoutState{};
            l.attrs[scene_glsl.ATTR_scene_high].format = .FLOAT3;
            l.attrs[scene_glsl.ATTR_scene_low].format = .FLOAT3;
            break :init l;
        },
        .index_type = sg.IndexType.UINT16,
        .cull_mode = sg.CullMode.BACK,
        .sample_count = sample_count,
        .depth = .{ .pixel_format = .DEPTH, .compare = .LESS_EQUAL, .write_enabled = true },
    });
    pip.colors[0].pixel_format = .RGBA16F;
    return pip;
}

pub fn sokol_clear_action(color: sg.Color, clear_color: bool, clear_depth: bool) sg.PassAction {
    var action = sg.PassAction{};
    if (clear_color) {
        action.colors[0].load_action = sg.LoadAction.CLEAR;
        action.colors[0].clear_value = color;
    } else {
        action.colors[0].load_action = sg.LoadAction.DONTCARE;
    }

    if (clear_depth) {
        action.depth.load_action = sg.LoadAction.CLEAR;
        action.depth.clear_value = 1.0;
    } else {
        action.depth.action = sg.LoadAction.DONTCARE;
        action.stencil.action = sg.LoadAction.DONTCARE;
    }

    return action;
}
pub fn init_scene_pass(
    bg_color: sg.Color,
    w: i32,
    h: i32,
    sample_count: i32,
) OffScreenPass {
    var pass = OffScreenPass{};
    pass.pip = init_scene_pass();
    pass.pass_action = sokol_clear_action(bg_color, false, false);
    pass.color_target = utils.sokol_target_rgba16f("Scene color target", w, h, sample_count, 1);
    pass.depth_target = utils.sokol_target_depth(w, h, sample_count);
    return pass;
}

pub fn run_scene_pass(pass: *OffScreenPass, state: *RenderState) !void {
    const us = state.uniforms;
    const cam = state.camera;
    const projection = math.Mat4.perspective(cam.fov, cam.aspect, cam.near, cam.far);
    const cameraMatrix = math.Mat4.lookAt(&cam.position, &cam.lookat, &cam.up);
    const viewMatrix = math.Mat4.inverse(&cameraMatrix);
    const modelView = math.Mat4.multiply(&viewMatrix, &cameraMatrix);
    var modelViewRelativeToEye = modelView.clone();
    modelViewRelativeToEye[12] = 0;
    modelViewRelativeToEye[13] = 0;
    modelViewRelativeToEye[14] = 0;
    const modelViewProjectionRelativeToEye = math.Mat4.multiply(&modelViewRelativeToEye, &projection);
    const us_common_vs = scene_glsl.VsCommon{
        .encodedCameraPositionMCHigh = math.toVec3f(&us.encodedCameraPositionMCHigh),
        .encodedCameraPositionMCLow = math.toVec3f(&us.encodedCameraPositionMCLow),
        .modelViewProjectionRelativeToEye = math.toMat4f(&modelViewProjectionRelativeToEye),
        .projection = math.toMat4f(&projection),
        .modelView = math.toMat4f(&modelView),
        .modelViewRelativeToEye = math.toMat4f(&modelViewRelativeToEye),
    };
    sg.beginPass(pass.pass);
    sg.applyPipeline(pass.pip);
    sg.applyUniforms(scene_glsl.UB_vs_common, sg.asRange(&us_common_vs));
    var it = ecs.query_iter(state.world, state.q_scene);
    while (ecs.query_next(&it)) {
        const geometries = ecs.field(it, com.Query, 0).?;
        for (0..it.count()) |b| {
            const geometry = geometries[b];
            const binding = sg.Bindings{};
            binding.vertex_buffers[scene_glsl.ATTR_scene_high] = geometry.vertices.high;
            binding.vertex_buffers[scene_glsl.ATTR_scene_low] = geometry.vertices.low;
            binding.index_buffer = geometry.indices;
            sg.applyBindings(binding);
            sg.draw(0, geometry.indices.count, 1);
        }
    }
    sg.endPass();
    sg.commit();
}
