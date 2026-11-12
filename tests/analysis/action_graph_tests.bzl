load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//csharp:defs.bzl", "CSharpInfo")


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

def _friend_ref_action_test_impl(ctx):
    env = analysistest.begin(ctx)

    compile_actions = [a for a in analysistest.target_actions(env) if a.mnemonic == "CSharpCompile"]
    asserts.equals(env, 1, len(compile_actions))
    inputs = [f.short_path for f in compile_actions[0].inputs.to_list()]
    has = lambda suffix: len([p for p in inputs if p.endswith("/" + suffix)]) > 0
    asserts.true(env, has(ctx.attr.expected_ref), "Expected %s in compile inputs, got: %s" % (ctx.attr.expected_ref, inputs))
    asserts.false(env, has(ctx.attr.unexpected_ref), "Expected %s absent from compile inputs, got: %s" % (ctx.attr.unexpected_ref, inputs))

    return analysistest.end(env)

friend_ref_action_test = analysistest.make(
    _friend_ref_action_test_impl,
    attrs = {
        "expected_ref": attr.string(mandatory = True),
        "unexpected_ref": attr.string(mandatory = True),
    },
)

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

    # The apphost searches only <app dir>\dotnet, with no "..", since Windows resolves ".." from the
    # bazel-bin path without following the junction. That is the one directory link per binary, to
    # the runtime tree the toolchain builds, and it is in the default outputs.
    asserts.true(
        env,
        "--app-relative-dotnet=dotnet" in patch_action.argv,
        "Expected the apphost to search cross_app_\\dotnet only, got: %s" % patch_action.argv,
    )
    target = analysistest.target_under_test(env)
    links = [f for f in target[DefaultInfo].files.to_list() if f.short_path.endswith("cross_app_/dotnet")]
    asserts.equals(env, 1, len(links), "Expected one dotnet directory in the default outputs, got: %s" % links)
    asserts.true(env, links[0].is_directory, "Expected cross_app_/dotnet to be a directory output")
    under = [f.short_path for f in target[DefaultInfo].files.to_list() if "cross_app_/dotnet/" in f.short_path]
    asserts.equals(env, [], under, "Expected no per file runtime outputs under cross_app_/dotnet, got: %s" % under)
    link_actions = [a for a in actions if a.mnemonic == "Symlink" and a.outputs.to_list()[0].short_path.endswith("cross_app_/dotnet")]
    asserts.equals(env, 1, len(link_actions), "Expected one symlink action for cross_app_/dotnet")
    link_input = link_actions[0].inputs.to_list()[0]
    asserts.true(
        env,
        link_input.is_directory and link_input.basename.endswith("_dotnet") and "windows" in link_input.path,
        "Expected the link to point at the toolchain's runtime tree for the target platform, got: %s" % link_input.path,
    )

    # bazel run reaches the runtime from <exe>.runfiles and from <exe>.runfiles/<workspace>
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
    asserts.expect_failure(env, 'bazel_dep(name = "rules_csharp_proto", version = "0.5.0")')
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

def _older_csharp_info_impl(ctx):
    info = ctx.attr.lib[CSharpInfo]
    return [CSharpInfo(
        target_framework = info.target_framework,
        compile_ref = info.compile_ref,
        runtime_dll = info.runtime_dll,
        pdb = info.pdb,
        transitive_compile_refs = info.transitive_compile_refs,
        transitive_runtime_dlls = info.transitive_runtime_dlls,
        transitive_native_libs = info.transitive_native_libs,
    )]

# Rewraps a library's CSharpInfo with only the fields 0.4.0 had, like a rule written against it.
older_csharp_info = rule(
    implementation = _older_csharp_info_impl,
    attrs = {"lib": attr.label(providers = [CSharpInfo], mandatory = True)},
)

def _older_csharp_info_dep_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.true(env, CSharpInfo in analysistest.target_under_test(env))
    return analysistest.end(env)

