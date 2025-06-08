const sanhi = @import("../../lib.zig");
const ecs = sanhi.ecs;
const sokol = sanhi.sokol;
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const math = sanhi.math;
const com = @import("./com.zig");
const constant = @import("./constant.zig");
const types = @import("./types.zig");
const sokol_offscreen_pass_t = types.sokol_offscreen_pass_t;
const sokol_screen_pass_t = types.sokol_screen_pass_t;
const sokol_resources_t = types.sokol_resources_t;

fn compute_flat_normals(
    vertices:[]math.Vec3f,
    indices:[]u16,
    count:i32,
    normals_count:[]math.Vec3f,
    )void
{
    var v:i32= 0;
    while(v<count):(v+=3){
        
        vec3 vec1, vec2, normal;
        glm_vec3_sub(vertices[indices[v + 0]], vertices[indices[v + 1]], vec1);
        glm_vec3_sub(vertices[indices[v + 0]], vertices[indices[v + 2]], vec2);
        glm_vec3_crossn(vec2, vec1, normal);

        if (fabs(normal[0]) < GLM_FLT_EPSILON) {
            normal[0] = 0;
        }
        if (fabs(normal[1]) < GLM_FLT_EPSILON) {
            normal[1] = 0;
        }
        if (fabs(normal[2]) < GLM_FLT_EPSILON) {
            normal[2] = 0;
        }

        glm_vec3_copy(normal, normals_out[indices[v + 0]]);
        glm_vec3_copy(normal, normals_out[indices[v + 1]]);
        glm_vec3_copy(normal, normals_out[indices[v + 2]]);
    }
}

pub fn sokol_target(
    label:[]const u8
    width:i32, 
    height:i32,
    sample_count:i32,
    num_mipmaps:i32,
    format:sg_pixel_format)sg.Image
{
    var img_desc:sg.ImageDesc = undefined;
    sg.Filter.NEAREST
    if (num_mipmaps > 1) {
        img_desc = sg.ImageDesc{
            .render_target = true,
            .width = width,
            .height = height,
            .wrap_u = sg.Wrap.CLAMP_TO_EDGE,
            .wrap_v = sg.Wrap.CLAMP_TO_EDGE,
            .pixel_format = format,
            // .min_filter = SG_FILTER_LINEAR_MIPMAP_LINEAR,
            // .mag_filter = SG_FILTER_LINEAR,
            .sample_count = sample_count,
            .num_mipmaps = num_mipmaps,
            .label = label
        }
    } else {
        img_desc = sg.ImageDesc{
            .render_target = true,
            .width = width,
            .height = height,
            .wrap_u = sg.Wrap.CLAMP_TO_EDGE,
            .wrap_v = sg.Wrap.CLAMP_TO_EDGE,
            .pixel_format = format,
            // .min_filter = SG_FILTER_LINEAR,
            // .mag_filter = SG_FILTER_LINEAR,
            .sample_count = sample_count,
            .num_mipmaps = num_mipmaps,
            .label = label
        };
    }
    return sg.makeImage(img_desc);
}

pub fn sokol_target_rgba8(
    label:[]const u8,
    width:i32, 
    height:i32,
    sample_count:i32)sg.Image
{
    return sokol_target(label, width, height, sample_count, 1, SG_PIXELFORMAT_RGBA8);
}

pub fn sokol_target_rgba16(
    label:[]const u8,
    width:i32, 
    height:i32,
    sample_count:i32)sg.Image
{
    return sokol_target(label, width, height, sample_count, 1, SG_PIXELFORMAT_RGBA16);
}

pub fn sokol_target_rgba16f(
    label:[]const u8,
    width:i32, 
    height:i32,
    sample_count:i32,
    num_mipmaps:i32) sg.Image
{
    return sokol_target(label, width, height, sample_count, num_mipmaps, SG_PIXELFORMAT_RGBA16F);
}

pub fn sokol_target_depth(
    width:i32, 
    height:i32,
    sample_count:i32) sg.Image
{
    const img_desc = sg.ImageDesc{
        .render_target = true,
        .width = width,
        .height = height,
        .pixel_format = SG_PIXELFORMAT_DEPTH,
        // .min_filter = SG_FILTER_LINEAR,
        // .mag_filter = SG_FILTER_LINEAR,
        .sample_count = sample_count,
        .label = "Depth target"
    };

    return sg.makeImage(img_desc);
}

pub fn sokol_buffer_quad() sg.Buffer {
    return sg.makeBuffer(.{
        .data = sg.asRange(&constant.quad_vertices_uvs),
        .usage = sg.Usage.IMMUTABLE,
    });
}
pub fn sokol_buffer_box() sg.Buffer {
    return sg.makeBuffer(.{
        .data = sg.asRange(&constant.box_vertices),
        .usage = sg.Usage.IMMUTABLE,
    });
}

