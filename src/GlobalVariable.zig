const lib = @import("lib.zig");
var mercatorTilingScheme: ?lib.TilingScheme = undefined;
var webMercatorTilingScheme: ?lib.TilingScheme = undefined;
pub fn getMercatorTilingScheme() lib.TilingScheme {
    if (mercatorTilingScheme == null) {
        mercatorTilingScheme = lib.TilingScheme.new(
            lib.quadTreeSubdivisionScheme,
            lib.mercatorProjection,
        );
    }
    return mercatorTilingScheme.?;
}
pub fn getWebMercatorTilingScheme() lib.TilingScheme {
    if (webMercatorTilingScheme == null) {
        webMercatorTilingScheme = lib.TilingScheme.new(
            lib.quadTreeSubdivisionScheme,
            lib.webMercatorProjection,
        );
    }
    return webMercatorTilingScheme.?;
}

test "GlobalVariable" {
    const webMercatorTilingSchemeT = getWebMercatorTilingScheme();
    const testing = @import("std").testing;
    try testing.expectEqual(webMercatorTilingSchemeT.getSubTileKeys(lib.TileKey.new(0, 0, 0)).len, 4);
}
