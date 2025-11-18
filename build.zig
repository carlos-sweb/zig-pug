const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ========================================================================
    // Module Export - For use as a Zig dependency
    // ========================================================================
    const zigpug_module = b.addModule("zig_pug", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add mujs include path for the module
    zigpug_module.addIncludePath(b.path("vendor/mujs"));

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
    // Cross-compilation targets
    // ========================================================================
    const cross_targets = [_]std.Target.Query{
        // Linux
        .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
        .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .musl },
        // Windows
        .{ .cpu_arch = .x86_64, .os_tag = .windows },
        // macOS
        .{ .cpu_arch = .x86_64, .os_tag = .macos },
        .{ .cpu_arch = .aarch64, .os_tag = .macos },
    };

    const cross_target_names = [_][]const u8{
        "linux-x86_64",
        "linux-aarch64",
        "windows-x86_64",
        "macos-x86_64",
        "macos-aarch64",
    };

    const cross_all_step = b.step("cross-all", "Build for all target platforms");

    for (cross_targets, cross_target_names, 0..) |cross_target, name, i| {
        _ = i;
        const cross_exe = b.addExecutable(.{
            .name = "zig-pug",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/cli.zig"),
                .target = b.resolveTargetQuery(cross_target),
                .optimize = .ReleaseFast,
            }),
        });

        cross_exe.addIncludePath(b.path("vendor/mujs"));
        cross_exe.addObjectFile(b.path("vendor/mujs/libmujs.a"));
        cross_exe.linkLibC();

        const install_artifact = b.addInstallArtifact(cross_exe, .{
            .dest_dir = .{
                .override = .{
                    .custom = b.fmt("bin/{s}", .{name}),
                },
            },
        });

        const cross_step = b.step(
            b.fmt("cross-{s}", .{name}),
            b.fmt("Build for {s}", .{name}),
        );
        cross_step.dependOn(&install_artifact.step);
        cross_all_step.dependOn(&install_artifact.step);
    }

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
