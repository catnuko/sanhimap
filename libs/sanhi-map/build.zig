const std = @import("std");
const builtin = @import("builtin");

var target: Build.ResolvedTarget = undefined;
var optimize: std.builtin.OptimizeMode = undefined;

const Build = std.Build;
const ModuleImport = struct {
    module: *Build.Module,
    name: []const u8,
    linkLib: ?*Build.Step.Compile = null,
};
fn addImport(module: *std.Build.Module, imports: *const [1]ModuleImport) void {
    for (imports) |import| {
        module.addImport(import.name, import.module);
        if (import.linkLib) |lib| {
            module.linkLibrary(lib);
        }
    }
}
pub fn build(b: *std.Build) !void {
    target = b.standardTargetOptions(.{});
    optimize = b.standardOptimizeOption(.{});

    const sanhi = b.dependency("sanhi", .{
        .target = target,
        .optimize = optimize,
    });
    //导入模块
    const imports = [_]ModuleImport{
        .{ .name = "sanhi", .module = sanhi.module("root") },
    };
    // Delve module
    const sanhimap_mod = b.addModule("sanhimap", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    addImport(sanhimap_mod, &imports);

    const sanhimap_lib = b.addStaticLibrary(.{
        .target = target,
        .optimize = optimize,
        .name = "sanhimap",
        .root_source_file = b.path("src/lib.zig"),
    });
    b.installArtifact(sanhimap_lib);

    const app_basic = b.addExecutable(.{
        .target = target,
        .optimize = optimize,
        .name = "basic",
        .root_source_file = b.path("./examples/basic.zig"),
    });
    app_basic.root_module.addImport("sanhimap", sanhimap_mod);
    @import("zgpu").addLibraryPathsTo(app_basic);
    app_basic.linkLibrary(sanhimap_lib);
    b.installArtifact(app_basic);

    const run = b.addRunArtifact(app_basic);
    var option_buffer = [_]u8{undefined} ** 100;
    const run_name = try std.fmt.bufPrint(&option_buffer, "run-{s}", .{"basic"});
    var description_buffer = [_]u8{undefined} ** 200;
    const descr_name = try std.fmt.bufPrint(&description_buffer, "run {s} example", .{"basic"});
    b.step(run_name, descr_name).dependOn(&run.step);

}