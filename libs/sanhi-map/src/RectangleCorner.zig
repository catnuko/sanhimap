const Rectangle = @import("./Rectangle.zig").Rectangle;
const Cartographic = @import("Cartographic.zig").Cartographic;
pub const RectangleCorner = struct {
    southWest: Cartographic,
    southEast: Cartographic,
    northWest: Cartographic,
    northEast: Cartographic,

    const Self = @This();

    pub fn new(
        southWest: Cartographic,
        southEast: Cartographic,
        northWest: Cartographic,
        northEast: Cartographic,
    ) Self {
        return .{
            .southWest = southWest,
            .southEast = southEast,
            .northWest = northWest,
            .northEast = northEast,
        };
    }

    pub fn fromRectangle(rectangle: *const Rectangle) RectangleCorner {
        return new(
            rectangle.southWest(),
            rectangle.southEast(),
            rectangle.northWest(),
            rectangle.northEast(),
        );
    }
};
