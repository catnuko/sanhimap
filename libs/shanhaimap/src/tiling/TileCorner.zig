const math = @import("math");
const shm = @import("../root.zig");
pub const TileCorner = struct {
    se: math.Vec3d,
    sw: math.Vec3d,
    ne: math.Vec3d,
    nw: math.Vec3d,
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
