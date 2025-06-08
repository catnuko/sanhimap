const std = @import("std");
const Build = std.Build;
const ModuleImport = struct {
    module: *Build.Module,
    name: []const u8,
    linkLib: ?*Build.Step.Compile = null,
};
fn addImport(module: *std.Build.Module, imports: *const [4]ModuleImport) void {
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

    const math = b.dependency("math", .{
        .target = target,
        .optimize = optimize,
    });
    const zflecs = b.dependency("zflecs", .{
        .target = target,
        .optimize = optimize,
    });
    const sokol = b.dependency("sokol", .{
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
        .{ .module = sokol.module("sokol"), .name = "sokol" },
        .{ .module = zflecs.module("root"), .name = "zflecs", .linkLib = zflecs.artifact("flecs") },
        .{ .module = zmesh.module("root"), .name = "zmesh", .linkLib = zmesh.artifact("zmesh") },
        .{ .module = math.module("root"), .name = "math" },
    };
    const sanhi_mod = b.addModule("root", .{
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

    const names = [_][]const u8{ "app", "ecs", "ecs2", "str" };

    for (names) |name| {
        try build_examples(b, target, optimize, name, sanhi_mod);
    }

    const lib_tests = b.addTest(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&lib_tests.step);
}

fn build_examples(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, name: []const u8, sanhi_mod: *std.Build.Module) !void {
    var root_source_buffer = [_]u8{undefined} ** 100;
    const root_source_file = try std.fmt.bufPrint(&root_source_buffer, "./examples/{s}.zig", .{name});
    const app = b.addExecutable(.{
        .target = target,
        .optimize = optimize,
        .name = name,
        .root_source_file = b.path(root_source_file),
    });
    app.root_module.addImport("sanhi", sanhi_mod);

    // app.linkLibrary(sanhi_lib);
    b.installArtifact(app);
    const run = b.addRunArtifact(app);
    var option_buffer = [_]u8{undefined} ** 100;
    const run_name = try std.fmt.bufPrint(&option_buffer, "run-{s}", .{name});
    var description_buffer = [_]u8{undefined} ** 200;
    const descr_name = try std.fmt.bufPrint(&description_buffer, "run {s} example", .{name});
    b.step(run_name, descr_name).dependOn(&run.step);
}
