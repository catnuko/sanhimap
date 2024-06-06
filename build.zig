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
    //导入模块
    const lib_root_module_imports = [_]ModuleImport{
        .{ .module = zglfw.module("root"), .name = "zglfw" },
    };
    //静态链接库
    const link_libraries = [_]*Build.Step.Compile{zglfw.artifact("glfw")};

    const build_collection: BuildCollection = .{
        .add_imports = &lib_root_module_imports,
        .link_libraries = &link_libraries,
    };

    const lib = b.addStaticLibrary(.{
        .name = "lib",
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    for (build_collection.add_imports) |build_import| {
        lib.root_module.addImport(build_import.name, build_import.module);
    }
    for (build_collection.link_libraries) |library| {
        lib.root_module.linkLibrary(library);
    }

    b.installArtifact(lib);

    //zglfw

    const exe = b.addExecutable(.{
        .name = "geo",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
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
