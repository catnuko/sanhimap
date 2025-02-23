const std = @import("std");
const RGBA = @import("./RGBA.zig");

pub const HEX_FULL_CHANNEL: f64 = 0xff;
pub const HEX_RGB_MASK: f64 = 0xffffff;
pub const HEX_TRGB_MASK: f64 = 0xffffffff;
pub const SHIFT_TRANSPARENCY: f64 = 24;
pub const SHIFT_RED: f64 = 16;
pub const SHIFT_GREEN: f64 = 8;
pub const SHIFT_BLUE: f64 = 0;

pub fn getHexFromRgba(r: f64, g: f64, b: f64, a: f64) f64 {
    std.debug.assert(r >= 0.0 and r <= 1.0 and g >= 0.0 and g <= 1.0 and b >= 0.0 and b <= 1.0 and a >= 0.0 and a <= 1.0);
    const t: u32 = @intFromFloat(HEX_FULL_CHANNEL - std.math.floor(a * HEX_FULL_CHANNEL));
    const v: u32 = ((t << SHIFT_TRANSPARENCY) ^
        (@as(u32, @intFromFloat(r * HEX_FULL_CHANNEL)) << SHIFT_RED) ^
        (@as(u32, @intFromFloat(g * HEX_FULL_CHANNEL)) << SHIFT_GREEN) ^
        (@as(u32, @intFromFloat(b * HEX_FULL_CHANNEL)) << SHIFT_BLUE));
    return @floatFromInt(v);
}

pub fn getHexFromRgb(r: f64, g: f64, b: f64) f64 {
    std.debug.assert(r >= 0.0 and r <= 1.0 and g >= 0.0 and g <= 1.0 and b >= 0.0 and b <= 1.0);
    return ((HEX_FULL_CHANNEL << SHIFT_TRANSPARENCY) ^
        ((r * HEX_FULL_CHANNEL) << SHIFT_RED) ^
        ((g * HEX_FULL_CHANNEL) << SHIFT_GREEN) ^
        ((b * HEX_FULL_CHANNEL) << SHIFT_BLUE));
}

pub fn getHexFromHsl(h: f64, s: f64, l: f64) f64 {
    std.debug.assert(h >= 0.0 and h <= 1.0 and s >= 0.0 and s <= 1.0 and l >= 0.0 and l <= 1.0);
    var r: f64 = 0;
    var g: f64 = 0;
    var b: f64 = 0;
    if (s == 0) {
        r = l;
        g = l;
        b = l;
    } else {
        const q: f64 = if (l < 0.5) l * (1 + s) else l + s - l * s;
        const p: f64 = 2 * l - q;
        r = hueToRgb(p, q, h + 1 / 3.0);
        g = hueToRgb(p, q, h);
        b = hueToRgb(p, q, h - 1 / 3.0);
    }
    return getHexFromRgb(r, g, b);
}
fn hueToRgb(p: f64, q: f64, t: f64) f64 {
    if (t < 0) t += 1;
    if (t > 1) t -= 1;
    if (t < 1 / 6.0) return p + (q - p) * 6 * t;
    if (t < 1 / 2.0) return q;
    if (t < 2 / 3.0) return p + (q - p) * (2 / 3.0 - t) * 6;
    return p;
}

pub fn getRgbaFromHex(hex: f64) RGBA {
    std.debug.assert((hex & ~HEX_TRGB_MASK) == 0);
    const r: f64 = ((hex >> SHIFT_RED) & HEX_FULL_CHANNEL) / HEX_FULL_CHANNEL;
    const g: f64 = ((hex >> SHIFT_GREEN) & HEX_FULL_CHANNEL) / HEX_FULL_CHANNEL;
    const b: f64 = ((hex >> SHIFT_BLUE) & HEX_FULL_CHANNEL) / HEX_FULL_CHANNEL;
    const a: f64 = (HEX_FULL_CHANNEL - ((hex >> SHIFT_TRANSPARENCY) & HEX_FULL_CHANNEL)) / HEX_FULL_CHANNEL;
    return RGBA.new(r, g, b, a);
}

pub fn hasAlphaInHex(hex: f64) bool {
    std.debug.assert((hex & ~HEX_TRGB_MASK) == 0);
    return (hex >> SHIFT_TRANSPARENCY) != 0;
}
pub fn getAlphaFromHex(hex: f64) f64 {
    std.debug.assert((hex & ~HEX_TRGB_MASK) == 0);
    return (HEX_FULL_CHANNEL - (hex >> SHIFT_TRANSPARENCY)) / HEX_FULL_CHANNEL;
}
pub fn removeAlphaFromHex(hex: f64) f64 {
    std.debug.assert((hex & ~HEX_TRGB_MASK) == 0);
    return hex & HEX_RGB_MASK;
}

pub fn main() !void {
    // const hex = getHexFromRgba(0.0, 0.0, 0.0, 0.0);
    // std.debug.print("{}\n", .{hex});
    const x: f64 = 4278190080;
    std.debug.print("{}\n", .{@as(u32, @intFromFloat(x))});
    const y: u32 = 4278190080;
    std.debug.print("{}\n", .{@as(f64, @floatFromInt(y))});
}
