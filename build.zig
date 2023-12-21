const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "aq",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .target = target,
        .optimize = optimize,
    });
    exe.addCSourceFiles(&.{
        "src/main.c",
        "src/app.c",
        "src/common.c",
        "src/fex.c",
        "src/midi.c",
        "src/renderer.c",
        "src/ui.c",
        "src/api/core.c",
        "src/api/dsp.c",
        "src/api/ui.c",
        "src/dsp/dsp.c",
        "src/dsp/node.c",
        "src/dsp/nodes/dac.c",
        "src/dsp/nodes/delay.c",
        "src/dsp/nodes/line.c",
        "src/dsp/nodes/math.c",
        "src/dsp/nodes/osc.c",
        "src/dsp/nodes/reverb.c",
        "src/dsp/nodes/shaper.c",
        "src/dsp/nodes/svf.c",
        "src/lib/fe/fe.c",
        "src/lib/microui/microui.c",
        "src/lib/freeverb/freeverb.c",
    }, &.{
        // AFAIU mu_push_command has issues with casting unaligned pointers to mu_Command*
        "-fno-sanitize=undefined",
    });

    exe.addIncludePath(.{ .path = "src" });
    exe.linkSystemLibrary("SDL2");
    switch (@import("builtin").os.tag) {
        .macos => {
            exe.linkFramework("OpenGL");
        },
        else => {
            exe.linkSystemLibrary("gl");
        },
    }

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.cwd = "demo";

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
