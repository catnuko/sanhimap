const zgui = @import("zgui");
const zgpu = @import("zgpu");
pub fn drawFPS(gctx: *zgpu.GraphicsContext) void {
    const draw_list = zgui.getBackgroundDrawList();
    draw_list.addText(
        .{ 10, 10 },
        0xff_ff_ff_ff,
        "{d:.3} ms/frame ({d:.1} fps)",
        .{ gctx.stats.average_cpu_time, gctx.stats.fps },
    );
}
