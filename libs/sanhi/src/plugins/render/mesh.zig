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
const camera = @import("./camera.zig");
const draw = @import("./draw.zig");
const Transform = @import("./transform.zig").Transform;
const cube_glsl = @import("../../shaders/cube.main.zig");
pub const Material = struct {
    shader_desc: sg.ShaderDesc,
    primitive_type: sg.PrimitiveType = sg.PrimitiveType.TRIANGLE_STRIP,
    pub const name = "render.Material";
};

pub const Geometry = struct {
    positions: std.ArrayList(f32),
    indices: std.ArrayList(u32),
    normals: ?std.ArrayList(f32) = null,
    uvs: ?std.ArrayList(f32) = null,
    pub const name = "render.Geometry";
    pub fn dtor(self: @This()) void {
        self.positions.deinit();
        self.indices.deinit();
        if (self.normals != null) {
            self.normals.?.deinit();
        }
        if (self.uvs != null) {
            self.uvs.?.deinit();
        }
    }
};
pub const AttributeState = struct {
    format: sg.VertexFormat,
    offset: i32 = 0,
    stride: u32 = 0,
};
pub const GeometryBuffer = struct {
    index_count: u32,
    indices: sg.Buffer,
    positions: sg.Buffer,
    positions_attr: AttributeState,
    normals: ?sg.Buffer = null,
    normals_attr: ?AttributeState = null,
    uvs: ?sg.Buffer = null,
    uvs_attr: ?AttributeState = null,
    pub const name = "render.GeometryBuffer";
};
const generate_geometry_buffer_name = "render.generate_geometry_buffer";
fn generate_geometry_buffer(it: *ecs.iter_t) callconv(.C) void {
    const geometryCols = ecs.field(it, Geometry, 0).?;
    for (0..it.count()) |i| {
        const geometry = geometryCols[i];
        const positions_buffer = sg.makeBuffer(.{
            .data = sg.asRange(geometry.positions.items),
            .usage = sg.Usage.IMMUTABLE,
            .type = sg.BufferType.VERTEXBUFFER,
        });
        const indices_buffer = sg.makeBuffer(.{
            .data = sg.asRange(geometry.indices.items),
            .usage = sg.Usage.IMMUTABLE,
            .type = sg.BufferType.INDEXBUFFER,
        });
        var b = GeometryBuffer{
            .positions = positions_buffer,
            .positions_attr = AttributeState{
                .format = sg.VertexFormat.FLOAT3,
            },
            .indices = indices_buffer,
            .index_count = @intCast(geometry.indices.items.len),
        };
        if (geometry.normals) |normals| {
            const normals_buffer = sg.makeBuffer(.{
                .data = sg.asRange(normals.items),
                .usage = sg.Usage.IMMUTABLE,
            });
            b.normals = normals_buffer;
            b.normals_attr = AttributeState{
                .format = sg.VertexFormat.FLOAT3,
            };
        }
        if (geometry.uvs) |uvs| {
            const uvs_buffer = sg.makeBuffer(.{
                .data = sg.asRange(uvs.items),
                .usage = sg.Usage.IMMUTABLE,
            });
            b.uvs = uvs_buffer;
            b.uvs_attr = AttributeState{
                .format = sg.VertexFormat.FLOAT2,
            };
        }
        _ = ecs.set(it.world, it.entities()[i], GeometryBuffer, b);
    }
}
pub const GeometryAttribute = struct {};
const extract_pipline_name = "render.extract_pipline";
fn extract_pipline(it: *ecs.iter_t) callconv(.C) void {
    const c = ecs.get(it.world, ecs.id(camera.Camera), camera.Camera).?;
    const cameraTransform = ecs.get(it.world, ecs.id(camera.Camera), Transform).?;
    const view = math.Mat4f.inverse(&cameraTransform.world);
    const projection = c.projection;
    const viewProjection = projection.multiply(&view);

    const geometryBufferCols = ecs.field(it, GeometryBuffer, 0).?;
    const materialsCols = ecs.field(it, Material, 1).?;
    const transformsCols = ecs.field(it, Transform, 2).?;
    for (0..it.count()) |i| {
        const gb = geometryBufferCols[i];
        const material = materialsCols[i];
        const transform = transformsCols[i];
        const pip = sg.makePipeline(.{
            .shader = sg.makeShader(material.shader_desc),
            .layout = init: {
                var l = sg.VertexLayoutState{};
                l.buffers[0].stride = 12;
                l.attrs[0].format = gb.positions_attr.format;
                l.attrs[0].offset = gb.positions_attr.offset;

                if (gb.normals != null) {
                    l.buffers[1].stride = 12;
                    l.attrs[1].format = gb.normals_attr.?.format;
                    l.attrs[1].offset = gb.normals_attr.?.offset;
                }

                if (gb.uvs != null) {
                    l.buffers[2].stride = 8;
                    l.attrs[2].format = gb.uvs_attr.?.format;
                    l.attrs[2].offset = gb.uvs_attr.?.offset;
                }
                break :init l;
            },
            .index_type = sg.IndexType.UINT32,
            .primitive_type = material.primitive_type,
        });
        var binding = sg.Bindings{};
        binding.vertex_buffers[0] = gb.positions;
        binding.index_buffer = gb.indices;
        if (gb.normals != null) {
            binding.vertex_buffers[1] = gb.normals.?;
        }
        if (gb.uvs != null) {
            binding.vertex_buffers[2] = gb.uvs.?;
        }
        var pass = sg.Pass{};
        pass.action.colors[0].load_action = sg.LoadAction.CLEAR;
        pass.swapchain = sglue.swapchain();

        const mvp = viewProjection.multiply(&transform.world);
        // _ = mvp;
        const mvp2 = math.Mat4f.identity();
        _ = mvp2;
        const us = draw.GpuUniforms{ .us = cube_glsl.VsCommon{ .mvp = mvp } };

        _ = ecs.set(it.world, it.entities()[i], draw.GpuPass, draw.GpuPass{ .v = pass });
        _ = ecs.set(it.world, it.entities()[i], draw.GpuPipeline, draw.GpuPipeline{ .v = pip });
        _ = ecs.set(it.world, it.entities()[i], draw.GpuBinding, draw.GpuBinding{ .v = binding, .num_elements = gb.index_count });
        _ = ecs.set(it.world, it.entities()[i], draw.GpuUniforms, us);
    }
}

