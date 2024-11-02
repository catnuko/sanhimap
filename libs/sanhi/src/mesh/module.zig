const std = @import("std");
const lib = @import("../lib.zig");
const backend = lib.backend;
const zgui = lib.zgui;
const zgpu = lib.zgpu;
const wgpu = lib.wgpu;
const modules = lib.modules;
// const math = lib.math;
const math = @import("math");
const Mat4 = math.Mat4x4;
const Vec3 = math.Vec3;
const mesh = @import("./mesh.zig");
const triangle = @import("./Triangle.zig");
const TriangleMesh = triangle.TriangleMesh;

const wgsl_vs =
    \\  @group(0) @binding(0) var<uniform> object_to_clip: mat4x4<f32>;
    \\  struct VertexOut {
    \\      @builtin(position) position_clip: vec4<f32>,
    \\      @location(0) color: vec4<f32>,
    \\  }
    \\  @vertex fn main(
    \\      @location(0) position: vec3<f32>,
    \\      @location(1) color: vec4<f32>,
    \\  ) -> VertexOut {
    \\      var output: VertexOut;
    \\      output.position_clip = object_to_clip * vec4(position, 1.0);
    \\      output.color = color;
    \\      return output;
    \\  }
;
const wgsl_fs =
    \\  @fragment fn main(
    \\      @location(0) color: vec4<f32>,
    \\  ) -> @location(0) vec4<f32> {
    \\      return color;
    \\  }
    // zig fmt: on
;

pub fn State(comptime Mesh: type) type {
    return struct {
        gctx: *zgpu.GraphicsContext,
        mesh: Mesh,
        depth_texture: zgpu.TextureHandle,
        depth_texture_view: zgpu.TextureViewHandle,
    };
}
var state: State(TriangleMesh) = undefined;
const Vertex = struct {
    position: [3]f32,
    color: [3]f32,
};
var vs_module: zgpu.wgpu.ShaderModule = undefined;
var fs_module: zgpu.wgpu.ShaderModule = undefined;
pub fn to_list(comptime T: type, constList: anytype) std.ArrayList(T) {
    const allocator = lib.mem.getAllocator(); // 使用合适的内存分配器
    var list = std.ArrayList(T).initCapacity(allocator, constList.len) catch unreachable;
    for (0..constList.len) |i| {
        list.appendAssumeCapacity(constList[i]);
    }
    return list;
}
fn on_init(appBackend: *backend.AppBackend) !void {
    const gctx = appBackend.gctx;
    const depth = createDepthTexture(gctx);
    var triangle_mesh = triangle.initTriangleMesh();
    triangle_mesh.upload(gctx);
    state = State(TriangleMesh){
        .gctx = gctx,
        .mesh = triangle_mesh,
        .depth_texture = depth.texture,
        .depth_texture_view = depth.view,
    };
}
fn on_draw(appBackend: *backend.AppBackend) void {
    const gctx = appBackend.gctx;

    zgui.backend.newFrame(
        gctx.swapchain_descriptor.width,
        gctx.swapchain_descriptor.height,
    );
    zgui.showDemoWindow(null);

    const back_buffer_view = gctx.swapchain.getCurrentTextureView();
    defer back_buffer_view.release();

    const commands = commands: {
        const encoder = gctx.device.createCommandEncoder(null);
        defer encoder.release();

        pass: {
            const depth_view = gctx.lookupResource(state.depth_texture_view) orelse break :pass;

            const color_attachments = [_]wgpu.RenderPassColorAttachment{.{
                .view = back_buffer_view,
                .load_op = .clear,
                .store_op = .store,
            }};
            const depth_attachment = wgpu.RenderPassDepthStencilAttachment{
                .view = depth_view,
                .depth_load_op = .clear,
                .depth_store_op = .store,
                .depth_clear_value = 1.0,
            };
            const render_pass_info = wgpu.RenderPassDescriptor{
                .color_attachment_count = color_attachments.len,
                .color_attachments = &color_attachments,
                .depth_stencil_attachment = &depth_attachment,
            };
            const pass = encoder.beginRenderPass(render_pass_info);
            defer {
                pass.end();
                pass.release();
            }

            state.mesh.draw(gctx, pass) orelse unreachable;
        }
        {
            const color_attachments = [_]wgpu.RenderPassColorAttachment{.{
                .view = back_buffer_view,
                .load_op = .load,
                .store_op = .store,
            }};
            const render_pass_info = wgpu.RenderPassDescriptor{
                .color_attachment_count = color_attachments.len,
                .color_attachments = &color_attachments,
            };
            const pass = encoder.beginRenderPass(render_pass_info);
            defer {
                pass.end();
                pass.release();
            }

            zgui.backend.draw(pass);
        }

        break :commands encoder.finish(null);
    };
    defer commands.release();

    gctx.submit(&.{commands});

    if (gctx.present() == .swap_chain_resized) {
        // Release old depth texture.
        gctx.releaseResource(state.depth_texture_view);
        gctx.destroyResource(state.depth_texture);

        // Create a new depth texture to match the new window size.
        const depth = createDepthTexture(gctx);
        state.depth_texture = depth.texture;
        state.depth_texture_view = depth.view;
    }
}
fn on_deinit() !void {
    state.mesh.deinit();
}

pub fn module() modules.Module {
    const meshes = modules.Module{
        .name = "meshes",
        .draw_fn = on_draw,
        .init_fn = on_init,
        .cleanup_fn = on_deinit,
    };
    return meshes;
}

fn createDepthTexture(gctx: *zgpu.GraphicsContext) struct {
    texture: zgpu.TextureHandle,
    view: zgpu.TextureViewHandle,
} {
    const texture = gctx.createTexture(.{
        .usage = .{ .render_attachment = true },
        .dimension = .tdim_2d,
        .size = .{
            .width = gctx.swapchain_descriptor.width,
            .height = gctx.swapchain_descriptor.height,
            .depth_or_array_layers = 1,
        },
        .format = .depth32_float,
        .mip_level_count = 1,
        .sample_count = 1,
    });
    const view = gctx.createTextureView(texture, .{});
    return .{ .texture = texture, .view = view };
}

fn mat4ToGpuMat4(mat4: *const Mat4) [16]f32 {
    const v = mat4.toArray();
    var res: [16]f32 = [1]f32{0} ** 16;
    for (v, 0..) |vv, i| {
        res[i] = @floatCast(@round(vv));
    }
    return res;
}
