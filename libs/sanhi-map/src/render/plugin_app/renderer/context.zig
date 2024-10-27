const std = @import("std");
const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const simgui = sokol.imgui;
const Allocator = @import("std").mem.Allocator;
const ArrayList = @import("std").ArrayList;
pub const RenderContext = struct {
    const Self = @This();
};

// pub fn test(){
// }
