const uefi = @import("std").os.uefi;
const std = @import("std");
const L = std.unicode.utf8ToUtf16LeStringLiteral;
const console = @import("console.zig");
pub fn printLn(comptime fmt: []const u8) void {
    const con_out = uefi.system_table.con_out.?;
    _ = con_out.outputString(L(fmt) ++ L("\r\n")) catch {};
}

const Resolution = struct {
    width: u32,
    height: u32,
};

pub fn u32ToUtf16(num: u32) [16:0]u16 {
    var buf8: [16]u8 = undefined;
    var buf16: [16:0]u16 = std.mem.zeroes([16:0]u16);
    const s = std.fmt.bufPrint(&buf8, "{d}", .{num}) catch unreachable;
    for (s, 0..) |c, i| {
        buf16[i] = c;
    }
    buf16[s.len] = 0;
    return buf16;
}

pub fn findBiggestMode(gop: *uefi.protocol.GraphicsOutput) ?u32 {
    var biggest_mode: u32 = 0;
    var biggest_area: u32 = 0;
    for (0..gop.mode.max_mode) |i| {
        const idx: u32 = @intCast(i);
        const mode_info = gop.queryMode(idx) catch continue;
        const area = mode_info.horizontal_resolution * mode_info.vertical_resolution;
        if (area > biggest_area) {
            biggest_mode = idx;
            biggest_area = area;
        }
    }
    if (biggest_area == 0) return null;
    return biggest_mode;
}

pub fn findResolution(resolution: Resolution, gop: *uefi.protocol.GraphicsOutput) ?u32 {
    for (0..gop.mode.max_mode) |i| {
        const idx: u32 = @intCast(i);
        const mode_info = gop.queryMode(idx) catch continue;
        if (mode_info.horizontal_resolution == resolution.width and mode_info.vertical_resolution == resolution.height) {
            return idx;
        }
    }
    return null;
}

pub fn main() void {
    const con_out = uefi.system_table.con_out.?;
    _ = con_out.reset(false) catch {};
    const boot_services = uefi.system_table.boot_services.?;

    // GOP

    const gop = (boot_services.locateProtocol(uefi.protocol.GraphicsOutput, null) catch {
        printLn("Failed to locate GOP protocol");
        return;
    }).?;

    _ = gop.setMode(findResolution(.{ .width = 1920, .height = 1080 }, gop).?) catch {
        printLn("Failed to set mode");
        return;
    };

    printLn("Hello, Kaos!");
    printLn("GOP");
    printLn("Mode info:");
    const horinzontal = u32ToUtf16(gop.mode.info.horizontal_resolution);
    const vertical = u32ToUtf16(gop.mode.info.vertical_resolution);
    _ = con_out.outputString(&horinzontal) catch {};
    printLn("");
    _ = con_out.outputString(&vertical) catch {};
    printLn("");
    console.whiteScreen(gop);

    while (true) {}
}
