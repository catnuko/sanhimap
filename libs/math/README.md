# math
1. add math to build.zig.zon
```zig

.{
    .name = "sanhi",
    .version = "0.0.0",
    .dependencies = .{
        .math = .{ .path = "../math" },
        ......
    }   
}
```

1. build.zig
```zig
const math = b.dependency("math", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("math", math.module("root"));

```

1. main.zig

```zig
const math = @import("math");
const vec3d = math.vec3d(1,1,1);
```