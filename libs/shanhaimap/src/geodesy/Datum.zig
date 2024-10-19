const Ellipsoid = @import("Ellipsoid.zig").Ellipsoid;
pub const Datum = struct {
    ellipsoid: Ellipsoid,
    transform: [7]f64,
    pub const ED50: Datum = new(Ellipsoid.Intl1924, .{ 89.5, 93.8, 123.1, -1.2, 0.0, 0.0, 0.156 }); // epsg.io/1311
    pub const ETRS89: Datum = new(Ellipsoid.GRS80, .{ 0, 0, 0, 0, 0, 0, 0 }); // epsg.io/1149; @ 1-metre level
    pub const Irl1975: Datum = new(Ellipsoid.AiryModified, .{ -482.530, 130.596, -564.557, -8.150, 1.042, 0.214, 0.631 }); // epsg.io/1954
    pub const NAD27: Datum = new(Ellipsoid.Clarke1866, .{ 8, -160, -176, 0, 0, 0, 0 });
    pub const NAD83: Datum = new(Ellipsoid.GRS80, .{ 0.9956, -1.9103, -0.5215, -0.00062, 0.025915, 0.009426, 0.011599 });
    pub const NTF: Datum = new(Ellipsoid.Clarke1880IGN, .{ 168, 60, -320, 0, 0, 0, 0 });
    pub const OSGB36: Datum = new(Ellipsoid.Airy1830, .{ -446.448, 125.157, -542.060, 20.4894, -0.1502, -0.2470, -0.8421 }); // epsg.io/1314
    pub const Potsdam: Datum = new(Ellipsoid.Bessel1841, .{ -582, -105, -414, -8.3, 1.04, 0.35, -3.08 });
    pub const TokyoJapan: Datum = new(Ellipsoid.Bessel1841, .{ 148, -507, -685, 0, 0, 0, 0 });
    pub const WGS72: Datum = new(Ellipsoid.WGS72, .{ 0, 0, -4.5, -0.22, 0, 0, 0.554 });
    pub const WGS84: Datum = new(Ellipsoid.WGS84, .{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 });
    const Self = @This();
    pub fn new(e: Ellipsoid, t: [7]f64) Self {
        return .{ .ellipsoid = e, .transform = t };
    }
};
