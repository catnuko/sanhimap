const std = @import("std");
const Build = std.Build;
const ModuleImport = struct {
    module: *Build.Module,
    name: []const u8,
};
const BuildCollection = struct {
    add_imports: []const ModuleImport,
    link_libraries: []const *Build.Step.Compile,
};

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
    //导入模块
    const lib_root_module_imports = [_]ModuleImport{
        .{ .module = zglfw.module("root"), .name = "zglfw" },
        .{ .module = zgpu.module("root"), .name = "zgpu" },
        .{ .module = zgui.module("root"), .name = "zgui" },
        .{ .module = uuid.module("uuid"), .name = "uuid" },
    };
    //静态链接库
    const link_libraries = [_]*Build.Step.Compile{
        zgui.artifact("imgui"),
        zglfw.artifact("glfw"),
        zgpu.artifact("zdawn"),
    };

    const build_collection: BuildCollection = .{
        .add_imports = &lib_root_module_imports,
        .link_libraries = &link_libraries,
    };
    const lib_mod = b.addModule("lib", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    for (build_collection.add_imports) |build_import| {
        lib_mod.addImport(build_import.name, build_import.module);
    }
    for (build_collection.link_libraries) |library| {
        lib_mod.linkLibrary(library);
    }
    // const lib = b.addStaticLibrary(.{
    //     .name = "lib",
    //     .root_source_file = b.path("src/lib.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });
    // @import("system_sdk").addLibraryPathsTo(lib);
    // @import("zgpu").addLibraryPathsTo(lib);
    // b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "geo",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    @import("system_sdk").addLibraryPathsTo(exe);
    @import("zgpu").addLibraryPathsTo(exe);
    exe.root_module.addImport("lib", lib_mod);
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    //test step
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
