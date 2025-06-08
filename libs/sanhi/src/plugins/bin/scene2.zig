const sanhi = @import("../../lib.zig");
const ecs = sanhi.ecs;
const sokol = sanhi.sokol;
const sg = sokol.gfx;
const math = sanhi.math;
const sh = @import("../../shaders/index.zig");
const scene_glsl = sh.scene_glsl;
const sun_glsl = sh.sun_glsl;
const types = @import("./types.zig");
const sokol_offscreen_pass_t = types.sokol_offscreen_pass_t;
const sokol_screen_pass_t = types.sokol_screen_pass_t;
const sokol_render_state_t = types.sokol_render_state_t;
const depth = @import("./depth.zig");
const sokol_init_depth_pass = depth.sokol_init_depth_pass;
const sokol_update_depth_pass = depth.sokol_update_depth_pass;

pub const scene_vs_uniforms_t = struct  {
    mat_v:math.Mat4f,
    mat_vp:math.Mat4f,
    light_mat_vp:math.Mat4f,
    near_:f64,
    far_:f64,
};

pub const scene_fs_uniforms_t = struct  {
    light_ambient: math.Vec3f,
    light_ambient_ground: math.Vec3f,
    light_direction: math.Vec3f,
    light_color: math.Vec3f,
    eye_pos: math.Vec3f,
    light_ambient_ground_falloff:f64 ,
    light_ambient_ground_offset:f64 ,
    light_ambient_ground_intensity:f64 ,
    shadow_map_size:f64 ,
    shadow_far:f64 ,
    light_count:i32,
};

pub const scene_fs_lights_t = struct  {
    light_colors:[SOKOL_MAX_LIGHTS]math.Vec3f ,
    light_positions:[SOKOL_MAX_LIGHTS]math.Vec3f ,
    light_distance:[SOKOL_MAX_LIGHTS]f64 ,
};

pub const scene_fs_sun_atmos_uniforms_t = struct  {
    sun_screen_pos:math.Vec3f ,
    sun_color:math.Vec3f ,
    target_size :math.Vec2f,
    aspect:f64,
    sun_intensity:f64,
};

const POSITION_I =  0;
const NORMAL_I =  1;
const COLOR_I =  2;
const MATERIAL_I =  3;
const TRANSFORM_I =  4;
fn init_scene_pipeline(sample_count:i32) sg_pipeline {
    var pip =  sg.makePipeline(.{
        .shader = sg.makeShader(scene_glsl.sceneFragShaderDesc(sg.queryBackend())),
        .layout = init:{
            var l = sg.VertexLayoutState{};
            l.attrs[scene_glsl.ATTR_scene_frag_v_position].format = .FLOAT3;
            l.attrs[scene_glsl.ATTR_scene_frag_v_normal].format = .FLOAT3;
            l.attrs[scene_glsl.ATTR_scene_frag_i_color].format = .FLOAT3;
            l.attrs[scene_glsl.ATTR_scene_frag_i_material].format = .FLOAT3;
            l.attrs[scene_glsl.ATTR_scene_frag_i_mat_m].format = .FLOAT3;
            break :init l;
        },
        .index_type = sg.IndexType.UINT16,
        .cull_mode = sg.CullMode.BACK,
        .sample_count = sample_count,
        .depth = .{
            .pixel_format = .DEPTH,
            .compare =  .LESS_EQUAL,
            .write_enabled = true,
        },
    });
    pip.colors[0].pixel_format = .RGBA16F;
    return pip;
}

fn init_scene_atmos_sun_pipeline(sample_count:i32) sg_pipeline{
    var pip =  sg.makePipeline(.{
        .shader = sg.makeShader(sun_glsl.sceneFragShaderDesc(sg.queryBackend())),
        .layout = init:{
            var l = sg.VertexLayoutState{};
            l.attrs[sun_glsl.ATTR_sun_v_position].format = .FLOAT3;
            l.attrs[sun_glsl.ATTR_sun_v_uv].format = .FLOAT2;
            break :init l;
        },
        .depth = .{
            .pixel_format = .DEPTH,
            .compare =  .LESS_EQUAL,
            .write_enabled = false,
        },
        .sample_count = sample_count
    });
    return pip;
}
fn update_scene_pass(
    pass:*sokol_offscreen_pass_t,
    w:i32, 
    h:i32,
    sample_count:i32 )void
{
    pass.color_target = sokol_target_rgba16f("Scene color target", w, h, sample_count, 1);
    pass.depth_target = sokol_target_depth(w, h, sample_count);
    // pass.pass = sg_make_pass(.{
    //     .color_attachments[0].image = pass.color_target,
    //     .depth_stencil_attachment.image = pass.depth_target
    // });
}

fn sokol_init_scene_pass(
    background_color:ecs_rgb_t ,
    w:i32, 
    h:i32,
    sample_count:i32,
    depth_pass_out:*sokol_offscreen_pass_t) sokol_offscreen_pass_t
{
    var pass = sokol_offscreen_pass_t{};
    update_scene_pass(&pass, w, h, sample_count);

    *depth_pass_out = sokol_init_depth_pass(w, h, pass.depth_target, sample_count);

    pass.pass_action = sokol_clear_action(background_color, false, false);

    ecs_trace("sokol: initialize scene pipeline");
    pass.pip = init_scene_pipeline(sample_count);
    pass.pip_2 = init_scene_atmos_sun_pipeline(sample_count);
    pass.sample_count = sample_count;

    ecs_trace("sokol: initialized scene pass");
    return pass;
}

