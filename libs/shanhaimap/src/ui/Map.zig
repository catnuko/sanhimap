pub fn Map(comptime Projection: type) type {
    return struct {
        projection: Projection,
    };
}
