const math = @import("../math.zig");
const shm = @import("../lib.zig");
pub const TileCorner = struct {
    se: math.Vec3,
    sw: math.Vec3,
    ne: math.Vec3,
    nw: math.Vec3,
    const Self = @This();
};

pub fn projectTilePlaneCorners(
    comptime Tile: type,
    tile: *const Tile,
) TileCorner {
    const geoBox = tile.geoBox;
    const projection = tile.projection();
    const sw = projection.projectPoint(&geoBox.southWest());
    const se = projection.projectPoint(&geoBox.southEast());
    const nw = projection.projectPoint(&geoBox.northWest());
    const ne = projection.projectPoint(&geoBox.northEast());
    return TileCorner{
        .sw = sw,
        .se = se,
        .nw = nw,
        .ne = ne,
    };
}