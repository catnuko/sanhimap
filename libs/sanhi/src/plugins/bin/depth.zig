const sanhi = @import("../../lib.zig");
const ecs = sanhi.ecs;
const sokol = sanhi.sokol;
const sg = sokol.gfx;
const math = sanhi.math;
const sh = @import("../../shaders/index.zig");
const depth_glsl = sh.depth_glsl;
const types = @import("./types.zig");
const sokol_offscreen_pass_t = types.sokol_offscreen_pass_t;
const sokol_screen_pass_t = types.sokol_screen_pass_t;

pub const depth_vs_uniforms_t = struct  {
    mat_vp:math.Mat4f,
};

pub const depth_fs_uniforms_t = struct  {
    eye_pos:math.Vec3f,
    near_:f32,
    far_:f32,
    depth_c:f32,
    inv_log_far:f32,
};

fn init_depth_pipeline(sample_count:i32) sg_pipeline {
    return sg_make_pipeline(&(sg_pipeline_desc){
        .shader = sg.makeShader(depth_glsl.sceneFragShaderDesc(sg.queryBackend())),
        .index_type = sg.IndexType.UINT16,
        .layout = init:{
            var l = sg.VertexLayoutState{};
            l.buffers[0].stride = 64;
            l.buffers[0].step_func = sg.VertexStep.PER_INSTANCE,
            l.attrs[depth_glsl.ATTR_sun_v_position].format = .FLOAT3;
            l.attrs[depth_glsl.ATTR_sun_i_mat_m].format = .FLOAT3;
            break :init l;
        },
          .depth = .{
            .pixel_format = .DEPTH,
            .compare =  .LESS_EQUAL,
            .write_enabled = true,
        },
        .cull_mode = sg.CullMode.BACK,
        .sample_count = sample_count,
    });
}

pub fn sokol_init_depth_pass(
    w:i32, 
    h:i32,
    depth_target:sg.Image,
    sample_count:i32) void
{
    ecs_trace("sokol: initialize depth pass");

    const color_target = sokol_target_rgba8("Depth color target", w, h, sample_count);
    const background_color = .{1, 1, 1};

    sokol_offscreen_pass_t result = {
        .pass_action = sokol_clear_action(background_color, true, true),
        .pass = sg_make_pass(&(sg_pass_desc){
            .color_attachments[0].image = color_target,
            .depth_stencil_attachment.image = depth_target
        }),
        .pip = init_depth_pipeline(sample_count),
        .color_target = color_target,
        .depth_target = depth_target
    };

    ecs_trace("sokol: depth initialized");
    return result;
}

pub fn sokol_update_depth_pass(
    pass:*sokol_offscreen_pass_t,
    w:i32,
    h:i32,
    depth_target:sg.Image,
    sample_count:i32)void
{
    sg_destroy_image(pass->color_target);
    sg_destroy_pass(pass->pass);

    pass->color_target = sokol_target_rgba8(
        "Depth color target", w, h, sample_count);

    pass->pass = sg_make_pass(&(sg_pass_desc){
        .color_attachments[0].image = pass->color_target,
        .depth_stencil_attachment.image = depth_target
    });
}

fn depth_draw_instances(
    geometry:*SokolGeometry,
    buffers:*sokol_geometry_buffers_t)void
{
    if (!buffers->instance_count) {
        return;
    }

    sg_bindings bind = {
        .vertex_buffers = {
            [0] = geometry->vertices,
            [1] = buffers->transforms
        },
        .index_buffer = geometry->indices
    };

    sg_apply_bindings(&bind);
    sg_draw(0, geometry->index_count, buffers->instance_count);
}

void sokol_run_depth_pass(
    pass:*sokol_offscreen_pass_t,
    sokol_render_state_t *state)
{
    depth_vs_uniforms_t vs_u;
    glm_mat4_copy(state->uniforms.mat_vp, vs_u.mat_vp);
    
    depth_fs_uniforms_t fs_u;
    glm_vec3_copy(state->uniforms.eye_pos, fs_u.eye_pos);
    fs_u.near_ = state->uniforms.near_;
    fs_u.far_ = state->uniforms.far_;
    fs_u.depth_c = SOKOL_DEPTH_C;
    fs_u.inv_log_far = 1.0 / log(SOKOL_DEPTH_C * fs_u.far_ + 1.0);

    /* Render to offscreen texture so screen-space effects can be applied */
    sg_begin_pass(pass->pass, &pass->pass_action);
    sg_apply_pipeline(pass->pip);

    sg_apply_uniforms(SG_SHADERSTAGE_VS, 0, &(sg_range){&vs_u, sizeof(depth_vs_uniforms_t)});
    sg_apply_uniforms(SG_SHADERSTAGE_FS, 0, &(sg_range){&fs_u, sizeof(depth_fs_uniforms_t)});

    /* Loop geometry, render scene */
    ecs_iter_t qit = ecs_query_iter(state->world, state->q_scene);
    while (ecs_query_next(&qit)) {
        SokolGeometry *geometry = ecs_field(&qit, SokolGeometry, 0);

        int b;
        for (b = 0; b < qit.count; b ++) {
            depth_draw_instances(&geometry[b], &geometry[b].solid);
            depth_draw_instances(&geometry[b], &geometry[b].emissive);
        }
    }

    sg_end_pass();
}