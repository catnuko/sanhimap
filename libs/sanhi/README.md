# sanhi
A 3d render engine inspired by threejs is the rendering engine for sanhi-map.
## examples
```bash
cd libs/sanhi
zig build run-basic
```
![basic](./static/basic.png)


## install
1. add sanhi to build.zig.zon
```zig

.{
    .name = "sanhimap",
    .version = "0.0.0",
    .dependencies = .{
        .sanhi = .{ .path = "../sanhi" },
        ......
    }   
}
```

1. build.zig
```zig
const sanhi = b.dependency("sanhi", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("sanhi", sanhi.module("root"));

```

1. main.zig

```zig
const sanhi = @import("sanhi");
const vec3d = sanhi.math.vec3d(1,1,1);
```