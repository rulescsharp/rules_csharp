load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")


def _abi_refout_action_test_impl(ctx):
    env = analysistest.begin(ctx)

    actions = analysistest.target_actions(env)
    compile_actions = [a for a in actions if a.mnemonic == "CSharpCompile"]
    asserts.equals(env, 1, len(compile_actions))

    compile_action = compile_actions[0]
    input_basenames = [f.basename for f in compile_action.inputs.to_list()]

    # lib_a.ref.dll is an input
    asserts.true(
        env,
        "lib_a.ref.dll" in input_basenames,
        "Expected lib_a.ref.dll in compile inputs, got: %s" % input_basenames,
    )

    # lib_a.dll is not an input
    asserts.false(
        env,
        "lib_a.dll" in input_basenames,
        "Expected lib_a.dll to be absent from compile inputs, but found in: %s" % input_basenames,
    )

    return analysistest.end(env)

abi_refout_action_test = analysistest.make(_abi_refout_action_test_impl)

def _cross_windows_action_test_impl(ctx):
    env = analysistest.begin(ctx)

    actions = analysistest.target_actions(env)
    compile_actions = [a for a in actions if a.mnemonic == "CSharpCompile"]
    asserts.equals(env, 1, len(compile_actions))
    compile_action = compile_actions[0]

    # uses host csc.dll
    compile_input_basenames = [f.basename for f in compile_action.inputs.to_list()]
    asserts.true(
        env,
        "csc.dll" in compile_input_basenames,
        "Expected host csc.dll in compile inputs",
    )

    # uses target apphost.exe template
    patch_actions = [a for a in actions if a.mnemonic == "CSharpAppHostPatch"]
    asserts.equals(env, 1, len(patch_actions))
    patch_action = patch_actions[0]

    patch_inputs = [f.basename for f in patch_action.inputs.to_list()]
    asserts.true(
        env,
        "apphost.exe" in patch_inputs,
        "Expected Windows apphost.exe template in AppHostPatch inputs, got: %s" % patch_inputs,
    )

    patch_outputs = [f.basename for f in patch_action.outputs.to_list()]
    asserts.true(
        env,
        any([out.endswith(".exe") for out in patch_outputs]),
        "Expected .exe output for Windows binary, got: %s" % patch_outputs,
    )

    # The apphost loads the app from its own directory, so it runs without a runfiles tree
    asserts.true(
        env,
        "--assembly-name=cross_app_\\cross_app.dll" in patch_action.argv,
        "Expected the apphost to point into cross_app_\\, got: %s" % patch_action.argv,
    )

    # bazel run reaches the runtime from <exe>.runfiles and from <exe>.runfiles/<workspace>
    target = analysistest.target_under_test(env)
    exe = target[DefaultInfo].files_to_run.executable
    dotnet_root = target[RunEnvironmentInfo].environment["DOTNET_ROOT"]
    up = ctx.workspace_name + "/" + "../" * (len(exe.path.split("/")) + 1)
    asserts.true(
        env,
        dotnet_root.startswith(up + "external/") and "csharp_pack_" in dotnet_root,
        "Expected DOTNET_ROOT to go from the run directory up to the runtime pack, got: %s" % dotnet_root,
    )

    return analysistest.end(env)

cross_windows_action_test = analysistest.make(
    _cross_windows_action_test_impl,
    config_settings = {
        "//command_line_option:platforms": str(Label("//csharp/constraints:windows_x64_platform")),
    },
)

def _cross_linux_action_test_impl(ctx):
    env = analysistest.begin(ctx)

    actions = analysistest.target_actions(env)
    compile_actions = [a for a in actions if a.mnemonic == "CSharpCompile"]
    asserts.equals(env, 1, len(compile_actions))
    compile_action = compile_actions[0]

    # uses host csc.dll
    compile_input_basenames = [f.basename for f in compile_action.inputs.to_list()]
    asserts.true(
        env,
        "csc.dll" in compile_input_basenames,
        "Expected host csc.dll in compile inputs",
    )

    # uses Linux apphost template (non-.exe)
    patch_actions = [a for a in actions if a.mnemonic == "CSharpAppHostPatch"]
    asserts.equals(env, 1, len(patch_actions))
    patch_action = patch_actions[0]

    patch_inputs = [f.basename for f in patch_action.inputs.to_list()]
    asserts.true(
        env,
        "apphost" in patch_inputs,
        "Expected Linux apphost template in AppHostPatch inputs, got: %s" % patch_inputs,
    )

    patch_outputs = [f.basename for f in patch_action.outputs.to_list()]
    asserts.false(
        env,
        any([out.endswith(".exe") for out in patch_outputs]),
        "Expected non-.exe output for Linux binary, got: %s" % patch_outputs,
    )

    return analysistest.end(env)

cross_linux_action_test = analysistest.make(
    _cross_linux_action_test_impl,
    config_settings = {
        "//command_line_option:platforms": str(Label("//csharp/constraints:linux_x64_platform")),
    },
)

