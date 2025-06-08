const std = @import("std");
const zstbi = @import("zstbi");
const mem = @import("mem.zig");

var allocator: std.mem.Allocator = undefined;

pub const Image = zstbi.Image;

pub fn init() !void {
    allocator = mem.getAllocator();
    std.debug.print("Image zstbi init", .{});
    zstbi.init(allocator);
}

pub fn deinit() void {
    std.debug.print("Image zstbi deinit", .{});
    zstbi.deinit();
}

pub fn loadFile(file_path: [:0]const u8) !Image {
    std.debug.print("Loading image from file: {s}", .{file_path});
    defer std.debug.print("Done loading image from file: {s}", .{file_path});

    // const file = try std.fs.cwd().openFile(
    //     file_path,
    //     .{}, // mode is read only by default
    // );
    // defer file.close();
    //
    // const file_stat = try file.stat();
    // const file_size: usize = @as(usize, @intCast(file_stat.size));
    //
    // const contents = try file.reader().readAllAlloc(allocator, file_size);
    // defer allocator.free(contents);
    //
    // std.debug.print("Read {d} bytes", .{file_size});
    //
    // return loadBytes(contents);

    return Image.loadFromFile(file_path, 0);
}

pub fn loadBytes(image_bytes: []const u8) !Image {
    std.debug.print("Loading image bytes", .{});
    defer std.debug.print("Done loading image bytes", .{});
    return Image.loadFromMemory(image_bytes, 0);
}
