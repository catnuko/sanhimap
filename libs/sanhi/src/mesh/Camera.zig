const lib = @import("../lib.zig");
const backend = lib.backend;
const zglfw = lib.zglfw;
const math = @import("math");
const Vector2 = math.Vector2;
const Vector3 = math.Vector3;
const Mat4 = math.Matrix4;
const Mat3 = math.Matrix3;
const Quaternion = math.Quaternion;
const HeadingPitchRoll = math.HeadingPitchRoll;
const Self = @This();
fovy: f32,
aspect: f32,
near: f32,
far: f32,
projection_matrix: Mat4 = Mat4.fromIdentity(),
isPerspectiveCamera:bool = true,
isOrthographicCamera:bool = false,
zoom:f32 = 0,
view_projection:Mat4 = Mat4.fromIdentity(),
inverse_view_projection:Mat4 = Mat4.fromIdentity(),


position:Vector3 = Vector3.fromZero(),
rotation:Quaternion = Quaternion.fromZero(),
scale:Vector3 = Vector3.splat(1),
up:Vector3 = Vector3.new(0,1,0),

matrix: Mat4 = Mat4.fromIdentity(),
matrix_world: Mat4 = Mat4.fromIdentity(),
view_matrix:Mat4 = Mat4.fromIdentity(),
pub fn new(fovy: f32, aspect: f32, near: f32, far: f32) Self {
    var self: Self = .{ .fovy = fovy, .aspect = aspect, .near = near, .far = far };
    self.updateProjection();
    return self;
}

// pub fn move(self:*Self,direction:*const Vector3,amount:f32)void{}
// pub fn move_forward(self:*Self,amount:f32)void{}
// pub fn move_back(self:*Self,amount:f32)void{}
// pub fn move_left(self:*Self,amount:f32)void{}
// pub fn move_right(self:*Self,amount:f32)void{}
// pub fn move_up(self:*Self,amount:f32)void{}
// pub fn move_down(self:*Self,amount:f32)void{}

// pub fn look(self:*Self,axis:*const Vector3,amount:f32)void{}
// pub fn look_left(self:*Self,amount:f32)void{}
// pub fn look_right(self:*Self,amount:f32)void{}
// pub fn look_up(self:*Self,amount:f32)void{}
// pub fn look_down(self:*Self,amount:f32)void{}

// pub fn rotate(self:*Self,axis:*const Vector3,amount:f32)void{}
// pub fn rotate_left(self:*Self,amount:f32)void{}
// pub fn rotate_right(self:*Self,amount:f32)void{}
// pub fn rotate_up(self:*Self,amount:f32)void{}
// pub fn rotate_down(self:*Self,amount:f32)void{}
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
pub fn lookAt(self:*Self,target:*const Vector3)void{
    self.rotation = Quaternion.fromRotationMatrix(&math.Matrix3.lookAt(&self.position,target,&self.up));
}
pub fn project(self:*const Self,point:*const Vector3)Vector3{
    return self.view_projection.multiplyByPoint(point);
}
pub fn unproject(self:*const Self,point:*const Vector2)Vector3{
    return self.inverse_view_projection.multiplyByPoint(&Vector3.new(point.x(),point.y(),0));
}