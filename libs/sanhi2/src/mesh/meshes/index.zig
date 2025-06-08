const lib = @import("../../lib.zig");
const zmesh = lib.zmesh;
const wgpu = lib.wgpu;
const mesh = @import("../index.zig");
const Mesh = mesh.Mesh;
pub fn init_axes_mesh(size: f32) *Mesh {
    const geometry = mesh.geometry.init_axes_geometry(size);
    const material = mesh.material.init_basic_line_material();
    return Mesh.new(geometry, material);
}
pub fn init_grid_mesh(size: f32) *Mesh {
    const geometry = mesh.geometry.init_grid_geometry(size);
    const material = mesh.material.init_basic_line_material();
    return Mesh.new(geometry, material);
}
