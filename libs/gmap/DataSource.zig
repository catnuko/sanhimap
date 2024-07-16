const lib = @import("lib.zig");
const Self = @This();
pub const VTable = struct {
    getTilingScheme: *const fn (ctx: *anyopaque) lib.TilingScheme,
    getTile: *const fn (ctx: *anyopaque, tileKey: lib.TileKey) ?lib.Tile,
};
ptr: *anyopaque = undefined,
vtable: *const VTable = undefined,
name: []const u8,
addGroundPlane: bool = false,
minDataLevel: u16 = 1,
maxDataLevel: u16 = 20,
minDisplayLevel: u16 = 1,
maxDisplayLevel: u16 = 20,
enablePicking: bool = true,
dataSourceOrder: u16 = 0,
cacheable: bool = false,
pub fn new(name: []const u8) Self {
    return .{
        .name = name,
    };
}
pub fn getTilingScheme(
    self: Self,
) lib.TilingScheme {
    return self.vtable.getTilingScheme(self.ptr);
}
pub fn getTile(self: Self, tileKey: lib.TileKey) lib.TilingScheme {
    return self.vtable.getTile(self.ptr, tileKey);
}
