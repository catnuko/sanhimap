const math = @import("std").math;
pub const EQUATORIAL_CIRCUMFERENCE: f64 = 40075016.6855784861531768177614;
pub const EQUATORIAL_RADIUS: f64 = 6378137.0;
pub const MIN_ELEVATION: f64 = -433.0;
pub const MAX_ELEVATION: f64 = 8848.0;
pub const MAX_BUILDING_HEIGHT: f64 = 828;
pub fn circumference_at_latitude(latitude: f64) f64 {
    return EQUATORIAL_CIRCUMFERENCE * math.cos(latitude * math.pi / 180.0);
}

pub fn mercator_x_from_lng(longitude: f64) f64 {
    return (180.0 + longitude) / 360.0;
}

pub fn mercator_y_from_lat(latitude: f64) f64 {
    return (180.0 - (180.0 / math.pi * math.ln(math.tan(math.pi / 4.0 + latitude * math.pi / 360.0)))) / 360.0;
}

pub fn mercator_z_from_altitude(latitude: f64, altitude: f64) f64 {
    return altitude / circumference_at_latitude(latitude);
}
