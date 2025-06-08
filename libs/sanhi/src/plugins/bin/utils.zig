const sanhi = @import("../../lib.zig");
const ecs = sanhi.ecs;
const sokol = sanhi.sokol;
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const math = sanhi.math;
const std = sanhi.std;
pub fn sokol_target(label: []const u8, width: i32, height: i32, sample_count: i32, num_mipmaps: i32, format: sg.PixelFormat) sg.Image {
    var img_desc: sg.ImageDesc = undefined;
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
            .label = label,
        };
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
            .label = label,
        };
    }
    return sg.makeImage(img_desc);
}

pub fn sokol_target_rgba8(label: []const u8, width: i32, height: i32, sample_count: i32) sg.Image {
    return sokol_target(label, width, height, sample_count, 1, sg.PixelFormat.RGBA8);
}

pub fn sokol_target_rgba16(label: []const u8, width: i32, height: i32, sample_count: i32) sg.Image {
    return sokol_target(label, width, height, sample_count, 1, sg.PixelFormat.RGBA16);
}

pub fn sokol_target_rgba16f(label: []const u8, width: i32, height: i32, sample_count: i32, num_mipmaps: i32) sg.Image {
    return sokol_target(label, width, height, sample_count, num_mipmaps, sg.PixelFormat.RGBA16F);
}

pub fn sokol_target_depth(width: i32, height: i32, sample_count: i32) sg.Image {
    const img_desc = sg.ImageDesc{
        .render_target = true,
        .width = width,
        .height = height,
        .pixel_format = sg.PixelFormat.DEPTH,
        // .min_filter = SG_FILTER_LINEAR,
        // .mag_filter = SG_FILTER_LINEAR,
        .sample_count = sample_count,
        .label = "Depth target",
    };

    return sg.makeImage(img_desc);
}

pub fn white_color() sg.Color {
    return sg.Color{ .r = 1, .g = 1, .b = 1, .a = 1 };
}
