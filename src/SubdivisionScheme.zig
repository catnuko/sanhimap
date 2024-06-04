const std = @import("std");
const lib = @import("lib.zig");
pub const SubdivisionScheme = struct {
    vtable: *const VTable,
    pub const VTable = struct {
        getSubdivisionX: *const fn (level: u32) u32,
        getSubdivisionY: *const fn (level: u32) u32,
        getLevelDimensionX: *const fn (level: u32) u32,
        getLevelDimensionY: *const fn (level: u32) u32,
    };
    pub fn getSubdivisionX(this: SubdivisionScheme, level: u32) u32 {
        return this.vtable.getSubdivisionX(level);
    }
    pub fn getSubdivisionY(this: SubdivisionScheme, level: u32) u32 {
        return this.vtable.getSubdivisionY(level);
    }
    pub fn getLevelDimensionX(this: SubdivisionScheme, level: u32) u32 {
        return this.vtable.getLevelDimensionX(level);
    }
    pub fn getLevelDimensionY(this: SubdivisionScheme, level: u32) u32 {
        return this.vtable.getLevelDimensionY(level);
    }
};
const QuadTreeSubdivisionScheme = struct {
    pub fn getSubdivisionX(_: u32) u32 {
        return 2;
    }
    pub fn getSubdivisionY(_: u32) u32 {
        return 2;
    }
    pub fn getLevelDimensionX(level: u32) u32 {
        return std.math.pow(u32, 2, level);
    }
    pub fn getLevelDimensionY(level: u32) u32 {
        return std.math.pow(u32, 2, level);
    }
    pub fn interface() SubdivisionScheme {
        return .{ .vtable = &.{
            .getSubdivisionX = getSubdivisionX,
            .getSubdivisionY = getSubdivisionY,
            .getLevelDimensionX = getLevelDimensionX,
            .getLevelDimensionY = getLevelDimensionY,
        } };
    }
};
const HalfQuadTreeSubdivisionScheme = struct {
    pub fn getSubdivisionX(_: u32) u32 {
        return 2;
    }
    pub fn getSubdivisionY(level: u32) u32 {
        return if (level == 0) 1 else 2;
    }
    pub fn getLevelDimensionX(level: u32) u32 {
        return std.math.pow(u32, 2, level);
    }
    pub fn getLevelDimensionY(level: u32) u32 {
        return if (level != 0) std.math.pow(u32, 2, level - 1) else 1;
    }
    pub fn interface() SubdivisionScheme {
        return .{ .vtable = &.{
            .getSubdivisionX = getSubdivisionX,
            .getSubdivisionY = getSubdivisionY,
            .getLevelDimensionX = getLevelDimensionX,
            .getLevelDimensionY = getLevelDimensionY,
        } };
    }
};
fn testfn(ss: SubdivisionScheme) u32 {
    return ss.getSubdivisionY(0);
}
test "geo.SubdivisionScheme" {
    const quad = QuadTreeSubdivisionScheme.interface();
    try std.testing.expectEqual(testfn(quad), 2);
    const half = HalfQuadTreeSubdivisionScheme.interface();
    try std.testing.expectEqual(testfn(half), 1);
}
