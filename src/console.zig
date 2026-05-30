const font = @import("font.zig");
const font8x8 = font.font8x8_basic;
const protocol = @import("std").os.uefi.protocol;
const BltPixel = GraphicsOutput.BltPixel;
const BltOperation = GraphicsOutput.BltOperation;
const GraphicsOutput = protocol.GraphicsOutput;

fn white_blt_pixel() BltPixel {
    return BltPixel{ .red = 0xff, .green = 0xff, .blue = 0xff, .reserved = 0 };
}
fn black_blt_pixel() BltPixel {
    return BltPixel{ .red = 0x00, .green = 0x00, .blue = 0x00, .reserved = 0 };
}

pub fn whiteScreen(gop: *GraphicsOutput) void {
    const width = gop.mode.info.horizontal_resolution;
    const height = gop.mode.info.vertical_resolution;
    var blt_buffer: [1]BltPixel = .{white_blt_pixel()};
    gop.blt(&blt_buffer, .blt_video_fill, 0, 0, 0, 0, width, height, 0) catch {};
}
