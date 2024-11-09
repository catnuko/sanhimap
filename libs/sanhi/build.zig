const std = @import("std");
const Build = std.Build;
const ModuleImport = struct {
    module: *Build.Module,
    name: []const u8,
    linkLib: ?*Build.Step.Compile = null,
};
fn addImport(module: *std.Build.Module, imports: *const [6]ModuleImport) void {
    for (imports) |import| {
        module.addImport(import.name, import.module);
        if (import.linkLib) |linkLib| {
            module.linkLibrary(linkLib);
        }
    }
}
pub fn build(b: *std.Build) !void {
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
    const zmesh = b.dependency("zmesh", .{
        .target = target,
        .optimize = optimize,
        .shape_use_32bit_indices = true,
    });
    //导入模块
    const imports = [_]ModuleImport{
        .{ .module = zglfw.module("root"), .name = "zglfw", .linkLib = zglfw.artifact("glfw") },
        .{ .module = zgpu.module("root"), .name = "zgpu", .linkLib = zgpu.artifact("zdawn") },
        .{ .module = zgui.module("root"), .name = "zgui", .linkLib = zgui.artifact("imgui") },
        .{ .module = zmesh.module("root"), .name = "zmesh", .linkLib = zmesh.artifact("zmesh") },
        .{ .module = uuid.module("uuid"), .name = "uuid" },
        .{ .module = math.module("root"), .name = "math" },
    };
    const sanhi_mod = b.addModule("sanhi", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    addImport(sanhi_mod, &imports);

    const sanhi_lib = b.addStaticLibrary(.{
        .name = "sanhi",
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(sanhi_lib);

    const app = b.addExecutable(.{
        .target = target,
        .optimize = optimize,
        .name = "test",
        .root_source_file = b.path("./examples/test.zig"),
    });
    app.root_module.addImport("sanhi", sanhi_mod);
    @import("system_sdk").addLibraryPathsTo(app);
    @import("zgpu").addLibraryPathsTo(app);
    app.linkLibrary(sanhi_lib);
    b.installArtifact(app);

    const run = b.addRunArtifact(app);
    var option_buffer = [_]u8{undefined} ** 100;
    const run_name = try std.fmt.bufPrint(&option_buffer, "run-{s}", .{"test"});
    var description_buffer = [_]u8{undefined} ** 200;
    const descr_name = try std.fmt.bufPrint(&description_buffer, "run {s} example", .{"test"});
    b.step(run_name, descr_name).dependOn(&run.step);

    const lib_tests = b.addTest(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&lib_tests.step);
}
