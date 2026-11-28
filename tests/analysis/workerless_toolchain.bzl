"""A C# toolchain like the hub's for an exec platform other than the host, which has no csc_worker."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

WORKERLESS = str(Label("//tests/analysis:workerless"))

def _host_toolchain_transition_impl(_settings, _attr):
    return {WORKERLESS: False}

# The wrapped toolchain resolves without this flag, so it gets the hub's toolchain and not itself.
_host_toolchain_transition = transition(
    implementation = _host_toolchain_transition_impl,
    inputs = [],
    outputs = [WORKERLESS],
)

def _workerless_csharp_toolchain_impl(ctx):
    toolchain = ctx.toolchains[Label("//csharp:toolchain_type")]
    info = toolchain.csharp_info
    fields = {k: getattr(info, k) for k in dir(info) if k not in ("to_json", "to_proto")}
    fields["csc_worker"] = None
    info = struct(**fields)
    return [platform_common.ToolchainInfo(csharp_info = info, csharp = info, toolchain_info = info)]

workerless_csharp_toolchain = rule(
    implementation = _workerless_csharp_toolchain_impl,
    cfg = _host_toolchain_transition,
    toolchains = [str(Label("//csharp:toolchain_type"))],
)

def _workerless_package_generator_action_test_impl(ctx):
    env = analysistest.begin(ctx)

    compile_actions = [a for a in analysistest.target_actions(env) if a.mnemonic == "CSharpCompile"]
    asserts.equals(env, 1, len(compile_actions))
    asserts.false(env, "--persistent_worker" in compile_actions[0].argv, "Expected csc.dll without CscWorker, got: %s" % compile_actions[0].argv)

    # Nothing compares versions without CscWorker, so the package copy has to be the only one, like before the pack
    # generators were passed. The pack's 8.0 generator can't handle a primary constructor ILogger.
    logging = [a for a in compile_actions[0].argv if a.startswith("-analyzer:") and a.endswith("/Microsoft.Extensions.Logging.Generators.dll")]
    asserts.true(
        env,
        len(logging) == 1 and "/Microsoft.AspNetCore.App.Ref/" not in logging[0],
        "Expected only the package logging generator, got: %s" % logging,
    )

    return analysistest.end(env)

workerless_package_generator_action_test = analysistest.make(
    _workerless_package_generator_action_test_impl,
    config_settings = {
        "//command_line_option:extra_toolchains": [str(Label("//tests/analysis:workerless_toolchain"))],
        WORKERLESS: True,
    },
)