older_csharp_info_dep_test = analysistest.make(_older_csharp_info_dep_test_impl)
def _written_content(actions, suffix):
    for a in actions:
        if a.mnemonic == "FileWrite" and a.outputs.to_list()[0].basename.endswith(suffix):
            return a.content
    return None

def _framework_reference_action_test_impl(ctx):
    env = analysistest.begin(ctx)

    target = analysistest.target_under_test(env)
    asserts.equals(env, ["Microsoft.AspNetCore.App"], target[CSharpInfo].framework_references.to_list())

    actions = analysistest.target_actions(env)
    compile_actions = [a for a in actions if a.mnemonic == "CSharpCompile"]
    asserts.equals(env, 1, len(compile_actions))
    input_paths = [f.path for f in compile_actions[0].inputs.to_list()]
    asserts.true(
        env,
        any(["Microsoft.AspNetCore.App.Ref" in p for p in input_paths]),
        "Expected the ASP.NET Core reference assemblies from the library in compile inputs, got: %s" % input_paths,
    )

    runtimeconfig = _written_content(actions, ".runtimeconfig.json")
    asserts.true(
        env,
        runtimeconfig and '"name": "Microsoft.NETCore.App"' in runtimeconfig and '"name": "Microsoft.AspNetCore.App"' in runtimeconfig,
        "Expected runtimeconfig.json to list both shared frameworks, got: %s" % runtimeconfig,
    )

    return analysistest.end(env)

framework_reference_action_test = analysistest.make(_framework_reference_action_test_impl)

def _runtimeconfig_action_test_impl(ctx):
    env = analysistest.begin(ctx)

    runtimeconfig = _written_content(analysistest.target_actions(env), ".runtimeconfig.json")
    asserts.equals(env, ctx.attr.server_gc, '"System.GC.Server": true' in runtimeconfig, "System.GC.Server in: %s" % runtimeconfig)
    asserts.false(env, "rollForward" in runtimeconfig, "Expected the default roll forward, got: %s" % runtimeconfig)

    return analysistest.end(env)

runtimeconfig_action_test = analysistest.make(
    _runtimeconfig_action_test_impl,
    attrs = {"server_gc": attr.bool()},
)

def _worker_sdk_action_test_impl(ctx):
    env = analysistest.begin(ctx)

    usings = _written_content(analysistest.target_actions(env), ".GlobalUsings.g.cs")
    for ns in ["Microsoft.Extensions.Configuration", "Microsoft.Extensions.DependencyInjection", "Microsoft.Extensions.Hosting", "Microsoft.Extensions.Logging"]:
        asserts.true(env, "global using global::%s;" % ns in usings, "Expected a global using for %s, got: %s" % (ns, usings))
    asserts.false(env, "Microsoft.AspNetCore" in usings, "Expected no ASP.NET Core usings for the Worker SDK, got: %s" % usings)

    return analysistest.end(env)

worker_sdk_action_test = analysistest.make(_worker_sdk_action_test_impl)

def _expect_failure_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, ctx.attr.message)
    return analysistest.end(env)

expect_failure_test = analysistest.make(
    _expect_failure_test_impl,
    attrs = {"message": attr.string(mandatory = True)},
    expect_failure = True,
)

def _analyzes_test_impl(ctx):
    env = analysistest.begin(ctx)
    return analysistest.end(env)

analyzes_test = analysistest.make(_analyzes_test_impl)

