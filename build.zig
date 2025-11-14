const std = @import("std");

pub fn build(b: *std.Build) void {
    // Use system libc (Android Bionic in Termux)
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Ejecutable principal
    const exe = b.addExecutable(.{
        .name = "zig-pug",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Note: QuickJS integration disabled in Termux/Android environment
    // The pre-compiled libquickjs.a exists but Zig has issues with Android Bionic libc
    // Uncomment these lines when running on standard Linux/Mac:
    //
    // exe.linkSystemLibrary("c");
    // exe.addIncludePath(b.path("vendor/quickjs"));
    // exe.addObjectFile(b.path("vendor/quickjs/libquickjs.a"));
    // exe.linkSystemLibrary("m");   // math library
    // exe.linkSystemLibrary("dl");  // dynamic loader
    // exe.linkSystemLibrary("pthread"); // threads

    b.installArtifact(exe);

    // Run command
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Tests
    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // QuickJS integration disabled for tests too (same Termux/Android issue)

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}
