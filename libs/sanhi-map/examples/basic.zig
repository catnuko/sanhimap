const std = @import("std");
const sanhimap = @import("sanhimap");
const sanhi = sanhimap.sanhi;

const Mat4 = sanhi.math.Matrix4;
const Quaternion = sanhi.math.Quaternion;
const Vector3 = sanhi.math.Vector3;
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
    viewer.camera.position.setZ(5);
    viewer.camera.updateMatrix();
    viewer.scene.root.add(sphere_mesh);
    viewer.scene.root.add(mesh.meshes.init_axes_mesh(3));
    viewer.scene.root.add(mesh.meshes.init_grid_mesh(10));
    viewer.startMainLoop();
}
