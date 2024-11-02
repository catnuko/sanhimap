const lib = @import("../lib.zig");
const wgpu = lib.wgpu;
const zgpu = lib.zgpu;
const math = @import("math");
const Mat4 = math.Mat4x4;
const Vec3 = math.Vec3;
const Quat = math.Quat;
const geom = @import("./geometry.zig");
const mate = @import("./material.zig");
const Geometry = geom.Geometry;
const Material = mate.Material;

pub const Object3D = struct {
    matrix: Mat4 = Mat4.identity(),
    matrixWorld: Mat4 = Mat4.identity(),
    parent: ?*Object3D = null,
    children: lib.ArrayList(*Object3D),
    const Self = @This();
    pub fn new() Self {
        return .{ .children = lib.ArrayList(*Object3D).init(lib.mem.getAllocator()) };
    }
    pub fn deinit(self: *Self) void {
        self.removeAll();
        self.children.deinit();
    }
    pub fn updateMatrixWorld(self: *Self) void {
        if (self.parent) |parent| {
            self.matrixWorld = parent.matrixWorld.mul(self.matrix);
        } else {
            self.matrixWorld = self.matrix.clone();
        }
        for (self.children.items) |children| {
            children.updateMatrixWorld();
        }
    }
    pub fn add(self: *Self, obj: *Object3D) void {
        if (self == obj) {
            @compileError("obj can't be added as a child of itself.");
        }
        obj.removeFromParent();
        obj.parent = self;
        self.children.append(obj);
    }
    pub fn remove(self: *Self, obj: *Object3D) void {
        var targetIndex: usize = -1;
        for (self.children.items, 0..) |children, i| {
            if (children == obj) {
                targetIndex = i;
                break;
            }
        }
        if (targetIndex != -1) {
            const children = self.children.swapRemove(targetIndex);
            children.parent = null;
        }
    }
    pub fn removeFromParent(self: *Self) void {
        if (self.parent) |parent| {
            parent.remove(self);
        }
    }
    pub fn removeAll(self: *Self) void {
        for (self.children.items) |children| {
            children.parent = null;
        }
        self.children.clearAndFree();
    }
};
pub fn Mesh(comptime Vertex: type, comptime Uniforms: type) type {
    return struct {
        const State = struct {
            pipeline: zgpu.RenderPipelineHandle,
            bindGroup: zgpu.BindGroupHandle,
        };
        const Self = @This();
        pub const MeshGeometry = Geometry(Vertex);
        pub const MeshMaterial = Material(Uniforms);
        geometry: MeshGeometry,
        material: MeshMaterial,
        state: State = undefined,
        object3D: Object3D,
        pub fn new(geometry: MeshGeometry, material: MeshMaterial) Self {
            return .{
                .geometry = geometry,
                .material = material,
                .object3D = Object3D.new(),
            };
        }
        pub inline fn add(self: *Self, obj: *Object3D) void {
            self.object3D.add(obj);
        }
        pub inline fn remove(self: *Self, obj: *Object3D) void {
            self.object3D.remove(obj);
        }
        pub inline fn removeFromParent(self: *Self) void {
            self.object3D.removeFromParent();
        }
        pub inline fn removeAll(self: *Self) void {
            self.object3D.removeAll();
        }
        pub inline fn updateMatrixWorld(self: *Self) void {
            self.object3D.updateMatrixWorld();
        }
        pub fn deinit(self: *Self) void {
            self.geometry.deinit();
            self.material.deinit();
            self.object3D.deinit();
        }
        pub fn upload(self: *Self, gctx: *zgpu.GraphicsContext) void {
            self.material.upload(gctx);
            self.geometry.upload(gctx);
            self.createRenderPipeline(gctx);
        }
        fn createRenderPipeline(self: *Self, gctx: *zgpu.GraphicsContext) void {
            //create pipeline layout
            const bind_group_layout = gctx.createBindGroupLayout(&.{
                zgpu.bufferEntry(0, .{ .vertex = true }, .uniform, true, 0),
            });
            defer gctx.releaseResource(bind_group_layout);

            const pipeline_layout = gctx.createPipelineLayout(&.{bind_group_layout});
            defer gctx.releaseResource(pipeline_layout);

            const vertebuf = self.geometry.vertexBufferLayout();
            const vertextBufferLayout = [_]wgpu.VertexBufferLayout{vertebuf};
            const color_targets = [_]wgpu.ColorTargetState{.{
                .format = zgpu.GraphicsContext.swapchain_format,
            }};
            const desc = wgpu.RenderPipelineDescriptor{
                .vertex = wgpu.VertexState{
                    .module = self.material.vs_module,
                    .entry_point = "vsMain",
                    .buffer_count = vertextBufferLayout.len,
                    .buffers = &vertextBufferLayout,
                },
                .primitive = wgpu.PrimitiveState{
                    .front_face = .ccw,
                    .cull_mode = .none,
                    .topology = self.geometry.primitiveTopology,
                },
                .depth_stencil = &wgpu.DepthStencilState{
                    .format = .depth32_float,
                    .depth_write_enabled = true,
                    .depth_compare = .less,
                },
                .fragment = &wgpu.FragmentState{
                    .module = self.material.fs_module,
                    .entry_point = "fsMain",
                    .target_count = color_targets.len,
                    .targets = &color_targets,
                },
            };
            //create pipeline
            const pipeline = gctx.createRenderPipeline(pipeline_layout, desc);

            const bind_group = gctx.createBindGroup(bind_group_layout, &.{
                .{ .binding = 0, .buffer_handle = gctx.uniforms.buffer, .offset = 0, .size = self.material.uniforms.getSize() },
            });
            self.state = .{ .bindGroup = bind_group, .pipeline = pipeline };
        }
        pub fn draw(self: *Self, gctx: *zgpu.GraphicsContext, pass: wgpu.RenderPassEncoder) ?void {
            const vb_info = gctx.lookupResourceInfo(self.geometry.vertex_buffer).?;
            const ib_info = gctx.lookupResourceInfo(self.geometry.index_buffer).?;
            const uniform_bg = gctx.lookupResource(self.state.bindGroup).?;
            const pipeline = gctx.lookupResource(self.state.pipeline).?;
            pass.setVertexBuffer(0, vb_info.gpuobj.?, 0, vb_info.size);
            pass.setIndexBuffer(ib_info.gpuobj.?, .uint32, 0, ib_info.size);
            pass.setPipeline(pipeline);
            {
                self.material.uniforms.update(gctx);
                const mem = gctx.uniformsAllocate(Uniforms, 1);
                mem.slice[0] = self.material.uniforms;
                pass.setBindGroup(0, uniform_bg, &.{mem.offset});
                pass.drawIndexed(3, 1, 0, 0, 0);
            }
        }
    };
}
