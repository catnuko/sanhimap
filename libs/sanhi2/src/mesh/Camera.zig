const lib = @import("../lib.zig");
const backend = lib.backend;
const zglfw = lib.zglfw;
const math = @import("math");
const Vector2D = math.Vector2D;
const Vector3D = math.Vector3D;
const Mat4 = math.Matrix4D;
const Mat3 = math.Matrix3D;
const QuaternionD = math.QuaternionD;
const HeadingPitchRoll = math.HeadingPitchRoll;
const Self = @This();
fovy: f64,
aspect: f64,
near: f64,
far: f64,
projection_matrix: Mat4 = Mat4.fromIdentity(),
isPerspectiveCamera:bool = true,
isOrthographicCamera:bool = false,
zoom:f64 = 0,
view_projection:Mat4 = Mat4.fromIdentity(),
inverse_view_projection:Mat4 = Mat4.fromIdentity(),


position:Vector3D = Vector3D.fromZero(),
rotation:QuaternionD = QuaternionD.fromZero(),
scale:Vector3D = Vector3D.splat(1),
up:Vector3D = Vector3D.new(0,1,0),

matrix: Mat4 = Mat4.fromIdentity(),
matrix_world: Mat4 = Mat4.fromIdentity(),
view_matrix:Mat4 = Mat4.fromIdentity(),
pub fn new(fovy: f64, aspect: f64, near: f64, far: f64) Self {
    var self: Self = .{ .fovy = fovy, .aspect = aspect, .near = near, .far = far };
    self.updateProjection();
    return self;
}

// pub fn move(self:*Self,direction:*const Vector3D,amount:f64)void{}
// pub fn move_forward(self:*Self,amount:f64)void{}
// pub fn move_back(self:*Self,amount:f64)void{}
// pub fn move_left(self:*Self,amount:f64)void{}
// pub fn move_right(self:*Self,amount:f64)void{}
// pub fn move_up(self:*Self,amount:f64)void{}
// pub fn move_down(self:*Self,amount:f64)void{}

// pub fn look(self:*Self,axis:*const Vector3D,amount:f64)void{}
// pub fn look_left(self:*Self,amount:f64)void{}
// pub fn look_right(self:*Self,amount:f64)void{}
// pub fn look_up(self:*Self,amount:f64)void{}
// pub fn look_down(self:*Self,amount:f64)void{}

// pub fn rotate(self:*Self,axis:*const Vector3D,amount:f64)void{}
// pub fn rotate_left(self:*Self,amount:f64)void{}
// pub fn rotate_right(self:*Self,amount:f64)void{}
// pub fn rotate_up(self:*Self,amount:f64)void{}
// pub fn rotate_down(self:*Self,amount:f64)void{}
pub fn updateMatrix(self:*Self)void{
    self.matrix = Mat4.fromTranslationQuaternionScale(&self.position,&self.rotation,&self.scale);
    self.updateMatrixWorld();
}
pub fn updateMatrixWorld(self:*Self)void{
    self.matrix_world = self.matrix.clone();
    self.view_matrix = self.matrix_world.inverse();
    self.view_projection = self.projection_matrix.multiply(&self.view_matrix);
    self.inverse_view_projection = self.view_projection.inverse();
}
pub fn updateProjection(self: *Self) void {
    self.projection_matrix = Mat4.perspective(
        self.fovy,
        self.aspect,
        self.near,
        self.far,
    );
}
pub fn lookAt(self:*Self,target:*const Vector3D)void{
    self.rotation = QuaternionD.fromRotationMatrix(&math.Matrix3D.lookAt(&self.position,target,&self.up));
}
pub fn project(self:*const Self,point:*const Vector3D)Vector3D{
    return self.view_projection.multiplyByPoint(point);
}
pub fn unproject(self:*const Self,point:*const Vector2D)Vector3D{
    return self.inverse_view_projection.multiplyByPoint(&Vector3D.new(point.x(),point.y(),0));
}