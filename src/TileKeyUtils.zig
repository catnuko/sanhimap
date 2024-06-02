const std = @import("std");
const stdmath = std.math;
const lib = @import("./lib.zig");
const TileKey = lib.TileKey;
const GeoCoordinates = lib.GeoCoordinates;
const GeoBox = lib.GeoBox;
const allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
pub fn geocoordinates_to_tilekey(comptime TilingScheme: type, tilingscheme: TilingScheme, geopoint: GeoCoordinates, level: u32) ?TileKey {
    const projection = tilingscheme.projection;
    const worldpoint = projection.projectPoint(geopoint);
    return worldcoordinates_to_tilekey(tilingscheme, worldpoint, level);
}
pub fn worldcoordinates_to_tilekey(comptime TilingScheme: type, tilingscheme: TilingScheme, worldpoint: GeoCoordinates, level: u32) ?TileKey {
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

    const column = stdmath.min(cx - 1, stdmath.floor((cx * (worldpoint.x - min.x)) / worldSizeX));
    const row = stdmath.min(cy - 1, stdmath.floor((cy * (worldpoint.y - min.y)) / worldSizeY));

    return TileKey.fromRowColumnLevel(row, column, level);
}
pub fn georectangle_to_tilekeys(comptime TilingScheme: type, tilingscheme: TilingScheme, geobox: GeoBox, level: u32) ArrayList(TileKey) {
    // Clamp at the poles and wrap around the international date line.
    const southWestLongitude = wrap(geobox.southWest.longitudeInRadians, -stdmath.pi, stdmath.pi);
    const southWestLatitude = stdmath.clamp(geobox.southWest.latitudeInRadians, -(stdmath.pi * 0.5), stdmath.pi * 0.5);
    const northEastLongitude = wrap(geobox.northEast.longitudeInRadians, -stdmath.pi, stdmath.pi);
    const northEastLatitude = stdmath.clamp(geobox.northEast.latitudeInRadians, -(stdmath.pi * 0.5), stdmath.pi * 0.5);
    const minTileKey = geocoordinates_to_tilekey(tilingscheme, GeoCoordinates.fromRadians(southWestLatitude, southWestLongitude), level);
    const maxTileKey = geocoordinates_to_tilekey(tilingscheme, GeoCoordinates.fromRadians(northEastLatitude, northEastLongitude), level);
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

    const keys = ArrayList(TileKey).init(allocator);
    for (minRow..maxRow) |row| {
        for (minColumn..maxColumn) |column| {
            keys.append(TileKey.new(row, column % columnCount, level));
        }
    }
    return keys;
}
pub fn wrap(value: f64, lower: f64, upper: f64) f64 {
    if (value < lower) {
        return upper - ((lower - value) % (upper - lower));
    }

    return lower + ((value - lower) % (upper - lower));
}
