const uefi = @import("std").os.uefi;
const std = @import("std");
const L = std.unicode.utf8ToUtf16LeStringLiteral;
pub fn main() void {
    const con_out = uefi.system_table.con_out.?;
    _ = con_out.reset(false) catch {};
    _ = con_out.outputString(L("Hello, Kaos!")) catch {};
    _ = uefi.system_table.boot_services.?;
    while (true) {}
}
