const std = @import("std");
const builtin = @import("builtin");
const ziglua = @import("ziglua");
const sokol = @import("sokol");
const system_sdk = @import("system-sdk");
const fs = std.fs;
const log = std.log;

var target: Build.ResolvedTarget = undefined;
var optimize: std.builtin.OptimizeMode = undefined;

const Build = std.Build;
const ModuleImport = struct {
    module: *Build.Module,
    name: []const u8,
    linkLib: ?*Build.Step.Compile = null,
};
fn addImport(module: *std.Build.Module, imports: *const [10]ModuleImport, dep_sokol: *std.Build.Dependency) void {
    for (imports) |import| {
        module.addImport(import.name, import.module);
        if (import.linkLib) |lib| {
            if (target.result.isWasm()) {
                lib.step.dependOn(&dep_sokol.artifact("sokol_clib").step);
            }
            module.linkLibrary(lib);
        }
    }
}
pub fn build(b: *std.Build) !void {
    target = b.standardTargetOptions(.{});
    optimize = b.standardOptimizeOption(.{});

    const uuid = b.dependency("uuid", .{});
    const math = b.dependency("math", .{
        .target = target,
        .optimize = optimize,
    });
    var dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
        .with_sokol_imgui = true,
    });
    const dep_ziglua = b.dependency("ziglua", .{
        .target = target,
        .optimize = optimize,
        .lang = .lua54,
        .can_use_jmp = !target.result.isWasm(),
    });

    const dep_zmesh = b.dependency("zmesh", .{
        .target = target,
        .optimize = optimize,
    });

    const dep_zaudio = b.dependency("zaudio", .{
        .target = target,
        .optimize = optimize,
    });

    const dep_zstbi = b.dependency("zstbi", .{
        .target = target,
        .optimize = optimize,
    });

    const dep_cimgui = b.dependency("cimgui", .{
        .target = target,
        .optimize = optimize,
    });

    const dep_stb_truetype = b.dependency("stb_truetype", .{
        .target = target,
        .optimize = optimize,
    });

    const dep_yamlz = b.dependency("ymlz", .{
        .target = target,
        .optimize = optimize,
    });
    // inject the cimgui header search path into the sokol C library compile step
    const cimgui_root = dep_cimgui.namedWriteFiles("cimgui").getDirectory();
    dep_sokol.artifact("sokol_clib").addIncludePath(cimgui_root);
    dep_stb_truetype.artifact("stb_truetype").addIncludePath(b.path("../../third/stb_truetype/libs"));

    //导入模块
    const imports = [_]ModuleImport{
        .{ .name = "uuid", .module = uuid.module("uuid") },
        .{ .name = "math", .module = math.module("root") },
        .{ .name = "sokol", .module = dep_sokol.module("sokol") },
        .{ .name = "ziglua", .module = dep_ziglua.module("ziglua"), .linkLib = dep_ziglua.artifact("lua") },
        .{ .name = "zmesh", .module = dep_zmesh.module("root"), .linkLib = dep_zmesh.artifact("zmesh") },
        .{ .name = "zstbi", .module = dep_zstbi.module("root"), .linkLib = dep_zstbi.artifact("zstbi") },
        .{ .name = "zaudio", .module = dep_zaudio.module("root"), .linkLib = dep_zaudio.artifact("miniaudio") },
        .{ .name = "cimgui", .module = dep_cimgui.module("cimgui"), .linkLib = dep_cimgui.artifact("cimgui_clib") },
        .{ .name = "stb_truetype", .module = dep_stb_truetype.module("root"), .linkLib = dep_stb_truetype.artifact("stb_truetype") },
        .{ .name = "ymlz", .module = dep_yamlz.module("root") },
    };
    // Delve module
    var shanhaimap_mod = b.addModule("shanhaimap", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    addImport(shanhaimap_mod, &imports, dep_sokol);

    if (target.result.isWasm()) {
        const emsdk_include_path = getEmsdkSystemIncludePath(dep_sokol);
        shanhaimap_mod.addSystemIncludePath(emsdk_include_path);
        for (imports) |import| {
            import.module.addSystemIncludePath(emsdk_include_path);
            if (import.linkLib) |lib| {
                lib.addSystemIncludePath(emsdk_include_path);
            }
        }
    }

    const shanhaimap_lib = b.addStaticLibrary(.{
        .target = target,
        .optimize = optimize,
        .name = "shanhaimap",
        .root_source_file = b.path("src/lib.zig"),
    });

    b.installArtifact(shanhaimap_lib);

    const examples = [_][]const u8{
        "clear",
    };

    for (examples) |example_item| {
        try buildExample(b, example_item, shanhaimap_mod, shanhaimap_lib);
    }

    buildShaders(b);

    const lib_tests = b.addTest(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    // addImport(&lib_tests.root_module, &imports, dep_sokol);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&lib_tests.step);
}

fn buildExample(b: *std.Build, example: []const u8, shanhaimap_module: *Build.Module, shanhaimap_lib: *Build.Step.Compile) !void {
    const name: []const u8 = example;
    var root_source_buffer = [_]u8{undefined} ** 256;
    const root_source_file = try std.fmt.bufPrint(&root_source_buffer, "examples/{s}.zig", .{name});

    var app: *Build.Step.Compile = undefined;
    // special case handling for native vs web build
    if (target.result.isWasm()) {
        app = b.addStaticLibrary(.{
            .target = target,
            .optimize = optimize,
            .name = name,
            .root_source_file = b.path(root_source_file),
        });
    } else {
        app = b.addExecutable(.{
            .target = target,
            .optimize = optimize,
            .name = name,
            .root_source_file = b.path(root_source_file),
        });
    }

    app.root_module.addImport("shanhaimap", shanhaimap_module);
    app.linkLibrary(shanhaimap_lib);

    if (target.result.isWasm()) {
        const dep_sokol = b.dependency("sokol", .{
            .target = target,
            .optimize = optimize,
            .with_sokol_imgui = true,
        });

        // link with emscripten
        const link_step = try emscriptenLinkStep(b, app, dep_sokol);

        // and add a run step
        const run = emscriptenRunStep(b, example, dep_sokol);
        run.step.dependOn(&link_step.step);

        var option_buffer = [_]u8{undefined} ** 100;
        const run_name = try std.fmt.bufPrint(&option_buffer, "run-{s}", .{name});
        var description_buffer = [_]u8{undefined} ** 200;
        const descr_name = try std.fmt.bufPrint(&description_buffer, "run {s}", .{name});
        b.step(run_name, descr_name).dependOn(&run.step);
    } else {
        b.installArtifact(app);
        const run = b.addRunArtifact(app);
        var option_buffer = [_]u8{undefined} ** 100;
        const run_name = try std.fmt.bufPrint(&option_buffer, "run-{s}", .{name});
        var description_buffer = [_]u8{undefined} ** 200;
        const descr_name = try std.fmt.bufPrint(&description_buffer, "run {s}", .{name});

        b.step(run_name, descr_name).dependOn(&run.step);
    }
}

pub fn emscriptenLinkStep(b: *Build, app: *Build.Step.Compile, dep_sokol: *Build.Dependency) !*Build.Step.InstallDir {
    app.defineCMacro("__EMSCRIPTEN__", "1");

    const emsdk = dep_sokol.builder.dependency("emsdk", .{});

    // Add the Emscripten system include path for the app too
    const emsdk_include_path = emsdk.path("upstream/emscripten/cache/sysroot/include");
    app.addSystemIncludePath(emsdk_include_path);

    return try sokol.emLinkStep(b, .{
        .lib_main = app,
        .target = target,
        .optimize = optimize,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .release_use_closure = false, // causing errors with miniaudio? might need to add a custom exerns file for closure
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = b.path(dep_sokol.path("src/sokol/web/shell.html").getPath(b)),
        .extra_args = &.{
            "-sUSE_OFFSET_CONVERTER=1",
            "-sTOTAL_STACK=16MB",
            "--preload-file=assets/",
            "-sALLOW_MEMORY_GROWTH=1",
            "-sSAFE_HEAP=0",
            "-sERROR_ON_UNDEFINED_SYMBOLS=0",
        },
    });
}

pub fn getEmsdkSystemIncludePath(dep_sokol: *Build.Dependency) Build.LazyPath {
    const dep_emsdk = dep_sokol.builder.dependency("emsdk", .{});
    return dep_emsdk.path("upstream/emscripten/cache/sysroot/include");
}

pub fn emscriptenRunStep(b: *Build, name: []const u8, dep_sokol: *Build.Dependency) *Build.Step.Run {
    const emsdk = dep_sokol.builder.dependency("emsdk", .{});
    return sokol.emRunStep(b, .{ .name = name, .emsdk = emsdk });
}
// Adds a run step to compile shaders, expects the shader compiler in ../sokol-tools-bin/
fn buildShaders(b: *Build) void {
    const sokol_tools_bin_dir = "../sokol-tools-bin/bin/";
    const shaders_dir = "assets/shaders/";
    const shaders_out_dir = "src/render/graphics/shaders/";

    const shaders = .{
        "basic-lighting",
        "default",
        "default-mesh",
        "emissive",
        "skinned-basic-lighting",
        "skinned",
    };

    const optional_shdc: ?[:0]const u8 = comptime switch (builtin.os.tag) {
        .windows => "win32/sokol-shdc.exe",
        .linux => "linux/sokol-shdc",
        .macos => if (builtin.cpu.arch.isX86()) "osx/sokol-shdc" else "osx_arm64/sokol-shdc",
        else => null,
    };

    if (optional_shdc == null) {
        std.log.warn("unsupported host platform, skipping shader compiler step", .{});
        return;
    }

    const shdc_step = b.step("shaders", "Compile shaders (needs ../sokol-tools-bin)");
    const shdc_path = sokol_tools_bin_dir ++ optional_shdc.?;
    const slang = "glsl300es:glsl430:wgsl:metal_macos:metal_ios:metal_sim:hlsl4";

    // build the .zig versions
    inline for (shaders) |shader| {
        const shader_with_ext = shader ++ ".glsl";
        const cmd = b.addSystemCommand(&.{
            shdc_path,
            "-i",
            shaders_dir ++ shader_with_ext,
            "-o",
            shaders_out_dir ++ shader_with_ext ++ ".zig",
            "-l",
            slang,
            "-f",
            "sokol_zig",
            "--reflection",
        });
        shdc_step.dependOn(&cmd.step);
    }

    // build the yaml reflection versions
    inline for (shaders) |shader| {
        const shader_with_ext = shader ++ ".glsl";
        fs.cwd().makePath(shaders_dir ++ "built/" ++ shader) catch |err| {
            log.info("Could not create path {}", .{err});
        };

        const cmd = b.addSystemCommand(&.{
            shdc_path,
            "-i",
            shaders_dir ++ shader_with_ext,
            "-o",
            shaders_dir ++ "built/" ++ shader ++ "/" ++ shader,
            "-l",
            slang,
            "-f",
            "bare_yaml",
            "--reflection",
        });
        shdc_step.dependOn(&cmd.step);
    }
}
