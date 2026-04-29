const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    // Force ReleaseFast because mujs requires optimization to work correctly
    // Debug and ReleaseSafe builds crash due to mujs internal issues with pointer arithmetic
    const user_optimize = b.standardOptimizeOption(.{});
    const optimize: std.builtin.OptimizeMode = if (user_optimize == .Debug) .ReleaseFast else user_optimize;

    // ========================================================================
    // Module Export - For use as a Zig dependency
    // ========================================================================
    const zigpug_module = b.addModule("zig_pug", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add mujs include path for the module
    zigpug_module.addIncludePath(b.path("vendor/mujs-1.3.9"));

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
                .pic = true, // Position Independent Code for Node.js addons,
                .link_libc = true, // 0.16 version zig
            }),
        });
        // Include mujs
        //lib_static.addIncludePath(b.path("vendor/mujs-1.3.9"));
        lib_static.root_module.addIncludePath(b.path("vendor/mujs-1.3.9"));
        lib_static.root_module.addCSourceFile(.{
            .file = b.path("vendor/mujs-1.3.9/one.c"),
            .flags = &.{ "-std=c99", "-O2", "-DHAVE_STRLCPY=0" },
        });
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
                .link_libc = true, // 0.16 version zig
            }),
        });

        // Compile mujs from source (same as executable)
        lib_shared.root_module.addIncludePath(b.path("vendor/mujs-1.3.9"));
        lib_shared.root_module.addCSourceFile(.{
            .file = b.path("vendor/mujs-1.3.9/one.c"),
            .flags = &.{ "-std=c99", "-O2", "-DHAVE_STRLCPY=0" },
        });
        //lib_shared.linkLibC();

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

    // For native Linux builds, use musl to avoid system libc dependency
    const exe_target = if (target.result.os.tag == .linux)
        b.resolveTargetQuery(.{
            .cpu_arch = target.result.cpu.arch,
            .os_tag = .linux,
            .abi = .musl,
        })
    else
        target;

    const exe = b.addExecutable(.{
        .name = "zpug",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/cli.zig"),
            .target = exe_target,
            .optimize = optimize,
            .link_libc = true, // 0.16 version zig
        }),
    });

    // Compile mujs from source (enables cross-compilation)
    // Note: mujs requires optimization (-O2) to work correctly
    exe.root_module.addIncludePath(b.path("vendor/mujs-1.3.9"));
    exe.root_module.addCSourceFile(.{
        .file = b.path("vendor/mujs-1.3.9/one.c"),
        .flags = &.{ "-std=c99", "-O2", "-DHAVE_STRLCPY=0" },
    });

    // Add c_print library for colored terminal output
    exe.root_module.addIncludePath(b.path("lib/c_print/include"));
    const c_print_flags = &[_][]const u8{ "-std=c99", "-O2", "-D_POSIX_C_SOURCE=200809L" };
    exe.root_module.addCSourceFile(.{ .file = b.path("lib/c_print/src/c_print.c"), .flags = c_print_flags });
    exe.root_module.addCSourceFile(.{ .file = b.path("lib/c_print/src/ansi_codes.c"), .flags = c_print_flags });
    exe.root_module.addCSourceFile(.{ .file = b.path("lib/c_print/src/color_parser.c"), .flags = c_print_flags });
    exe.root_module.addCSourceFile(.{ .file = b.path("lib/c_print/src/pattern_parser.c"), .flags = c_print_flags });
    exe.root_module.addCSourceFile(.{ .file = b.path("lib/c_print/src/number_formatter.c"), .flags = c_print_flags });
    exe.root_module.addCSourceFile(.{ .file = b.path("lib/c_print/src/string_utils.c"), .flags = c_print_flags });
    exe.root_module.addCSourceFile(.{ .file = b.path("lib/c_print/src/text_alignment.c"), .flags = c_print_flags });

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
    // Example
    // ========================================================================
    const example = b.addExecutable(.{
        .name = "example",
        .root_module = b.createModule(.{
            .root_source_file = b.path("example.zig"),
            .target = exe_target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    example.root_module.addIncludePath(b.path("vendor/mujs-1.3.9"));
    example.root_module.addCSourceFile(.{
        .file = b.path("vendor/mujs-1.3.9/one.c"),
        .flags = &.{ "-std=c99", "-O2", "-DHAVE_STRLCPY=0" },
    });

    const run_example_cmd = b.addRunArtifact(example);
    run_example_cmd.step.dependOn(b.getInstallStep());
    const run_example_step = b.step("example", "Run the example");
    run_example_step.dependOn(&run_example_cmd.step);

    // ========================================================================
    // Example: ScanNumber inspection
    // Usage: zig build exampleScanNumber
    // No mujs needed — tokenizer only
    // ========================================================================
    const example_scan_number = b.addExecutable(.{
        .name = "exampleScanNumber",
        .root_module = b.createModule(.{
            .root_source_file = b.path("exampleScanNumber.zig"),
            .target = exe_target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    const run_scan_number_cmd = b.addRunArtifact(example_scan_number);
    run_scan_number_cmd.step.dependOn(b.getInstallStep());
    const run_scan_number_step = b.step("exampleScanNumber", "Inspect scanNumber token output");
    run_scan_number_step.dependOn(&run_scan_number_cmd.step);

    // ========================================================================
    // Global Installation
    // Usage: sudo zig build -p /usr/local install
    // Or on Windows: zig build -p "C:\Program Files\zig-pug" install
    // ========================================================================

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
            .name = "zpug",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/cli.zig"),
                .target = b.resolveTargetQuery(cross_target),
                .optimize = .ReleaseFast,
                .link_libc = true, // 0.16 version zig
            }),
        });

        // Compile mujs from source for cross-compilation
        cross_exe.root_module.addIncludePath(b.path("vendor/mujs-1.3.9"));
        cross_exe.root_module.addCSourceFile(.{
            .file = b.path("vendor/mujs-1.3.9/one.c"),
            .flags = &.{ "-std=c99", "-O2", "-DHAVE_STRLCPY=0" },
        });

        // Add c_print library for colored terminal output
        cross_exe.root_module.addIncludePath(b.path("lib/c_print/include"));
        const cross_c_print_flags = &[_][]const u8{ "-std=c99", "-O2", "-D_POSIX_C_SOURCE=200809L" };
        cross_exe.root_module.addCSourceFile(.{ .file = b.path("lib/c_print/src/c_print.c"), .flags = cross_c_print_flags });
        cross_exe.root_module.addCSourceFile(.{ .file = b.path("lib/c_print/src/ansi_codes.c"), .flags = cross_c_print_flags });
        cross_exe.root_module.addCSourceFile(.{ .file = b.path("lib/c_print/src/color_parser.c"), .flags = cross_c_print_flags });
        cross_exe.root_module.addCSourceFile(.{ .file = b.path("lib/c_print/src/pattern_parser.c"), .flags = cross_c_print_flags });
        cross_exe.root_module.addCSourceFile(.{ .file = b.path("lib/c_print/src/number_formatter.c"), .flags = cross_c_print_flags });
        cross_exe.root_module.addCSourceFile(.{ .file = b.path("lib/c_print/src/string_utils.c"), .flags = cross_c_print_flags });
        cross_exe.root_module.addCSourceFile(.{ .file = b.path("lib/c_print/src/text_alignment.c"), .flags = cross_c_print_flags });

        //cross_exe.linkLibC();

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
            .root_source_file = b.path("src/lib.zig"),
            .target = exe_target,
            .optimize = optimize,
            .link_libc = true, // 0.16 version zig
        }),
    });

    // Compile mujs from source for tests
    tests.root_module.addIncludePath(b.path("vendor/mujs-1.3.9"));
    tests.root_module.addCSourceFile(.{
        .file = b.path("vendor/mujs-1.3.9/one.c"),
        .flags = &.{ "-std=c99", "-O2", "-DHAVE_STRLCPY=0" },
    });
    //tests.linkLibC();

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}
