const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ========================================================================
    // Static Library (.a) - Optional, requires libc
    // Note: Won't build in Termux/Android due to libc requirement
    // ========================================================================
    const lib_static_step = b.step("lib-static", "Build static library (.a) - requires libc");
    {
        const lib_static = b.addLibrary(.{
            .name = "zig-pug",
            .linkage = .static,
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/lib.zig"),
                .target = target,
                .optimize = optimize,
            }),
        });
        lib_static.linkLibC();
        const install_lib_static = b.addInstallArtifact(lib_static, .{});
        lib_static_step.dependOn(&install_lib_static.step);
    }

    // ========================================================================
    // Shared Library (.so / .dll / .dylib) - Optional, requires libc
    // Note: Won't build in Termux/Android due to libc requirement
    // ========================================================================
    const lib_shared_step = b.step("lib-shared", "Build shared library (.so/.dll/.dylib) - requires libc");
    {
        const lib_shared = b.addLibrary(.{
            .name = "zig-pug",
            .linkage = .dynamic,
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/lib.zig"),
                .target = target,
                .optimize = optimize,
            }),
        });
        lib_shared.linkLibC();
        const install_lib_shared = b.addInstallArtifact(lib_shared, .{});
        lib_shared_step.dependOn(&install_lib_shared.step);
    }

    // ========================================================================
    // Build all libraries at once - Optional, requires libc
    // ========================================================================
    const lib_all_step = b.step("lib", "Build both static and shared libraries - requires libc");
    lib_all_step.dependOn(lib_static_step);
    lib_all_step.dependOn(lib_shared_step);

    // ========================================================================
    // Executable (CLI tool)
    // ========================================================================
    const exe = b.addExecutable(.{
        .name = "zig-pug",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Link with mujs
    exe.addIncludePath(b.path("vendor/mujs"));
    exe.addObjectFile(b.path("vendor/mujs/libmujs.a"));
    // Note: libm (math library) is needed but we can't use linkSystemLibrary in Termux
    // mujs was compiled with -lm, so the symbols should be available

    b.installArtifact(exe);

    // Run command
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the CLI app");
    run_step.dependOn(&run_cmd.step);

    // ========================================================================
    // Tests
    // ========================================================================
    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Link with mujs for tests
    tests.addIncludePath(b.path("vendor/mujs"));
    tests.addObjectFile(b.path("vendor/mujs/libmujs.a"));

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}
