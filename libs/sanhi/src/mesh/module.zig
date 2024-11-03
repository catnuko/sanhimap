const std = @import("std");
const lib = @import("../lib.zig");
const backend = lib.backend;
const zgui = lib.zgui;
const zgpu = lib.zgpu;
const wgpu = lib.wgpu;
const modules = lib.modules;
const math = @import("math");
const Mat4 = math.Mat4x4;
const Vec3 = math.Vec3;
const mesh = @import("./index.zig");
const Mesh = mesh.Mesh;
const Context = mesh.Context;
const Scene = mesh.Scene;
const Camera = mesh.Camera;
const triangle = @import("./Triangle.zig");
const TriangleMesh = triangle.TriangleMesh;
const State = struct {
    depth_texture: zgpu.TextureHandle,
    depth_texture_view: zgpu.TextureViewHandle,
    context: Context,
    scene: Scene,
    camera: Camera,
};
var state: State = undefined;
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
    var context: Context = .{ .gctx = gctx };
    var scene = Scene.new();
    scene.upload(&context);
    const fb_width = gctx.swapchain_descriptor.width;
    const fb_height = gctx.swapchain_descriptor.height;
    var camera = Camera.new(
        math.pi / 3.0,
        @as(f32, @floatFromInt(fb_width)) / @as(f32, @floatFromInt(fb_height)),
        0.01,
        200.0,
    );
    camera.world_matrix = Mat4.lookAt(
        Vec3.new(3.0, 3.0, -3.0),
        Vec3.new(0.0, 0.0, 0.0),
        Vec3.new(0.0, 1.0, 0.0),
    );

    state = State{
        .context = context,
        .depth_texture = depth.texture,
        .depth_texture_view = depth.view,
        .scene = scene,
        .camera = camera,
    };
}
fn on_draw(appBackend: *backend.AppBackend) void {
    const gctx = appBackend.gctx;
    state.context.view = state.camera.world_matrix;
    state.context.projection = state.camera.projection_matrix;
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
            state.context.pass = pass;
            state.context.encoder = encoder;
            state.scene.draw(&state.context);
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
    state.scene.deinit();
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