pub fn init_com(world: *ecs.world_t) void {
    ecs.COMPONENT_WITH_NAME(world, Material, Material.name);
    ecs.COMPONENT_WITH_NAME(world, Geometry, Geometry.name);
    ecs.COMPONENT_WITH_NAME(world, GeometryBuffer, GeometryBuffer.name);
}
pub fn init_sys(world: *ecs.world_t) void {
    {
        var system_desc = ecs.observer_desc_t{ .callback = generate_geometry_buffer };
        system_desc.query.expr =
            \\render.Geometry,
        ;
        system_desc.events[0] = ecs.OnSet;
        _ = ecs.OBSERVER(world, generate_geometry_buffer_name, &system_desc);
    }
    {
        var system_desc = ecs.system_desc_t{};
        system_desc.callback = extract_pipline;
        system_desc.query.expr =
            \\render.GeometryBuffer,
            \\render.Material,
            \\render.Transform,
            \\!render.GpuPipeline,
        ;
        _ = ecs.SYSTEM(world, extract_pipline_name, ecs.OnUpdate, &system_desc);
    }
}

pub fn erase_list(allocator: std.mem.Allocator, comptime T: type, data: []const T) []u8 {
    const gpu_data = @as([*]const u8, @ptrCast(data.ptr));
    const size = @as(u64, @intCast(data.len)) * @sizeOf(T);
    const buffer_cloned = allocator.alloc(u8, size) catch unreachable;
    @memcpy(buffer_cloned[0..], gpu_data[0..size]);
    return buffer_cloned;
}
