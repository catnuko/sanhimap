pub const Ellipsoid = struct {
    a: f64,
    b: f64,
    f: f64,
};
pub const WGS84: Ellipsoid = .{ .a = 6378137, .b = 6356752.314245, .f = 1 / 298.257223563 };
pub const Airy1830: Ellipsoid = .{ .a = 6377563.396, .b = 6356256.909, .f = 1 / 299.3249646 };
pub const AiryModified: Ellipsoid = .{ .a = 6377340.189, .b = 6356034.448, .f = 1 / 299.3249646 };
pub const Bessel1841: Ellipsoid = .{ .a = 6377397.155, .b = 6356078.962822, .f = 1 / 299.15281285 };
pub const Clarke1866: Ellipsoid = .{ .a = 6378206.4, .b = 6356583.8, .f = 1 / 294.978698214 };
pub const Clarke1880IGN: Ellipsoid = .{ .a = 6378249.2, .b = 6356515.0, .f = 1 / 293.466021294 };
pub const GRS80: Ellipsoid = .{ .a = 6378137, .b = 6356752.314140, .f = 1 / 298.257222101 };
pub const Intl1924: Ellipsoid = .{ .a = 6378388, .b = 6356911.946128, .f = 1 / 297 }; // aka Hayford
pub const WGS72: Ellipsoid = .{ .a = 6378135, .b = 6356750.52, .f = 1 / 298.26 };
