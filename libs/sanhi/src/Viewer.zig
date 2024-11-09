const lib = @import("./lib.zig");
const wgpu = lib.wgpu;
const zgpu = lib.zgpu;
const zmesh = lib.zmesh;
const app = lib.app;
const math = @import("math");
const Mat4 = math.Mat4x4;
const Vec3 = math.Vec3;
const Quat = math.Quat;
const mesh = lib.mesh;
const Scene = mesh.Scene;
const Camera = mesh.Camera;
const Self = @This();

scene: *Scene,
camera: *Camera,
pub fn new() !Self {
    try app.init(.{});
    const allocator = lib.mem.getAllocator();
    zmesh.init(allocator);
    const scene = try allocator.create(Scene);
    scene.* = Scene.new();
    const width = app.get_width();
    const height = app.get_height();
    const camera = try allocator.create(Camera);
    camera.* = Camera.new(
        math.pi / 3.0,
        @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(height)),
        0.1,
        10000.0,
    );
    mesh.module.init(scene, camera);
    mesh.Control.set_camera(camera);
    return .{
        .scene = scene,
        .camera = camera,
    };
}
pub fn startMainLoop(_: *Self) void {
    try app.addPlugin(mesh.module);
    try app.addPlugin(lib.input);
    try app.addPlugin(mesh.Control);
    app.startMainLoop();
}
pub fn deinit(self: *Self) void {
    const allocator = lib.mem.getAllocator();
    self.scene.deinit();
    allocator.destroy(self.camera);
    allocator.destroy(self.scene);
    zmesh.deinit();
    app.deinit();
}
