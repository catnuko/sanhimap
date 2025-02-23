const std = @import("std");
const json = std.json;
const testing = std.testing;
const JsonValue = struct {
    pub const @"null" = 0;
    pub const @"bool" = 1;
    pub const integer = 2;
    pub const float = 3;
    pub const number_string = 4;
    pub const string = 5;
    pub const array = 6;
    pub const object = 7;
};
pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const json_string =
        \\{"integer": 42, "float": 3.14, "nested": {"array": [1, 2, 3]}}
    ;
    const parsed = try std.json.parseFromSlice(json.Value, allocator, json_string, .{});
    defer parsed.deinit();

    const value = parsed.value;
    std.debug.print("{s}\n", .{@tagName(value)});
    std.debug.print("{}\n", .{@intFromEnum(value) == JsonValue.object});
}
