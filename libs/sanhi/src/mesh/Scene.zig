const lib = @import("../lib.zig");
const mesh = @import("./index.zig");
const Context = mesh.Context;
const Object3D = mesh.Object3D;
const Mesh = mesh.Mesh;
const SharedObject3D = mesh.SharedObject3D;
const triangle = mesh.triangle;

const Self = @This();
root: *Mesh,
pub fn new() Self {
    return .{ .root = Mesh.empty() };
}
pub fn upload(self: *Self, ctx: *Context) void {
    self.root.upload(ctx);
}
pub fn draw(self: *Self, ctx: *Context) void {
    self.root.draw(ctx);
}
pub fn deinit(self: *Self) void {
    self.root.deinit();
}
