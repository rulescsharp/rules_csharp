"""Binary and test rules for rules_csharp."""

load(":compile.bzl", "compile_impl")
load(":providers.bzl", "CSharpAnalyzerInfo", "CSharpInfo", "CSharpToolchainInfo")
load(":toolchain_impl.bzl", "SEALED_DOTNET_ENV")

def _binary_common_impl(ctx, is_test = False):
    toolchain = ctx.toolchains["@rules_csharp//csharp:toolchain_type"].csharp_info

    # Compile the assembly
    compile_providers = compile_impl(ctx, is_analyzer = False)
    csharp_info = compile_providers[0]
    main_dll = csharp_info.runtime_dll
    pdb = csharp_info.pdb

    #monikers
    tfm = csharp_info.target_framework or "net8.0"
    version_num = tfm.replace("net", "")
    major = version_num.split(".")[0]
    framework_version = major + ".0.0"

    pkg = ctx.label.package
    probing_paths = ['"."']
    if pkg:
        probing_paths.append('"{}"'.format(pkg))
    probing_paths_str = ", ".join(probing_paths)

    # 1. Synthesize <name>.runtimeconfig.json
    runtimeconfig_json = ctx.actions.declare_file(ctx.label.name + ".runtimeconfig.json")
    sdk_flavor = getattr(ctx.attr, "sdk", "Microsoft.NET.Sdk")
    if sdk_flavor == "Microsoft.NET.Sdk.Web":
        framework_section = """    "frameworks": [
      {
        "name": "Microsoft.NETCore.App",
        "version": "%s"
      },
      {
        "name": "Microsoft.AspNetCore.App",
        "version": "%s"
      }
    ],""" % (framework_version, framework_version)
    else:
        framework_section = """    "framework": {
      "name": "Microsoft.NETCore.App",
      "version": "%s"
    },""" % framework_version

    runtimeconfig_content = """{{
  "runtimeOptions": {{
    "tfm": "{tfm}",
    "rollForward": "LatestMajor",
{framework_section}
    "additionalProbingPaths": [
      {probing_paths_str}
    ],
    "configProperties": {{
      "System.GC.Server": true,
      "System.Reflection.NullabilityInfoContext.IsSupported": true
    }}
  }}
}}
""".format(
        tfm = tfm,
        framework_section = framework_section,
        probing_paths_str = probing_paths_str,
    )
    ctx.actions.write(
        output = runtimeconfig_json,
        content = runtimeconfig_content,
    )

    # 2. Synthesize <name>.deps.json
    deps_json = ctx.actions.declare_file(ctx.label.name + ".deps.json")

    main_deps = {}
    target_entries = []
    library_entries = []

    seen_dep_names = {ctx.label.name: True}
    for dep_file in csharp_info.transitive_runtime_dlls.to_list():
        if dep_file.basename != main_dll.basename:
            dep_name = dep_file.basename[:-4] if dep_file.basename.endswith(".dll") else dep_file.basename
            if dep_name not in seen_dep_names:
                seen_dep_names[dep_name] = True
                main_deps[dep_name] = "1.0.0"
                target_entries.append("""      "{dep_name}/1.0.0": {{
        "runtime": {{
          "{dll_name}": {{}}
        }}
      }}""".format(dep_name = dep_name, dll_name = dep_file.basename))
                library_entries.append("""    "{dep_name}/1.0.0": {{
      "type": "package",
      "serviceable": false,
      "sha512": "",
      "path": "."
    }}""".format(dep_name = dep_name))

    main_dep_lines = ['          "{}": "{}"'.format(k, v) for k, v in main_deps.items()]
    main_deps_str = ",\n".join(main_dep_lines)

    root_target_entry = """      "{name}/1.0.0": {{
        "dependencies": {{
{main_deps_str}
        }},
        "runtime": {{
          "{dll_name}": {{}}
        }}
      }}""".format(
        name = ctx.label.name,
        dll_name = main_dll.basename,
        main_deps_str = main_deps_str,
    )

    root_library_entry = """    "{name}/1.0.0": {{
      "type": "project",
      "serviceable": false,
      "sha512": ""
    }}""".format(name = ctx.label.name)

    all_target_entries = [root_target_entry] + target_entries
    all_library_entries = [root_library_entry] + library_entries

    deps_content = """{{
  "runtimeTarget": {{
    "name": ".NETCoreApp,Version=v{version_num}"
  }},
  "targets": {{
    ".NETCoreApp,Version=v{version_num}": {{
{targets}
    }}
  }},
  "libraries": {{
{libraries}
  }}
}}
""".format(
        version_num = version_num,
        targets = ",\n".join(all_target_entries),
        libraries = ",\n".join(all_library_entries),
    )
    ctx.actions.write(
        output = deps_json,
        content = deps_content,
    )

    # 3. Stamp target platform's native apphost template binary
    is_windows = "win" in toolchain.target_rid
    exe_file = ctx.actions.declare_file(ctx.label.name + (".exe" if is_windows else ""))

    patcher_info = ctx.attr._patcher[CSharpInfo]
    patcher_dll = patcher_info.runtime_dll
    patcher_runtimeconfig = ctx.file._patcher_runtimeconfig

    patch_env = dict(toolchain.dotnet_env) if hasattr(toolchain, "dotnet_env") and toolchain.dotnet_env else dict(SEALED_DOTNET_ENV)
    patch_env["DOTNET_ROOT"] = toolchain.dotnet_muxer.dirname
    is_win = "win" in toolchain.host_rid
    patch_env["PATH"] = "C:\\Windows\\System32;C:\\Windows" if is_win else "/usr/bin:/bin"

    ctx.actions.run(
        executable = toolchain.dotnet_muxer,
        inputs = [
            toolchain.host_pack,
            patcher_dll,
            patcher_runtimeconfig,
        ] + toolchain.ref_pack.to_list() + toolchain.runtime_pack.to_list(),
        arguments = [
            patcher_dll.path,
            "--apphost-template=" + toolchain.host_pack.path,
            "--output=" + exe_file.path,
            "--assembly-name=" + main_dll.basename,
        ],
        outputs = [exe_file],
        env = patch_env,
        mnemonic = "CSharpAppHostPatch",
        progress_message = "Stamping AppHost %{label}",
        use_default_shell_env = False,
    )

    # 4. Assemble runfiles
    runfiles_files = [
        exe_file,
        main_dll,
        pdb,
        runtimeconfig_json,
        deps_json,
        toolchain.dotnet_muxer,
    ] + toolchain.runtime_pack.to_list()

    pkg = ctx.label.package
    prefix = pkg + "/" if pkg else ""

    runfiles_symlinks = {}
    for f in toolchain.runtime_pack.to_list():
        if "shared/" in f.path:
            idx = f.path.find("shared/")
            runfiles_symlinks[prefix + f.path[idx:]] = f
        elif "host/fxr/" in f.path:
            runfiles_symlinks[prefix + f.basename] = f
            idx = f.path.find("host/fxr/")
            runfiles_symlinks[prefix + f.path[idx:]] = f

    for f in csharp_info.transitive_runtime_dlls.to_list():
        runfiles_symlinks[prefix + f.basename] = f

    for f in csharp_info.transitive_native_libs.to_list():
        runfiles_symlinks[prefix + f.basename] = f

    runfiles_symlinks[prefix + runtimeconfig_json.basename] = runtimeconfig_json
    runfiles_symlinks[prefix + deps_json.basename] = deps_json
    runfiles_symlinks[prefix + toolchain.dotnet_muxer.basename] = toolchain.dotnet_muxer
    if hasattr(toolchain, "vstest_dll") and toolchain.vstest_dll:
        runfiles_symlinks[prefix + "vstest.console.dll"] = toolchain.vstest_dll

    extra_output_files = []
    for f in getattr(ctx.files, "content", []):
        runfiles_symlinks[prefix + f.basename] = f
        declared = ctx.actions.declare_file(f.basename)
        ctx.actions.symlink(output = declared, target_file = f)
        extra_output_files.append(declared)

    for target, dest_path in getattr(ctx.attr, "copy_to_output", {}).items():
        dest = dest_path if dest_path else target.files.to_list()[0].basename
        for f in target.files.to_list():
            declared = ctx.actions.declare_file(dest)
            ctx.actions.symlink(output = declared, target_file = f)
            extra_output_files.append(declared)
            runfiles_symlinks[prefix + dest] = f

    coverlet_dll = ""
    if is_test and ctx.configuration.coverage_enabled:
        # Coverlet finds symbols next to each assembly. Only instrumented targets carry a pdb here.
        for dep in ctx.attr.deps:
            if InstrumentedFilesInfo in dep:
                for f in dep[InstrumentedFilesInfo].metadata_files.to_list():
                    runfiles_symlinks[prefix + f.basename] = f
        for f in ctx.files._coverlet:
            # Keep the package layout so runtimes/<rid> copies never shadow the portable ones.
            runfiles_symlinks[prefix + "coverlet/" + f.short_path.split("tools/net8.0/any/", 1)[1]] = f
            if f.basename == "coverlet.console.dll":
                coverlet_dll = "coverlet/" + f.basename

    data_files = ctx.files.data if hasattr(ctx.files, "data") else []
    runfiles_files.extend(data_files)

    target_type = getattr(ctx.attr, "target_type", "exe")
    executable_file = exe_file
    if is_test:
        runner_ext = ".bat" if is_windows else ".sh"
        runner_file = ctx.actions.declare_file(ctx.label.name + "_runner" + runner_ext)
        vstest_path = toolchain.vstest_dll.path if hasattr(toolchain, "vstest_dll") and toolchain.vstest_dll else ""
        dotnet_path = toolchain.dotnet_muxer.path
        test_filter = getattr(ctx.attr, "test_filter", "")

        if is_windows:
            runner_content = """@echo off
setlocal enabledelayedexpansion
set SCRIPT_DIR=%~dp0
set DOTNET_ROOT=%SCRIPT_DIR%
set DOTNET_MULTILEVEL_LOOKUP=0
set DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
set DOTNET_CLI_TELEMETRY_OPTOUT=1
set DOTNET_NOLOGO=1
set VBCSCOMPILER_TTL=0
set MSBUILDDISABLENODEREUSE=1
set DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
set SCRATCH=%TEMP%\\.dotnet_scratch_%RANDOM%
if not exist "%SCRATCH%" mkdir "%SCRATCH%"
set DOTNET_CLI_HOME=%SCRATCH%
set HOME=%SCRATCH%
set USERPROFILE=%SCRATCH%
set APPDATA=%SCRATCH%

set DOTNET_BIN=%SCRIPT_DIR%{dotnet_bin}
set VSTEST_DLL=%SCRIPT_DIR%vstest.console.dll
set EXE_PATH=%SCRIPT_DIR%{exe_name}
set MAIN_DLL_PATH=%SCRIPT_DIR%{main_dll_name}

if not exist "!DOTNET_BIN!" (
    if defined RUNFILES_MANIFEST_FILE if exist "%RUNFILES_MANIFEST_FILE%" (
        for /f "usebackq tokens=1* delims= " %%A in ("%RUNFILES_MANIFEST_FILE%") do (
            set "R_KEY=%%A"
            if "!R_KEY:~-{dotnet_bin_len}!"=="{dotnet_bin}" (
                if exist "%%B" set "DOTNET_BIN=%%B"
            )
            if "!R_KEY:~-18!"=="vstest.console.dll" (
                if exist "%%B" set "VSTEST_DLL=%%B"
            )
            if "!R_KEY:~-{exe_name_len}!"=="{exe_name}" (
                if exist "%%B" set "EXE_PATH=%%B"
            )
            if "!R_KEY:~-{main_dll_len}!"=="{main_dll_name}" (
                if exist "%%B" set "MAIN_DLL_PATH=%%B"
            )
        )
    )
)

if not exist "!DOTNET_BIN!" set DOTNET_BIN={dotnet_path}
if not exist "!VSTEST_DLL!" set VSTEST_DLL={vstest_path}

for %%I in ("!DOTNET_BIN!") do (
    set "DOTNET_DIR=%%~dpI"
    if exist "!DOTNET_DIR!dotnet.exe" (
        set "DOTNET_ROOT=!DOTNET_DIR!"
        if "!DOTNET_ROOT:~-1!"=="\\" set "DOTNET_ROOT=!DOTNET_ROOT:~0,-1!"
    )
)

set FILTER=%TESTBRIDGE_TEST_ONLY%
if "%FILTER%"=="" set FILTER={test_filter}
if "{target_type}"=="library" (
    if not "%FILTER%"=="" (
        "!DOTNET_BIN!" exec "!VSTEST_DLL!" "!MAIN_DLL_PATH!" --logger:console --TestCaseFilter:"%FILTER%" %*
    ) else (
        "!DOTNET_BIN!" exec "!VSTEST_DLL!" "!MAIN_DLL_PATH!" --logger:console %*
    )
) else (
    if not "%FILTER%"=="" set TESTBRIDGE_TEST_ONLY=%FILTER%
    "!EXE_PATH!" %*
)
set EXIT_CODE=%ERRORLEVEL%
rmdir /s /q "%SCRATCH%" 2>nul
exit /b %EXIT_CODE%
""".format(
                dotnet_bin = toolchain.dotnet_muxer.basename,
                dotnet_bin_len = len(toolchain.dotnet_muxer.basename),
                dotnet_path = dotnet_path,
                exe_name = exe_file.basename,
                exe_name_len = len(exe_file.basename),
                main_dll_len = len(main_dll.basename),
                main_dll_name = main_dll.basename,
                target_type = target_type,
                test_filter = test_filter,
                vstest_path = vstest_path,
            )
        else:
            runner_content = """#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
export DOTNET_ROOT="$(cd "$DIR" && pwd)"
export DOTNET_MULTILEVEL_LOOKUP=0
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1
export VBCSCOMPILER_TTL=0
export MSBUILDDISABLENODEREUSE=1
export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
SCRATCH="${{TMPDIR:-/tmp}}/.dotnet_scratch_$$"
mkdir -p "$SCRATCH"
export DOTNET_CLI_HOME="$SCRATCH"
export HOME="$SCRATCH"
export USERPROFILE="$SCRATCH"
export APPDATA="$SCRATCH"

FILTER="${{TESTBRIDGE_TEST_ONLY:-{test_filter}}}"

DOTNET_BIN="$DIR/{dotnet_bin}"
VSTEST_DLL="$DIR/vstest.console.dll"
EXE_PATH="$DIR/{exe_name}"
MAIN_DLL_PATH="$DIR/{main_dll_name}"

if [ ! -f "$DOTNET_BIN" ] && [ -n "${{RUNFILES_MANIFEST_FILE:-}}" ] && [ -f "$RUNFILES_MANIFEST_FILE" ]; then
    while read -r rpath target; do
        case "$rpath" in
            *{dotnet_bin}) [ -f "$target" ] && DOTNET_BIN="$target" ;;
            *vstest.console.dll) [ -f "$target" ] && VSTEST_DLL="$target" ;;
            *{exe_name}) [ -f "$target" ] && EXE_PATH="$target" ;;
            *{main_dll_name}) [ -f "$target" ] && MAIN_DLL_PATH="$target" ;;
        esac
    done < "$RUNFILES_MANIFEST_FILE"
    if [ -f "$DOTNET_BIN" ]; then
        export DOTNET_ROOT="$(cd "$(dirname "$DOTNET_BIN")" && pwd)"
    fi
fi

if [ ! -f "$DOTNET_BIN" ]; then
    DOTNET_BIN="{dotnet_path}"
fi

if [ ! -f "$VSTEST_DLL" ]; then
    VSTEST_DLL="{vstest_path}"
fi

COVERLET_DLL="$DIR/{coverlet_dll}"
if [ -n "${{COVERAGE_DIR:-}}" ] && [ -f "$COVERLET_DLL" ]; then
    # Coverlet instruments assemblies in place, so run from a writable copy.
    APP_DIR="$SCRATCH/app"
    mkdir -p "$APP_DIR"
    for f in "$(dirname "$MAIN_DLL_PATH")"/*.dll "$(dirname "$MAIN_DLL_PATH")"/*.pdb "$(dirname "$MAIN_DLL_PATH")"/*.json; do
        [ -e "$f" ] || continue
        [ "$(basename "$f")" = vstest.console.dll ] || cp -L "$f" "$APP_DIR/"
    done
    chmod -R u+w "$APP_DIR"
    MAIN_DLL_PATH="$APP_DIR/$(basename "$MAIN_DLL_PATH")"
fi

if [ "{target_type}" = "library" ]; then
    set -- exec "$VSTEST_DLL" "$MAIN_DLL_PATH" --logger:console ${{FILTER:+--TestCaseFilter:"$FILTER"}} "$@"
    TEST_BIN="$DOTNET_BIN"
else
    if [ -n "$FILTER" ]; then
        export TESTBRIDGE_TEST_ONLY="$FILTER"
    fi
    TEST_BIN="$EXE_PATH"
    if [ -n "${{APP_DIR:-}}" ]; then
        set -- exec "$MAIN_DLL_PATH" "$@"
        TEST_BIN="$DOTNET_BIN"
    fi
fi

# set -e would exit before the cleanup below, so capture the test's exit code.
EXIT_CODE=0
if [ -n "${{APP_DIR:-}}" ]; then
    # Coverlet splits --targetargs like a command line, so quote each argument.
    TARGET_ARGS=""
    for a in "$@"; do
        TARGET_ARGS="$TARGET_ARGS \\"$(printf '%s' "$a" | sed 's/"/\\\\"/g')\\""
    done
    "$DOTNET_BIN" exec --roll-forward LatestMajor "$COVERLET_DLL" "$MAIN_DLL_PATH" \\
        --target "$TEST_BIN" --targetargs "$TARGET_ARGS" \\
        --exclude-assemblies-without-sources None \\
        --include-test-assembly \\
        --format lcov --output "$SCRATCH/coverlet.info" || EXIT_CODE=$?
    # Coverlet reports the absolute paths the compiler saw. Map each to its exec path in the manifest.
    awk 'NR == FNR {{ srcs[$0]; next }}
        /^SF:/ {{
            p = substr($0, 4); best = ""
            for (s in srcs) if (length(s) > length(best) && (p == s || substr(p, length(p) - length(s)) == "/" s)) best = s
            if (best != "") $0 = "SF:" best
        }}
        {{ print }}' "$COVERAGE_MANIFEST" "$SCRATCH/coverlet.info" > "$COVERAGE_DIR/coverlet.dat"
else
    "$TEST_BIN" "$@" || EXIT_CODE=$?
fi

rm -rf "$SCRATCH"
exit $EXIT_CODE
""".format(
                coverlet_dll = coverlet_dll,
                dotnet_bin = toolchain.dotnet_muxer.basename,
                dotnet_path = dotnet_path,
                exe_name = exe_file.basename,
                main_dll_name = main_dll.basename,
                target_type = target_type,
                test_filter = test_filter,
                vstest_path = vstest_path,
            )

        ctx.actions.write(
            output = runner_file,
            content = runner_content,
            is_executable = True,
        )
        executable_file = runner_file
        runfiles_files.append(runner_file)
        if hasattr(toolchain, "vstest_dll") and toolchain.vstest_dll:
            runfiles_files.append(toolchain.vstest_dll)

    runfiles = ctx.runfiles(
        files = runfiles_files + extra_output_files,
        symlinks = runfiles_symlinks,
        transitive_files = depset(
            csharp_info.transitive_runtime_dlls.to_list() +
            csharp_info.transitive_native_libs.to_list(),
        ),
    )

    providers = [
        DefaultInfo(
            executable = executable_file,
            files = depset([executable_file, main_dll, pdb, runtimeconfig_json, deps_json] + extra_output_files),
            runfiles = runfiles,
        ),
        csharp_info,
    ] + [p for p in compile_providers if type(p) == "InstrumentedFilesInfo"]

    pack_ws = getattr(toolchain.host_pack.owner, "workspace_name", "") or getattr(toolchain.host_pack.owner, "repo_name", "")
    dotnet_root_rel = "../" + pack_ws if pack_ws else toolchain.dotnet_muxer.dirname

    if is_test:
        test_env = dict(toolchain.dotnet_env) if hasattr(toolchain, "dotnet_env") and toolchain.dotnet_env else dict(SEALED_DOTNET_ENV)
        for k, v in getattr(ctx.attr, "env", {}).items():
            test_env[k] = v
        test_env["DOTNET_ROOT"] = dotnet_root_rel
        providers.append(
            testing.TestEnvironment(
                environment = test_env,
                inherited_environment = list(getattr(ctx.attr, "env_inherit", [])),
            ),
        )

    return providers

