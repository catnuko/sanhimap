const math = @import("../math.zig");
pub fn intersectLines(x1: f64, y1: f64, x2: f64, y2: f64, x3: f64, y3: f64, x4: f64, y4: f64) ?math.Vector2 {
    const d = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
    if (d == 0) {
        return null;
    }
    const px = ((x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)) / d;
    const py = ((x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)) / d;
    return math.Vector2.new(px, py);
}
pub const IntersectLineAndCircleResult = union(enum) {
    point: math.Vector2,
    line: [2]math.Vector2,
};
pub fn intersectLineAndCircle(xLine1: f64, yLine1: f64, xLine2: f64, yLine2: f64, radius: f64, xCenter: f64, yCenter: f64) ?IntersectLineAndCircleResult {
    // Line equation: dy*x - dx*y = c, c = dy*x1 - dx*y1 = x1*y2 - x2*y1
    // Circle equation: (x-xCenter)^2 + (y-yCenter)^2 = r^2

    // 1. Translate circle center to origin of coordinates:
    // u = x - xCenter
    // v = y - yCenter
    // circle: u^2 + v^2 = r^2
    // line: dy*u - dx*v = cp, cp = c - dy*xCenter - dx*yCenter

    // 2. Intersections are solutions of a quadratic equation:
    // ui = (cp*dy +/- sign(dy)*dx*discriminant / dSq
    // vi = (-cp*dx +/- |dy|*discriminant / dSq
    // discriminant = r^2*dSq - cp^2, dSq = dx^2 + dy^2
    // The sign of the discriminant indicates the number of intersections.

    // 3. Translate intersection coordinates back to original space:
    // xi = xCenter + ui
    // yi = yCenter + yi

    const epsilon: f64 = 1e-10;
    const dx = xLine2 - xLine1;
    const dy = yLine2 - yLine1;
    const dSq = dx * dx + dy * dy;
    const rSq = radius * radius;
    const c = xLine1 * yLine2 - xLine2 * yLine1;
    const cp = c - dy * xCenter + dx * yCenter;
    const discriminantSquared = rSq * dSq - cp * cp;

    if (discriminantSquared < -epsilon) {
        // no intersection
        return null;
    }

    const xMid = cp * dy;
    const yMid = -cp * dx;

    if (discriminantSquared < epsilon) {
        return IntersectLineAndCircleResult{ .point = math.Vector2.new(xCenter + xMid / dSq, yCenter + yMid / dSq) };
    }

    const discriminant = math.sqrt(discriminantSquared);

    // 2 intersections (secant line)
    const signDy = if (dy < 0) -1 else 1;
    const absDy = math.abs(dy);

    const xDist = signDy * dx * discriminant;
    const yDist = absDy * discriminant;

    return .{ .line = [2]math.Vector2{
        math.Vector2.new(xCenter + (xMid + xDist) / dSq, yCenter + (yMid + yDist) / dSq),
        math.Vector2.new(xCenter + (xMid - xDist) / dSq, yCenter + (yMid - yDist) / dSq),
    } };
}
pub fn distSquared(ax: f64, ay: f64, bx: f64, by: f64) f64 {
    return (ax - bx) * (ax - bx) + (ay - by) * (ay - by);
}
pub fn computeSquaredLineLength(line: []f64) f64 {
    var squaredLineLength: f64 = 0;
    const length = line.length - 4;
    var i: usize = 0;
    while (i < length) : (i += 3) {
        const xDiff = line[i + 3] - line[i];
        const yDiff = line[i + 4] - line[i + 1];
        squaredLineLength += xDiff * xDiff + yDiff * yDiff;
    }
    return squaredLineLength;
}
pub fn distToSegmentSquared(px: f64, py: f64, l0x: f64, l0y: f64, l1x: f64, l1y: f64) f64 {
    const lineLengthSuared = distSquared(l0x, l0y, l1x, l1y);
    if (lineLengthSuared == 0) {
        return distSquared(px, py, l0x, l0y);
    }
    var t = ((px - l0x) * (l1x - l0x) + (py - l0y) * (l1y - l0y)) / lineLengthSuared;
    t = @max(0, @min(1, t));
    return distSquared(px, py, l0x + t * (l1x - l0x), l0y + t * (l1y - l0y));
}
