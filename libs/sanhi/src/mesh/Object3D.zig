const lib = @import("../lib.zig");
const math = @import("math");
const Mat4 = math.Mat4x4;
const Vec3 = math.Vec3;
const Quat = math.Quat;

pub const Object3D = struct {
    const Self = @This();
    matrix: Mat4 = Mat4.identity(),
    matrixWorld: Mat4 = Mat4.identity(),
    parent: ?*Self = null,
    children: lib.ArrayList(*Self),
    pub fn new() Self {
        return .{ .children = lib.ArrayList(*Self).init(lib.mem.getAllocator()) };
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
    pub fn add(self: *Self, obj: *Self) void {
        if (self == obj) {
            @compileError("obj can't be added as a child of itself.");
        }
        obj.removeFromParent();
        obj.parent = self;
        self.children.append(obj);
    }
    pub fn remove(self: *Self, obj: *Self) void {
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
pub fn SharedObject3D(comptime Self: type) type {
    return struct {
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
        pub inline fn deinit_object3d(self: *Self) void {
            self.object3D.deinit();
        }
    };
}
