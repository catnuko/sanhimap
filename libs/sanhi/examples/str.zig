const std = @import("std");

// 编译时字符串模板替换函数
fn comptimeTemplate(comptime template: []const u8, context: anytype) []const u8 {
    comptime {
        const ContextType = @TypeOf(context);
        const type_info = @typeInfo(ContextType);
        if (type_info != .@"struct") {
            @compileError("Context must be a struct or tuple");
        }

        var result: []const u8 = "";
        var index: usize = 0;
        const len = template.len;

        while (index < len) {
            // 查找下一个 ${
            if (index + 1 < len and template[index] == '$' and template[index + 1] == '{') {
                const var_start = index + 2; // 跳过 ${
                index += 2;

                // 查找闭合的 }
                var var_end = var_start;
                while (var_end < len and template[var_end] != '}') : (var_end += 1) {}
                if (var_end >= len) {
                    @compileError("Unclosed ${ in template");
                }

                // 提取变量名
                const var_name = template[var_start..var_end];
                index = var_end + 1; // 跳过 }

                // 在上下文中查找变量
                const value = blk: {
                    for (std.meta.fields(ContextType)) |field| {
                        if (std.mem.eql(u8, field.name, var_name)) {
                            break :blk @field(context, field.name);
                        }
                    }
                    @compileError("Variable '" ++ var_name ++ "' not found in context");
                };

                // 将值转换为字符串并拼接
                result = result ++ convertToString(value);
            } else {
                // 处理普通文本
                const next_special = std.mem.indexOfScalarPos(u8, template, index, '$') orelse len;
                result = result ++ template[index..next_special];
                index = next_special;
            }
        }

        return result;
    }
}

// 将各种类型转换为编译时字符串
fn convertToString(value: anytype) []const u8 {
    return switch (@typeInfo(@TypeOf(value))) {
        .comptime_int => std.fmt.comptimePrint("{}", .{value}),
        .comptime_float => std.fmt.comptimePrint("{}", .{value}),
        .bool => if (value) "true" else "false",
        .pointer => value, // 假设是字符串
        else => @compileError("Unsupported value type"),
    };
}

// 示例使用
pub fn main() !void {
    const name = "bob";
    const age = 25;
    const active = true;

    // 使用模板替换（编译时执行）
    const message = comptime comptimeTemplate("Hello, ${name}! Age: ${age}, Active: ${active}", .{ .name = name, .age = age, .active = active });

    std.debug.print("{s}\n", .{message});
}
