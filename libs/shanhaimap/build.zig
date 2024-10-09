const std = @import("std");
const Build = std.Build;
const ModuleImport = struct {
    module: *Build.Module,
    name: []const u8,
    linkLib: ?*Build.Step.Compile = null,
};
fn addImport(module: *std.Build.Module, imports: *const [5]ModuleImport) void {
    for (imports) |import| {
        module.addImport(import.name, import.module);
        if (import.linkLib) |linkLib| {
            module.linkLibrary(linkLib);
        }
    }
}
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zglfw = b.dependency("zglfw", .{});
    const zgpu = b.dependency("zgpu", .{});
    const zgui = b.dependency("zgui", .{
        .target = target,
        .optimize = optimize,
        .backend = .glfw_wgpu,
    });
    const uuid = b.dependency("uuid", .{});
    const math = b.dependency("math", .{
        .target = target,
        .optimize = optimize,
    });
    //导入模块
    const imports = [_]ModuleImport{
        .{ .module = zglfw.module("root"), .name = "zglfw", .linkLib = zglfw.artifact("glfw") },
        .{ .module = zgpu.module("root"), .name = "zgpu", .linkLib = zgpu.artifact("zdawn") },
        .{ .module = zgui.module("root"), .name = "zgui", .linkLib = zgui.artifact("imgui") },
        .{ .module = uuid.module("uuid"), .name = "uuid" },
        .{ .module = math.module("root"), .name = "math" },
    };

    const exe = b.addExecutable(.{
        .name = "shanhaimap",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    @import("system_sdk").addLibraryPathsTo(exe);
    @import("zgpu").addLibraryPathsTo(exe);
    addImport(&exe.root_module, &imports);
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    @import("system_sdk").addLibraryPathsTo(lib_unit_tests);
    @import("zgpu").addLibraryPathsTo(lib_unit_tests);
    addImport(&lib_unit_tests.root_module, &imports);

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
