const sanhi = @import("../../lib.zig");
const com = @import("./com.zig");
const us = @import("./uniformState.zig");
const ecs = sanhi.ecs;
pub const RenderState = struct {
    world: *ecs.world_t = undefined,
    q_scene: *ecs.query_t = undefined,
    camera: *com.Camera = undefined,
    width: i32 = 0,
    height: i32 = 0,
    uniforms: us.GlobalUniforms = .{},
};
