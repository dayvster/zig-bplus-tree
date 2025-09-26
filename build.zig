const std = @import("std");

// Although this function looks imperative, it does not perform the build
// directly and instead it mutates the build graph (`b`) that will be then
// executed by an external runner. The functions in `std.Build` implement a DSL
// for defining build steps and express dependencies between them, allowing the
// build runner to parallelize the build automatically (and the cache system to
// know when a step doesn't need to be re-run).
pub fn build(b: *std.Build) void {
    // Standard target and optimize options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    // Main library module
    const mod = b.addModule("bplustree", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    // Example: basic_usage
    const ex_basic_usage = b.addExecutable(.{
        .name = "basic_usage",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/basic_usage.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "bplustree", .module = mod }},
        }),
    });
    b.installArtifact(ex_basic_usage);
    const run_step_basic = b.step("run-example-basic_usage", "Run example basic_usage");
    const run_cmd_basic = b.addRunArtifact(ex_basic_usage);
    run_step_basic.dependOn(&run_cmd_basic.step);
    run_cmd_basic.step.dependOn(b.getInstallStep());

    // Example: iteration
    const ex_iteration = b.addExecutable(.{
        .name = "iteration",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/iteration.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "bplustree", .module = mod }},
        }),
    });
    b.installArtifact(ex_iteration);
    // Example: self_balancing
    const ex_self_balancing = b.addExecutable(.{
        .name = "self_balancing",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/self_balancing.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "bplustree", .module = mod }},
        }),
    });
    b.installArtifact(ex_self_balancing);
    const run_step_self = b.step("run-example-self_balancing", "Run example self_balancing");
    const run_cmd_self = b.addRunArtifact(ex_self_balancing);
    run_step_self.dependOn(&run_cmd_self.step);
    run_cmd_self.step.dependOn(b.getInstallStep());
    const run_step_iter = b.step("run-example-iteration", "Run example iteration");
    const run_cmd_iter = b.addRunArtifact(ex_iteration);
    run_step_iter.dependOn(&run_cmd_iter.step);
    run_cmd_iter.step.dependOn(b.getInstallStep());

    // Test steps
    const mod_tests = b.addTest(.{ .root_module = mod });
    const run_mod_tests = b.addRunArtifact(mod_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);

    // Add all test files in tests/ directory after test_step is defined
    const test_files = &[_][]const u8{
        "tests/bplustree_test.zig",
        "tests/bplustree_edge_cases.zig",
    };
    for (test_files) |test_file| {
        const t = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path(test_file),
                .target = target,
                .optimize = optimize,
                .imports = &.{.{ .name = "bplustree", .module = mod }},
            }),
        });
        const run_t = b.addRunArtifact(t);
        test_step.dependOn(&run_t.step);
    }
    // Standard target options allow the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    // It's also possible to define more custom flags to toggle optional features
    // of this build script using `b.option()`. All defined flags (including
    // target and optimize options) will be listed when running `zig build --help`
    // in this directory.

    // This creates a module, which represents a collection of source files alongside
    // some compilation options, such as optimization mode and linked system libraries.
    // Zig modules are the preferred way of making Zig code available to consumers.
    // addModule defines a module that we intend to make available for importing
    // to our consumers. We must give it a name because a Zig package can expose
    // multiple modules and consumers will need to be able to specify which
    // module they want to access.

    // Here we define an executable. An executable needs to have a root module
    // which needs to expose a `main` function. While we could add a main function
    // to the module defined above, it's sometimes preferable to split business
    // business logic and the CLI into two separate modules.
    //
    // If your goal is to create a Zig library for others to use, consider if
    // it might benefit from also exposing a CLI tool. A parser library for a
    // data serialization format could also bundle a CLI syntax checker, for example.
    //
    // If instead your goal is to create an executable, consider if users might
    // be interested in also being able to embed the core functionality of your
    // program in their own executable in order to avoid the overhead involved in
    // subprocessing your CLI tool.
    //
    // If neither case applies to you, feel free to delete the declaration you
    // don't need and to put everything under a single module.

    // Removed references to 'exe', 'run_step', and 'run_cmd' as they are not defined.

    // Creates an executable that will run `test` blocks from the provided module.
    // Here `mod` needs to define a target, which is why earlier we made sure to
    // set the releative field.
    // Creates an executable that will run `test` blocks from the executable's
    // root module. Note that test executables only test one module at a time,
    // hence why we have to create two separate ones.
    // const exe_tests = b.addTest(.{
    //     .root_module = exe.root_module,
    // });

    // A run step that will run the second test executable.

    // A top level step for running all tests. dependOn can be called multiple
    // times and since the two run steps do not depend on one another, this will
    // make the two of them run in parallel.

    // Just like flags, top level steps are also listed in the `--help` menu.
    //
    // The Zig build system is entirely implemented in userland, which means
    // that it cannot hook into private compiler APIs. All compilation work
    // orchestrated by the build system will result in other Zig compiler
    // subcommands being invoked with the right flags defined. You can observe
    // these invocations when one fails (or you pass a flag to increase
    // verbosity) to validate assumptions and diagnose problems.
    //
    // Lastly, the Zig build system is relatively simple and self-contained,
    // and reading its source code will allow you to master it.
}
