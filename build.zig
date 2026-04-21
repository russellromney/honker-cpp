const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const honker_mod = b.createModule(.{
        .root_source_file = b.path("src/honker.zig"),
        .target = target,
        .optimize = optimize,
    });
    const is_darwin = target.result.os.tag == .macos;
    if (is_darwin) {
        honker_mod.addIncludePath(.{ .cwd_relative = "/opt/homebrew/opt/sqlite3/include" });
        honker_mod.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/opt/sqlite3/lib" });
    }
    honker_mod.linkSystemLibrary("sqlite3", .{});
    honker_mod.link_libc = true;

    const lib = b.addLibrary(.{
        .name = "honker_cpp",
        .root_module = honker_mod,
        .linkage = .static,
    });
    b.installArtifact(lib);

    const ext_opt = b.option([]const u8, "honker-ext", "Path to libhonker_ext.{dylib,so}");

    const test_step = b.step("test", "Run the C++ test suite");

    const test_files = .{
        "test/test_basic.cpp",
        "test/test_parity.cpp",
    };

    inline for (test_files) |tf| {
        const mod = b.createModule(.{
            .target = target,
            .optimize = optimize,
        });
        mod.addCSourceFile(.{
            .file = b.path(tf),
            .flags = &.{"-std=c++17", "-Wall", "-Wextra"},
        });
        mod.addIncludePath(b.path("include"));
        if (is_darwin) {
            mod.addIncludePath(.{ .cwd_relative = "/opt/homebrew/opt/sqlite3/include" });
            mod.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/opt/sqlite3/lib" });
        }
        mod.link_libc = true;
        mod.link_libcpp = true;
        mod.linkSystemLibrary("sqlite3", .{});
        mod.linkLibrary(lib);

        const exe = b.addExecutable(.{
            .name = std.fs.path.stem(tf),
            .root_module = mod,
        });
        b.installArtifact(exe);

        const run = b.addRunArtifact(exe);
        if (ext_opt) |ext| {
            run.setEnvironmentVariable("HONKER_EXTENSION_PATH", ext);
        }

        test_step.dependOn(&run.step);
    }
}
