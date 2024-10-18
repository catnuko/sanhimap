const App = @import("./index.zig").App;
pub const Plugin = struct {
    const Self = @This();
    pub const VTable = struct {
        build: *const fn (ctx: *anyopaque, app: *App) void,
        setup: *const fn (ctx: *anyopaque, app: *App) void,
    };
    name: []const u8,
    ptr: *anyopaque,
    vtable: *const VTable,
    pub fn new(namev: []const u8, ptr: *anyopaque, vtable: *const VTable) Self {
        return .{
            .name = namev,
            .ptr = ptr,
            .vtable = vtable,
        };
    }
    pub fn build(self: *const Self, app: *App) void {
        return self.vtable.build(self.ptr, app);
    }
    pub fn setups(self: *const Self, app: *App) void {
        return self.vtable.setup(self.ptr, app);
    }
};
