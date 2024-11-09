const std = @import("std");
const sanhi = @import("sanhi");
const Mat4 = sanhi.math.math.Mat4x4;
const Vec3 = sanhi.math.math.Vec3;
const zmesh = sanhi.zmesh;
const mesh = sanhi.mesh;
const app = sanhi.app;
pub fn main() !void {
    var viewer = try sanhi.Viewer.new();
    defer viewer.deinit();

    const geometry = mesh.geometry.init_sphere_geometry(50, 50);
    const material = mesh.material.init_basic_material();
    var sphere_mesh = mesh.Mesh.new(geometry, material);
    sphere_mesh.matrix.setScaleScalar(0.5);
    viewer.camera.camera_matrix = Mat4.fromTranslation(&Vec3.new(0, 0, -5));
    viewer.scene.root.add(sphere_mesh);
    viewer.scene.root.add(mesh.meshes.init_axes_mesh(3));
    viewer.scene.root.add(mesh.meshes.init_grid_mesh(10));
    viewer.startMainLoop();
}