def _output_assembly_action_test_impl(ctx):
    env = analysistest.begin(ctx)

    actions = analysistest.target_actions(env)
    compile_actions = [a for a in actions if a.mnemonic == "CSharpCompile"]
    asserts.equals(env, 1, len(compile_actions))
    outputs = sorted([f.basename for f in compile_actions[0].outputs.to_list()])
    asserts.equals(env, ["Contoso.App.dll", "Contoso.App.pdb", "Contoso.App.ref.dll"], outputs)

    input_basenames = [f.basename for f in compile_actions[0].inputs.to_list()]
    asserts.true(env, "Contoso.Greeting.ref.dll" in input_basenames, "Expected the renamed library in compile inputs, got: %s" % input_basenames)

    assembly_info = _written_content(actions, ".AssemblyInfo.g.cs")
    asserts.true(env, 'AssemblyTitle("Contoso.App")' in assembly_info, "Expected the assembly title to follow output_assembly, got: %s" % assembly_info)

    asserts.true(env, _written_content(actions, "Contoso.App.runtimeconfig.json") != None, "Expected Contoso.App.runtimeconfig.json")
    deps_json = _written_content(actions, "Contoso.App.deps.json")
    asserts.true(
        env,
        deps_json and '"Contoso.App/1.0.0"' in deps_json and '"Contoso.Greeting.dll"' in deps_json,
        "Expected deps.json to name both renamed assemblies, got: %s" % deps_json,
    )

    target = analysistest.target_under_test(env)
    exe = target[DefaultInfo].files_to_run.executable
    asserts.true(env, exe.basename in ("renamed_app", "renamed_app.exe"), "Expected the executable to keep the target name, got: %s" % exe.basename)

    patch_actions = [a for a in actions if a.mnemonic == "CSharpAppHostPatch"]
    asserts.true(
        env,
        [arg for arg in patch_actions[0].argv if arg.endswith("Contoso.App.dll")],
        "Expected the apphost to load Contoso.App.dll, got: %s" % patch_actions[0].argv,
    )

    return analysistest.end(env)

output_assembly_action_test = analysistest.make(_output_assembly_action_test_impl)

def _editorconfig_action_test_impl(ctx):
    env = analysistest.begin(ctx)

    compile_actions = [a for a in analysistest.target_actions(env) if a.mnemonic == "CSharpCompile"]
    asserts.equals(env, 1, len(compile_actions))
    compile_action = compile_actions[0]

    path = "tests/integration/editorconfig/.editorconfig"
    asserts.true(env, "-analyzerconfig:" + path in compile_action.argv, "Expected -analyzerconfig:%s, got: %s" % (path, compile_action.argv))
    asserts.true(
        env,
        path in [f.short_path for f in compile_action.inputs.to_list()],
        "Expected %s in compile inputs" % path,
    )

    return analysistest.end(env)

editorconfig_action_test = analysistest.make(_editorconfig_action_test_impl)

def _compilation_mode_action_test_impl(ctx):
    env = analysistest.begin(ctx)

    compile_actions = [a for a in analysistest.target_actions(env) if a.mnemonic == "CSharpCompile"]
    asserts.equals(env, 1, len(compile_actions))
    argv = compile_actions[0].argv
    for flag in ctx.attr.expected_flags:
        asserts.true(env, flag in argv, "Expected %s, got: %s" % (flag, argv))
    for flag in ctx.attr.unexpected_flags:
        asserts.false(env, flag in argv, "Expected no %s, got: %s" % (flag, argv))

    return analysistest.end(env)

_COMPILATION_MODE_TEST_ATTRS = {
    "expected_flags": attr.string_list(),
    "unexpected_flags": attr.string_list(),
}

compilation_mode_action_test = analysistest.make(
    _compilation_mode_action_test_impl,
    attrs = _COMPILATION_MODE_TEST_ATTRS,
    config_settings = {"//command_line_option:compilation_mode": "fastbuild"},
)

opt_compilation_mode_action_test = analysistest.make(
    _compilation_mode_action_test_impl,
    attrs = _COMPILATION_MODE_TEST_ATTRS,
    config_settings = {"//command_line_option:compilation_mode": "opt"},
)

def _additional_compiler_options_action_test_impl(ctx):
    env = analysistest.begin(ctx)

    compile_actions = [a for a in analysistest.target_actions(env) if a.mnemonic == "CSharpCompile"]
    asserts.equals(env, 1, len(compile_actions))
    argv = compile_actions[0].argv
    asserts.true(env, "-checked+" in argv, "Expected -checked+, got: %s" % argv)

    return analysistest.end(env)

additional_compiler_options_action_test = analysistest.make(_additional_compiler_options_action_test_impl)

