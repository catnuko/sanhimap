const math = @import("../../math.zig");
const com = @import("./com.zig");

pub const GlobalUniforms = struct {
    encodedCameraPositionMCHigh: math.Vec3 = math.Vec3.zero(),
    encodedCameraPositionMCLow: math.Vec3 = math.Vec3.zero(),
    modelViewProjectionRelativeToEye: math.Mat4.identity(),
    model: math.Mat4.identity(),
    view: math.Mat4.identity(),
    projection: math.Mat4.identity(),
    modelView: math.Mat4.identity(),
    modelViewRelativeToEye: math.Mat4.identity(),
};

pub const GPUGlobalUniforms = struct {
    encodedCameraPositionMCHigh: math.Vec3f = math.Vec3f.zero(),
    encodedCameraPositionMCLow: math.Vec3f = math.Vec3f.zero(),
};

pub fn initGlobeUniforms(camera: com.Camera, globalUniforms: *GlobalUniforms) void {
    const encodedCameraPosition = math.EncodedVec3.fromVec3(camera.position);
    globalUniforms.encodedCameraPositionMCHigh = encodedCameraPosition.high;
    globalUniforms.encodedCameraPositionMCLow = encodedCameraPosition.low;
}
