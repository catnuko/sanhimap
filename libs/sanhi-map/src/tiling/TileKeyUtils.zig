const std = @import("std");
const math = @import("../math.zig");
const TileKey = @import("./TileKey.zig");
const Cargotrphic = @import("../Cartographic.zig");
const GeoBox = @import("../GeoBox.zig");
const allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
pub fn geoCoordinatesToTileKey(comptime TilingScheme: type, tilingscheme: TilingScheme, geopoint: *const Cargotrphic, level: u32) ?TileKey {
    const projection = tilingscheme.projection;
    const worldpoint = projection.projectPoint(geopoint);
    return worldCoordinatesToTileKey(tilingscheme, worldpoint, level);
}
pub fn worldCoordinatesToTileKey(comptime TilingScheme: type, tilingscheme: TilingScheme, worldpoint: *const Cargotrphic, level: u32) ?TileKey {
    const projection = tilingscheme.projection;
    const subdivision_scheme = tilingscheme.subdivision_scheme;

    const cx = subdivision_scheme.getLevelDimensionX(level);
    const cy = subdivision_scheme.getLevelDimensionY(level);

    const geobox = projection.worldExtent(0, 0);
    const min = geobox.min;
    const max = geobox.max;

    const worldSizeX = max.x - min.x;
    const worldSizeY = max.y - min.y;

    if (worldpoint.x < min.x or worldpoint.x > max.x) {
        return null;
    }

    if (worldpoint.y < min.y or worldpoint.y > max.y) {
        return null;
    }

    const column = math.min(cx - 1, math.floor((cx * (worldpoint.x - min.x)) / worldSizeX));
    const row = math.min(cy - 1, math.floor((cy * (worldpoint.y - min.y)) / worldSizeY));

    return TileKey.fromRowColumnLevel(row, column, level);
}
pub fn geoRectangleToTileKeys(comptime TilingScheme: type, tilingscheme: TilingScheme, geobox: GeoBox, level: u32) []TileKey {
    // Clamp at the poles and wrap around the international date line.
    const southWestLongitude = wrap(geobox.southWest.longitudeInRadians, -stdmath.pi, stdmath.pi);
    const southWestLatitude = math.clamp(geobox.southWest.latitudeInRadians, -(stdmath.pi * 0.5), stdmath.pi * 0.5);
    const northEastLongitude = wrap(geobox.northEast.longitudeInRadians, -stdmath.pi, stdmath.pi);
    const northEastLatitude = math.clamp(geobox.northEast.latitudeInRadians, -(stdmath.pi * 0.5), stdmath.pi * 0.5);
    const minTileKey = geoCoordinatesToTileKey(tilingscheme, &Cargotrphic.fromRadians(southWestLatitude, southWestLongitude), level);
    const maxTileKey = geoCoordinatesToTileKey(tilingscheme, &Cargotrphic.fromRadians(northEastLatitude, northEastLongitude), level);
    const columnCount = tilingscheme.subdivisionScheme.getLevelDimensionX(level);

    if (!minTileKey || !maxTileKey) {
        unreachable;
    }

    const minColumn = minTileKey.column;
    var maxColumn = maxTileKey.column;

    // wrap around case
    if (southWestLongitude > northEastLongitude) {
        if (maxColumn != minColumn) {
            maxColumn += columnCount;
        } else {
            // do not duplicate
            maxColumn += columnCount - 1;
        }
    }
    const minRow = @min(minTileKey.row, maxTileKey.row);
    const maxRow = @max(minTileKey.row, maxTileKey.row);
    const len = (maxRow - minRow) * (maxColumn - minColumn);
    const keys: [len]TileKey = .{};
    // const keys = ArrayList(TileKey).init(allocator);
    for (minRow..maxRow) |row| {
        for (minColumn..maxColumn) |column| {
            keys.append(TileKey.new(row, column % columnCount, level));
        }
    }
    return keys.items;
}
pub fn wrap(value: f64, lower: f64, upper: f64) f64 {
    if (value < lower) {
        return upper - @mod((lower - value), (upper - lower));
    }

    return lower + @mod((value - lower), (upper - lower));
}
