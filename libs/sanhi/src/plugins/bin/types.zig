const sanhi = @import("../../lib.zig");
const ecs = sanhi.ecs;
const sokol = sanhi.sokol;
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const math = sanhi.math;
pub const sokol_offscreen_pass_t = struct {
    pass_action: sg.PassAction,
    pass: sg.Pass,
    pip: sg.Pipeline,
    pip_2: sg.Pipeline,
    depth_target: sg.Image,
    color_target: sg.Image,
    int32_t: i32,
};
pub const sokol_screen_pass_t = struct {
    pass_action: sg.PassAction,
    pip: sg.Pipeline,
};

pub const sokol_resources_t = struct {
    quad: sg.Buffer,
    rect: sg.Buffer,
    rect_indices: sg.Buffer,
    rect_normals: sg.Buffer,
    box: sg.Buffer,
    box_indices: sg.Buffer,
    box_normals: sg.Buffer,
    noise_texture: sg.Image,
    bg_texture: sg.Image,
};

pub const sokol_global_uniforms_t = struct {
    mat_v: math.Mat4f,
    mat_p: math.Mat4f,
    mat_vp: math.Mat4f,
    inv_mat_p: math.Mat4f,
    inv_mat_v: math.Mat4f,

    light_mat_v: math.Mat4f,
    light_mat_vp: math.Mat4f,

    light_ambient: math.Vec3f,

    light_ambient_ground: math.Vec4f,
    light_ambient_ground_falloff: f32,
    light_ambient_ground_offset: f32,
    light_ambient_ground_intensity: f32,

    sun_direction: math.Vec3f,
    sun_color: math.Vec3f,
    sun_screen_pos: math.Vec3f,
    sun_intensity: f32,

    eye_pos: math.Vec3f,
    eye_up: math.Vec3f,
    eye_lookat: math.Vec3f,
    eye_dir: math.Vec3f,
    eye_horizon: math.Vec3f,

    t: f32,
    dt: f32,
    aspect: f32,
    near_: f32,
    far_: f32,
    fov: f32,
    shadow_near: f32,
    shadow_far: f32,
    ortho: bool,
    shadow_map_size: f32,
};

pub const sokol_light_t = struct {
    color: math.Vec3f,
    position: math.Vec3f,
    distance: f32,
};

// Data that is collected once per frame and that is shared between passes
pub const sokol_render_state_t = struct {
    world: *ecs_world_t,
    q_scene: *ecs_query_t,
    light: *EcsDirectionalLight,
    camera: *EcsCamera,
    atmosphere: *EcsAtmosphere,
    ambient_light: ecs_rgb_t,
    ambient_light_ground: ecs_rgb_t,
    ambient_light_ground_falloff: float,
    ambient_light_ground_offset: float,
    ambient_light_ground_intensity: float,
    width: int32_t,
    height: int32_t,

    resources: sokol_resources_t,
    uniforms: sokol_global_uniforms_t,
    atmos: sg_image,
    shadow_map: sg_image,

    lights: ecs_vec_t,
};