def _csharp_binary_impl(ctx):
    return _binary_common_impl(ctx, is_test = False)

def _csharp_test_impl(ctx):
    return _binary_common_impl(ctx, is_test = True)

_BINARY_ATTRS = {
    "_patcher": attr.label(
        cfg = "exec",
        default = Label("//csharp/private/tools:apphost_patcher"),
        doc = "Host executable for application host binary patching.",
    ),
    "_patcher_runtimeconfig": attr.label(
        allow_single_file = True,
        cfg = "exec",
        default = Label("//csharp/private/tools:apphost_patcher_runtimeconfig"),
        doc = "Runtime configuration file for patcher executable.",
    ),
    "defines": attr.string_list(
        default = [],
        doc = "Preprocessor symbols to define during compilation.",
    ),
    "deps": attr.label_list(
        default = [],
        doc = "Direct dependency libraries.",
        providers = [[CSharpInfo]],
    ),
    "exports": attr.label_list(
        default = [],
        doc = "Dependencies exported to downstream consumers.",
        providers = [[CSharpInfo]],
    ),
    "nowarn": attr.string_list(
        default = [],
        doc = "Compiler diagnostic codes to suppress.",
    ),
    "content": attr.label_list(
        allow_files = True,
        default = [],
        doc = "Static content files copied to runtime directories.",
    ),
    "copy_to_output": attr.label_keyed_string_dict(
        allow_files = True,
        default = {},
        doc = "Files mapped to destination output paths.",
    ),
    "generate_assembly_info": attr.bool(
        default = True,
        doc = "Synthesize assembly information attributes.",
    ),
    "implicit_usings": attr.bool(
        default = True,
        doc = "Synthesize implicit global usings namespace imports.",
    ),
    "internals_visible_to": attr.string_list(
        default = [],
        doc = "Friend assembly names for InternalsVisibleTo.",
    ),
    "langversion": attr.string(
        default = "latest",
        doc = "Target C# language version specification.",
    ),
    "plugins": attr.label_list(
        default = [],
        doc = "Roslyn analyzer and generator plugins.",
        providers = [[CSharpAnalyzerInfo]],
    ),
    "resources": attr.label_keyed_string_dict(
        allow_files = True,
        default = {},
        doc = "Embedded resource files mapped to logical names.",
    ),
    "warn_as_error": attr.bool(
        default = False,
        doc = "Treat compiler warnings as errors.",
    ),
    "warning_level": attr.int(
        default = 4,
        doc = "Compiler diagnostic severity level.",
    ),
    "sdk": attr.string(
        default = "Microsoft.NET.Sdk",
        doc = "Target .NET SDK project flavor.",
        values = [
            "Microsoft.NET.Sdk",
            "Microsoft.NET.Sdk.Web",
            "Microsoft.NET.Sdk.Worker",
        ],
    ),
    "srcs": attr.label_list(
        allow_files = [".cs"],
        default = [],
        doc = "C# source files to compile.",
    ),
    "target_framework": attr.string(
        default = "",
        doc = "Target framework moniker string.",
    ),
    "target_type": attr.string(
        default = "exe",
        doc = "Compiler target type output flag.",
    ),
}

