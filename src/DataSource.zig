const DataSource = @This();
ptr: *anyopaque,
vtable: *const struct {
    pub fn getTilingScheme(ctx:*anyopaque) TilingScheme
},