pub fn sokol_buffer_box_indices() sg.Buffer {
    return sg.makeBuffer(.{
        .data = sg.asRange(&constant.box_indices),
        .usage = sg.Usage.IMMUTABLE,
        .type = sg.BufferType.INDEXBUFFER,
    });
}

pub fn sokol_box_index_count() i32 {
    return 32;
}


pub fn sokol_buffer_box_normals()sg.Buffer
{
    var normals:[24]vec3 = undefined;
    compute_flat_normals(
        box_vertices, box_indices, sokol_box_index_count(), normals);

    return sg.makeBuffer(.{
        .data = sg.asRange(&normals),
        .usage = sg.Usage.IMMUTABLE
    });
}

pub fn sokol_buffer_rectangle()sg.Buffer
{
    return sg.makeBuffer(.{
        .data = sg.asRange(&constant.rectangle_vertices),
        .usage = sg.Usage.IMMUTABLE
    });
}

pub fn sokol_buffer_rectangle_indices()sg.Buffer
{
    return sg.makeBuffer(.{
        .data = sg.asRange(&constant.rectangle_indices),
        .type = sg.BufferType.INDEXBUFFER,
        .usage = sg.Usage.IMMUTABLE
    });
}

pub fn sokol_rectangle_index_count()i32
{
    return 6;
}

pub fn sokol_buffer_rectangle_normals()sg.Buffer
{
    var normals = [4]math.Vec3f;
    compute_flat_normals(rectangle_vertices, 
        rectangle_indices, sokol_rectangle_index_count(), normals);

    return sg.makeBuffer(.{
        .data = { normals, sizeof(normals) },
        .usage = sg.Usage.IMMUTABLE
    });
}
pub fn sokol_clear_action(
    color:sg.Color,
    clear_color:bool ,
    clear_depth:bool )sg.PassAction
{   
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

const char* sokol_vs_passthrough(void)
{
    return  SOKOL_SHADER_HEADER
            "layout(location=0) in vec4 v_position;\n"
            "layout(location=1) in vec2 v_uv;\n"
            "out vec2 uv;\n"
            "void main() {\n"
            "  gl_Position = v_position;\n"
            "  uv = v_uv;\n"
            "}\n";
}

pub fn sokol_noise_texture(
    width:i32, 
    height:i32)sg.Image
{
    var data = alloc.malloc(u32,width*height);
    defer alloc.free(data);
    for (int32_t x = 0; x < width; x ++) {
        for (int32_t y = 0; y < height; y ++) {
            data[x + y * x] = rand();
        }
    }
    var desc = sg.ImageDesc{
        .width = width,
        .height = height,
        .wrap_u = sg.Wrap.REPEAT,
        .wrap_v = sg.Wrap.REPEAT,
        .pixel_format = sg.PixelFormat.R8,
        .label = "Noise texture",
    };
    desc.data.subimage[0][0] = sg.asRange(data);
    const img = sg.makeImage(desc);
    return img;
}

pub fn sokol_init_resources()sokol_resources_t{
        return sokol_resources_t{
            .quad = sokol_buffer_quad(),
            .rect = sokol_buffer_rectangle(),
            .rect_indices = sokol_buffer_rectangle_indices(),
            .rect_normals = sokol_buffer_rectangle_normals(),
            .box = sokol_buffer_box(),
            .box_indices = sokol_buffer_box_indices(),
            .box_normals = sokol_buffer_box_normals(),
            .noise_texture = sg.makeImage(.{
                .type = sg.ImageType.CUBE,
                .width = 256,
                .height = 256,
                .pixel_format = sg.PixelFormat.RGBA8,
                .usage = sg.Usage.DYNAMIC,
                .label = "sokol.noise_texture",
            }),
            .bg_texture = sg.makeImage(.{
                .type = sg.ImageType.CUBE,
                .width = 2,
                .height = 2,
                .pixel_format = sg.PixelFormat.RGBA8,
                .usage = sg.Usage.DYNAMIC,
                .label = "sokol.bg_texture",
            })
    }
}
pub fn  sokol_bg_texture(ecs_rgb_t color, width:i32, height:i32)sg.Image
{
    uint32_t *data = ecs_os_malloc_n(uint32_t, width * height);

    for (int32_t x = 0; x < width; x ++) {
        for (int32_t y = 0; y < height; y ++) {
            uint32_t c = (uint32_t)(color.r * 256);
            c += (uint32_t)(color.g * 256) << 8;
            c += (uint32_t)(color.b * 256) << 16;
            c += 255u << 24;

            data[x + y * width] = c;
        }
    }

    sg_image img = sg_make_image(&(sg_image_desc){
        .width = width,
        .height = height,
        .wrap_u = sg.Wrap.CLAMP_TO_EDGE,
        .wrap_v = sg.Wrap.CLAMP_TO_EDGE,
        .pixel_format = SG_PIXELFORMAT_RGBA8,
        .label = "Background texture",
        .data.subimage[0][0] = {
            .ptr = data,
            .size = width * height * 4
        }
    });

    return img;
}