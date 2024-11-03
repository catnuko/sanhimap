const mesh = @import("./mesh.zig");
const Context = mesh.Context;
const Object3D = mesh.Object3D;
const SharedObject3D = mesh.SharedObject3D;

const Self = @This();
object3D: Object3D,
pub usingnamespace SharedObject3D(Self);
pub fn new() Self {
    return .{
        .object3D = Object3D.new(),
    };
}
pub fn deinit(self: *Self) void {
    self.deinit_object3d();
}
