const lib = @import("../lib.zig");
const std = @import("std");
const wgpu = lib.wgpu;
const zgpu = lib.zgpu;

var app = lib.app;
const Self = @This();

pub fn new() !void {
    try app.init(.{});
    try app.addPlugin(lib.input);
    try app.addPlugin(lib.mesh.module);
}

pub fn startMainLoop() void {
    app.startMainLoop();
}

pub fn deinit() void {
    app.deinit();
}
