const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "BOOTX64",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = b.resolveTargetQuery(.{
                .cpu_arch = .x86_64,
                .os_tag = .uefi,
            }),
            .optimize = optimize,
        }),
    });

    const install = b.addInstallArtifact(exe, .{
        .dest_dir = .{ .override = .{ .custom = "EFI/BOOT" } },
    });
    b.getInstallStep().dependOn(&install.step);

    // zig build disk
    const disk = "zig-out/disk/disk.img";

    const mkdir = b.addSystemCommand(&.{ "mkdir", "-p", "zig-out/disk" });
    mkdir.step.dependOn(&install.step);

    const dd = b.addSystemCommand(&.{ "dd", "if=/dev/zero", b.fmt("of={s}", .{disk}), "bs=512", "count=93750" });
    dd.step.dependOn(&mkdir.step);

    const mformat = b.addSystemCommand(&.{ "mformat", "-i", disk, "-F", "::" });
    mformat.step.dependOn(&dd.step);

    const mmd_efi = b.addSystemCommand(&.{ "mmd", "-i", disk, "::/EFI" });
    mmd_efi.step.dependOn(&mformat.step);

    const mmd_boot = b.addSystemCommand(&.{ "mmd", "-i", disk, "::/EFI/BOOT" });
    mmd_boot.step.dependOn(&mmd_efi.step);

    const mcopy = b.addSystemCommand(&.{ "mcopy", "-i", disk });
    mcopy.addFileArg(exe.getEmittedBin());
    mcopy.addArg("::/EFI/BOOT/BOOTX64.EFI");
    mcopy.step.dependOn(&mmd_boot.step);

    const disk_step = b.step("disk", "Create zig-out/disk/disk.img");
    disk_step.dependOn(&mcopy.step);

    // zig build run
    const qemu = b.addSystemCommand(&.{
        "qemu-system-x86_64",
        "-drive",
        "if=pflash,format=raw,readonly=on,file=OVMF/OVMF_CODE.4m.fd",
        "-drive",
        "if=pflash,format=raw,file=OVMF/OVMF_VARS.4m.fd",
        "-drive",
        "format=vvfat,dir=zig-out,rw=on",
        "-net",
        "none",
        "-display",
        "gtk",
    });
    qemu.step.dependOn(&install.step);

    const run_step = b.step("run", "Emulate in QEMU");
    run_step.dependOn(&qemu.step);
}