def _csc_worker_action_test_impl(ctx):
    env = analysistest.begin(ctx)

    actions = analysistest.target_actions(env)
    compile_actions = [a for a in actions if a.mnemonic == "CSharpCompile"]
    asserts.equals(env, 1, len(compile_actions))
    compile_action = compile_actions[0]

    argv0 = compile_action.argv[0]
    asserts.true(
        env,
        argv0.endswith("/CscWorker") or argv0.endswith("/CscWorker.bat"),
        "Expected action.argv[0] to end with CscWorker or, on Windows, CscWorker.bat, got: %s" % argv0,
    )
    asserts.true(
        env,
        "--persistent_worker" in compile_action.argv,
        "Expected --persistent_worker in compile action arguments",
    )

    return analysistest.end(env)

csc_worker_action_test = analysistest.make(_csc_worker_action_test_impl)

def _web_sdk_action_test_impl(ctx):
    env = analysistest.begin(ctx)

    actions = analysistest.target_actions(env)
    compile_actions = [a for a in actions if a.mnemonic == "CSharpCompile"]
    asserts.equals(env, 1, len(compile_actions))
    compile_action = compile_actions[0]

    input_paths = [f.path for f in compile_action.inputs.to_list()]
    asserts.true(
        env,
        any(["Microsoft.AspNetCore.App.Ref" in p for p in input_paths]),
        "Expected Microsoft.AspNetCore.App.Ref reference assemblies in compile inputs, got: %s" % input_paths,
    )

    return analysistest.end(env)

web_sdk_action_test = analysistest.make(_web_sdk_action_test_impl)

def _msbuild_parity_action_test_impl(ctx):
    env = analysistest.begin(ctx)

    actions = analysistest.target_actions(env)
    compile_actions = [a for a in actions if a.mnemonic == "CSharpCompile"]
    asserts.equals(env, 1, len(compile_actions))
    compile_action = compile_actions[0]

    input_basenames = [f.basename for f in compile_action.inputs.to_list()]
    asserts.true(
        env,
        any([b.endswith(".GlobalUsings.g.cs") for b in input_basenames]),
        "Expected *.GlobalUsings.g.cs in compile inputs, got: %s" % input_basenames,
    )
    asserts.true(
        env,
        any([b.endswith(".AssemblyInfo.g.cs") for b in input_basenames]),
        "Expected *.AssemblyInfo.g.cs in compile inputs, got: %s" % input_basenames,
    )

    return analysistest.end(env)

msbuild_parity_action_test = analysistest.make(_msbuild_parity_action_test_impl)

def _proto_moved_test_impl(ctx):
    env = analysistest.begin(ctx)

    asserts.expect_failure(env, "%s moved to the rules_csharp_proto module" % ctx.attr.rule_name)
    asserts.expect_failure(env, 'bazel_dep(name = "rules_csharp_proto", version = "0.4.0")')
    asserts.expect_failure(env, 'load("@rules_csharp_proto//csharp:defs.bzl", "%s")' % ctx.attr.rule_name)

    return analysistest.end(env)

proto_moved_test = analysistest.make(
    _proto_moved_test_impl,
    attrs = {"rule_name": attr.string(mandatory = True)},
    expect_failure = True,
)

def _hermetic_sandbox_action_test_impl(ctx):
    env = analysistest.begin(ctx)

    actions = analysistest.target_actions(env)
    compile_actions = [a for a in actions if a.mnemonic == "CSharpCompile"]
    asserts.equals(env, 1, len(compile_actions))
    compile_action = compile_actions[0]

    action_env = compile_action.env
    asserts.equals(env, "0", action_env.get("DOTNET_MULTILEVEL_LOOKUP"))
    asserts.equals(env, "1", action_env.get("DOTNET_SKIP_FIRST_TIME_EXPERIENCE"))
    asserts.equals(env, "1", action_env.get("DOTNET_CLI_TELEMETRY_OPTOUT"))
    asserts.equals(env, "1", action_env.get("DOTNET_NOLOGO"))
    asserts.equals(env, "0", action_env.get("VBCSCOMPILER_TTL"))
    asserts.equals(env, "1", action_env.get("MSBUILDDISABLENODEREUSE"))
    asserts.equals(env, "1", action_env.get("DOTNET_SYSTEM_GLOBALIZATION_INVARIANT"))
    asserts.equals(env, ".dotnet_scratch", action_env.get("DOTNET_CLI_HOME"))
    asserts.false(
        env,
        action_env.get("DOTNET_ROOT", "").startswith("/"),
        "Expected DOTNET_ROOT to be relative path, got: %s" % action_env.get("DOTNET_ROOT"),
    )

    return analysistest.end(env)

hermetic_sandbox_action_test = analysistest.make(_hermetic_sandbox_action_test_impl)




def _target_framework_action_test_impl(ctx):
    env = analysistest.begin(ctx)

    compile_actions = [a for a in analysistest.target_actions(env) if a.mnemonic == "CSharpCompile"]
    asserts.equals(env, 1, len(compile_actions))
    ref_dirs = {f.dirname: None for f in compile_actions[0].inputs.to_list() if "/Microsoft.NETCore.App.Ref/" in f.path}
    want = "/ref/" + ctx.attr.expected_tfm
    asserts.true(
        env,
        ref_dirs and all([d.endswith(want) for d in ref_dirs]),
        "Expected only %s reference assemblies, got: %s" % (want, ref_dirs.keys()),
    )

    return analysistest.end(env)

target_framework_action_test = analysistest.make(
    _target_framework_action_test_impl,
    attrs = {"expected_tfm": attr.string(mandatory = True)},
)
