const std = @import("std");
const lib = @import("lib");
pub fn main() !void {
    var va = try lib.MapView.new();
    va.something();
}