pub fn sokol_update_scene_pass(
    pass:*sokol_offscreen_pass_t,
    w:i32,
    h:i32,
    depth_pass:*sokol_offscreen_pass_t)void
{
    ecs_dbg_3("sokol: update scene pass");
    // sg_destroy_pass(pass.pass);
    sg.destroyImage(pass.color_target);
    sg.destroyImage(pass.depth_target);

    update_scene_pass(pass, w, h, pass.sample_count);
    sokol_update_depth_pass(depth_pass, w, h, 
        pass.depth_target, pass.sample_count);
}

fn scene_draw_atmos(
    state:*sokol_render_state_t)void
{
    var binding = sg.Bindings{};
    binding.vertex_buffers[0] = state.resources.quad;
    binding.images[0] = state.atmos;
    sg.applyBindings(binding);
    sg.draw(0, 6, 1);
}

fn scene_draw_instances(
    geometry:*SokolGeometry,
    buffers:*sokol_geometry_buffers_t,
    shadow_map:sg.Image )void
{
    if (!buffers.instance_count) {
        return;
    }
    var binding = sg.Bindings{};
    binding.vertex_buffers[POSITION_I] = geometry.vertices;
    binding.vertex_buffers[NORMAL_I] = geometry.vertices;
    binding.vertex_buffers[COLOR_I] = geometry.vertices;
    binding.vertex_buffers[MATERIAL_I] = geometry.vertices;
    binding.vertex_buffers[TRANSFORM_I] = geometry.vertices;
    binding.index_buffer = geometry.indices;
    binding.images[0] = shadow_map;
    sg.applyBindings(binding);
    sg.draw(0, geometry.index_count, buffers.instance_count);
}

pub fn sokol_run_scene_pass(
    pass:*sokol_offscreen_pass_t,
    state:*sokol_render_state_t)void
{
    var vs_u = scene_vs_uniforms_t{};
    // vs_u.mat_v  = state.uniforms.mat_v;
    glm_mat4_copy(state.uniforms.mat_v, vs_u.mat_v);
    glm_mat4_copy(state.uniforms.mat_vp, vs_u.mat_vp);
    glm_mat4_copy(state.uniforms.light_mat_vp, vs_u.light_mat_vp);
    vs_u.near_ = state.uniforms.near_;
    vs_u.far_ = state.uniforms.far_;

    scene_fs_uniforms_t fs_u;
    glm_vec3_copy(state.uniforms.light_ambient, fs_u.light_ambient);
    glm_vec3_copy(state.uniforms.light_ambient_ground, fs_u.light_ambient_ground);
    fs_u.light_ambient_ground_falloff = state.uniforms.light_ambient_ground_falloff;
    fs_u.light_ambient_ground_offset = state.uniforms.light_ambient_ground_offset;
    fs_u.light_ambient_ground_intensity = state.uniforms.light_ambient_ground_intensity;

    glm_vec3_copy(state.uniforms.sun_direction, fs_u.light_direction);
    glm_vec3_copy(state.uniforms.sun_color, fs_u.light_color);
    glm_vec3_scale(fs_u.light_color, state.uniforms.sun_intensity, fs_u.light_color);
    glm_vec3_copy(state.uniforms.eye_pos, fs_u.eye_pos);
    fs_u.shadow_map_size = state.uniforms.shadow_map_size;
    fs_u.shadow_far = state.uniforms.shadow_far;
    fs_u.eye_pos[0] *= -1;

    scene_fs_sun_atmos_uniforms_t fs_sun_atmos_u;
    glm_vec3_copy(state.uniforms.sun_screen_pos, fs_sun_atmos_u.sun_screen_pos);
    glm_vec3_copy(state.uniforms.sun_color, fs_sun_atmos_u.sun_color);
    fs_sun_atmos_u.target_size[0] = state.width;
    fs_sun_atmos_u.target_size[1] = state.height;
    fs_sun_atmos_u.aspect = state.uniforms.aspect;
    fs_sun_atmos_u.sun_intensity = 1.0 + state.uniforms.sun_intensity * 6;

    scene_fs_lights_t lights_u;
    sokol_light_t *lights = ecs_vec_first(&state.lights);
    for (int i = 0; i < ecs_vec_count(&state.lights); i ++) {
        glm_vec3_copy(lights[i].color, lights_u.light_colors[i]);
        glm_vec3_copy(lights[i].position, lights_u.light_positions[i]);
        lights_u.light_distance[i] = lights[i].distance;
    }
    fs_u.light_count = ecs_vec_count(&state.lights);

    // Render to offscreen texture so screen-space effects can be applied
    sg.beginPass(pass.pass, &pass.pass_action);

    // Step 1: render atmosphere background
    sg.applyPipeline(pass.pip_2);
    sg.applyUniforms(0, &(sg_range){&fs_sun_atmos_u, sizeof(scene_fs_sun_atmos_uniforms_t)});
    scene_draw_atmos(state);

    // Step 2: render scene
    sg.applyPipeline(pass.pip);
    sg.applyUniforms(4, &(sg_range){&vs_u, sizeof(scene_vs_uniforms_t)});
    sg.applyUniforms(0, &(sg_range){&fs_u, sizeof(scene_fs_uniforms_t)});
    sg.applyUniforms(1, &(sg_range){&lights_u, sizeof(scene_fs_lights_t)});

    // Loop geometry, render scene
    ecs_iter_t qit = ecs_query_iter(state.world, state.q_scene);
    while (ecs_query_next(&qit)) {
        SokolGeometry *geometry = ecs_field(&qit, SokolGeometry, 0);

        int b;
        for (b = 0; b < qit.count; b ++) {
            scene_draw_instances(&geometry[b], &geometry[b].solid, state.shadow_map);
            scene_draw_instances(&geometry[b], &geometry[b].emissive, state.shadow_map);
        }
    }
    sg.endPass();
}