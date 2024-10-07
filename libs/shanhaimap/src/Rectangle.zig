const math = @import("math");
const Cartographic = @import("./Cartographic.zig").Cartographic;
const MAX_LONGITUDE = @import("./Cartographic.zig").MAX_LONGITUDE;
const RectangleCorner = @import("RectangleCorner.zig").RectangleCorner;
pub const Rectangle = struct {
    west: f64,
    south: f64,
    east: f64,
    north: f64,
    const Self = @This();

    pub const MAX_VALUE = new(-math.pi, -math.pi_over_two, math.pi, math.pi_over_two);

    pub fn new(westv: f64, southv: f64, eastv: f64, northv: f64) Self {
        return .{
            .west = westv,
            .south = southv,
            .east = eastv,
            .north = northv,
        };
    }
    pub fn computeWidth(self: *const Self) f64 {
        var e = self.east;
        const w = self.west;
        if (e < w) {
            e += math.tau;
        }
        return e - w;
    }
    pub inline fn computeHeight(self: *const Self) f64 {
        return self.north - self.south;
    }
    pub fn fromDegrees(w: f64, s: f64, e: f64, n: f64) Self {
        return new(
            math.degreesToRadians(w),
            math.degreesToRadians(s),
            math.degreesToRadians(e),
            math.degreesToRadians(n),
        );
    }
    pub fn fromRadians(w: f64, s: f64, e: f64, n: f64) Self {
        return new(w, s, e, n);
    }
    pub inline fn southWest(self: *const Self) Cartographic {
        return Cartographic.new(self.west, self.south, 0);
    }
    pub inline fn southEast(self: *const Self) Cartographic {
        return Cartographic.new(self.east, self.south, 0);
    }
    pub inline fn northWest(self: *const Self) Cartographic {
        return Cartographic.new(self.west, self.north, 0);
    }
    pub inline fn northEast(self: *const Self) Cartographic {
        return Cartographic.new(self.east, self.north, 0);
    }
    pub fn corners(self: *const Self) RectangleCorner {
        return RectangleCorner.fromRectangle(self);
    }
    pub fn center(self: *const Self) Cartographic {
        var e = self.east;
        const w = self.west;
        if (e < w) {
            e += math.tau;
        }
        const lon = math.negativePiToPi((w + e) * 0.5);
        const lat = (self.north + self.south) * 0.5;
        return Cartographic.new(lon, lat, 0);
    }
    pub fn clone(self: *const Self) Self {
        return .{
            .west = self.west,
            .south = self.south,
            .east = self.east,
            .north = self.north,
        };
    }
    pub fn contains(self: *const Self, p: Cartographic) bool {
        var longitude = p.lon;
        const latitude = p.lat;

        const west = self.west;
        var east = self.east;

        if (east < west) {
            east += math.tau;
            if (longitude < 0.0) {
                longitude += math.tau;
            }
        }
        return ((longitude > west or
            math.eql(f64, longitude, west, math.EPSILON14)) and
            (longitude < east or
            math.eql(f64, longitude, east, math.EPSILON14)) and
            latitude >= self.south and
            latitude <= self.north);
    }
    pub fn intersection(self: *const Self, other: *const Self) ?Self {
        var rectangleEast = self.east;
        var rectangleWest = self.west;

        var otherRectangleEast = other.east;
        var otherRectangleWest = other.west;

        if (rectangleEast < rectangleWest and otherRectangleEast > 0.0) {
            rectangleEast += math.tau;
        } else if (otherRectangleEast < otherRectangleWest and rectangleEast > 0.0) {
            otherRectangleEast += math.tau;
        }

        if (rectangleEast < rectangleWest and otherRectangleWest < 0.0) {
            otherRectangleWest += math.tau;
        } else if (otherRectangleEast < otherRectangleWest and rectangleWest < 0.0) {
            rectangleWest += math.tau;
        }

        const west = math.negativePiToPi(@max(rectangleWest, otherRectangleWest));
        const east = math.negativePiToPi(@min(rectangleEast, otherRectangleEast));

        if ((self.west < self.east or
            other.west < other.east) and
            east <= west)
        {
            return null;
        }

        const south = @max(self.south, other.south);
        const north = @min(self.north, other.north);

        if (south >= north) {
            return null;
        }

        return new(west, south, east, north);
    }
    pub fn simpleIntersection(self: *const Self, other: *const Self) ?Self {
        const west = @max(self.west, other.west);
        const south = @max(self.south, other.south);
        const east = @min(self.east, other.east);
        const north = @min(self.north, other.north);

        if (south >= north or west >= east) {
            return null;
        }
        return new(west, south, east, north);
    }
    pub fn unions(self: *const Self, other: *const Self) Self {
        var rectangleEast = self.east;
        var rectangleWest = self.west;

        var otherRectangleEast = other.east;
        var otherRectangleWest = other.west;

        if (rectangleEast < rectangleWest and otherRectangleEast > 0.0) {
            rectangleEast += math.tau;
        } else if (otherRectangleEast < otherRectangleWest and rectangleEast > 0.0) {
            otherRectangleEast += math.tau;
        }
        if (rectangleEast < rectangleWest and otherRectangleWest < 0.0) {
            otherRectangleWest += math.tau;
        } else if (otherRectangleEast < otherRectangleWest and rectangleWest < 0.0) {
            rectangleWest += math.tau;
        }

        const west = math.negativePiToPi(@min(rectangleWest, otherRectangleWest));
        const east = math.negativePiToPi(@max(rectangleEast, otherRectangleEast));
        return new(west, @min(self.south, other.south), east, @max(self.north, other.north));
    }
    pub fn expand(self: *const Self, other: *const Self) Self {
        const w = @min(self.west, other.west);
        const s = @min(self.south, other.south);
        const e = @max(self.east, other.east);
        const n = @max(self.north, other.north);
        return new(w, s, e, n);
    }
    pub fn subsection(self: *const Self, westLerp: f64, southLerp: f64, eastLerp: f64, northLerp: f64) Self {
        var result: Rectangle = undefined;
        if (self.west <= self.east) {
            const width = self.east - self.west;
            result.west = self.west + westLerp * width;
            result.east = self.west + eastLerp * width;
        } else {
            const width = math.tau + self.east - self.west;
            result.west = math.negativePiToPi(self.west + westLerp * width);
            result.east = math.negativePiToPi(self.west + eastLerp * width);
        }
        const height = self.north - self.south;
        result.south = self.south + southLerp * height;
        result.north = self.south + northLerp * height;

        // Fix floating point precision problems when t = 1
        if (westLerp == 1.0) {
            result.west = self.east;
        }
        if (eastLerp == 1.0) {
            result.east = self.east;
        }
        if (southLerp == 1.0) {
            result.south = self.north;
        }
        if (northLerp == 1.0) {
            result.north = self.north;
        }
        return result;
    }
};