csharp_binary = rule(
    doc = "Compiles a C# executable and stamps the native application host binary.",
    implementation = _csharp_binary_impl,
    attrs = _BINARY_ATTRS,
    executable = True,
    toolchains = ["@rules_csharp//csharp:toolchain_type"],
)

_TEST_ATTRS = dict(_BINARY_ATTRS)
_TEST_ATTRS.update({
    "_coverlet": attr.label(
        allow_files = True,
        default = Label("//csharp/private:coverlet"),
        doc = "Coverlet console files, empty unless collecting coverage.",
    ),
    "_lcov_merger": attr.label(
        cfg = "exec",
        default = configuration_field(fragment = "coverage", name = "output_generator"),
        doc = "Bazel coverage output generator that merges LCOV reports.",
    ),
    "data": attr.label_list(
        allow_files = True,
        default = [],
        doc = "Runtime data files for test execution.",
    ),
    "env": attr.string_dict(
        default = {},
        doc = "Environment variables for test execution.",
    ),
    "env_inherit": attr.string_list(
        default = [],
        doc = "Environment variables inherited from client environment.",
    ),
    "test_filter": attr.string(
        default = "",
        doc = "Default test filter expression.",
    ),
})

csharp_test = rule(
    doc = """Compiles and executes a C# test binary under the Bazel test harness.

`bazel coverage` reports line, branch, and method coverage of instrumented C# sources, collected with
[Coverlet](https://github.com/coverlet-coverage/coverlet) and merged by Bazel into LCOV. Coverage runs on
Linux (macOS is not verified yet). Windows test runners report none.
""",
    implementation = _csharp_test_impl,
    attrs = _TEST_ATTRS,
    executable = True,
    test = True,
    toolchains = ["@rules_csharp//csharp:toolchain_type"],
)


