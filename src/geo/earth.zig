const math = @import("std").math;

pub const EARTH_RADIUS: f64 = 6371008.8;
pub const PI: f64 = math.pi;
pub const EARTH_CIRCUMFRENCE: f64 = 2.0 * PI * EARTH_RADIUS; // meters

pub fn circumference_at_latitude(latitude: f64) f64 {
    return EARTH_CIRCUMFRENCE * math.cos(latitude * PI / 180.0);
}

pub fn mercator_x_from_lng(longitude: f64) f64 {
    return (180.0 + longitude) / 360.0;
}

pub fn mercator_y_from_lat(latitude: f64) f64 {
    return (180.0 - (180.0 / PI * math.ln(math.tan(PI / 4.0 + latitude * PI / 360.0)))) / 360.0;
}

pub fn mercator_z_from_altitude(latitude: f64, altitude: f64) f64 {
    return altitude / circumference_at_latitude(latitude);
}
