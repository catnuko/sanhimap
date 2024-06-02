const std = @import("std");
const expectEqual = std.testing.expectEqual;
const math = std.math;
pub const EXTENT_UINT: u32 = 4096;
pub const EXTENT_SINT: i32 = @as(i32, EXTENT_UINT);
pub const EXTENT: f64 = @as(f64, EXTENT_UINT);
pub const TILE_SIZE: f64 = 512.0;
pub const MAX_ZOOM: usize = 32;

pub const ZOOM_BOUNDS: [MAX_ZOOM]u32 = create_zoom_bounds();

fn create_zoom_bounds() [MAX_ZOOM]u32 {
    const result = [_]u8{0} ** MAX_ZOOM;
    var i: u32 = 0;
    while (i < MAX_ZOOM) : (i += 1) {
        result[i] = math.pow(u32, 2, i);
    }
    return result;
}

pub const TileCoord = struct {
    x: u32,
    y: u32,
    z: u32,
    pub fn new(x: u32, y: u32, z: u32) TileCoord {
        return .{
            .x = x,
            .y = y,
            .z = z,
        };
    }
    pub fn children(self: TileCoord) [4]TileCoord {
        return [4]TileCoord{ TileCoord.new(
            self.x * 2,
            self.y * 2,
            self.z + 1,
        ), TileCoord.new(
            self.x * 2 + 1,
            self.y * 2,
            self.z + 1,
        ), TileCoord.new(
            self.x * 2 + 1,
            self.y * 2 + 1,
            self.z + 1,
        ), TileCoord.new(
            self.x * 2,
            self.y * 2 + 1,
            self.z + 1,
        ) };
    }
    pub fn parent(self: TileCoord) ?TileCoord {
        if (self.z == 0) {
            return null;
        }
        return TileCoord.new(
            self.x >> 1,
            self.y >> 1,
            self.z - 1,
        );
    }
};
test "tests" {}
