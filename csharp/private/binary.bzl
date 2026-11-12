"""Binary and test rules for rules_csharp."""

load(":common.bzl", "TARGET_FRAMEWORKS", "TARGET_FRAMEWORK_DOC", "target_framework_transition")
load(":compile.bzl", "ADDITIONAL_COMPILER_OPTIONS_DOC", "ALLOW_UNSAFE_BLOCKS_DOC", "DATA_DOC", "DEFINES_DOC", "EDITORCONFIG_FILES_DOC", "FRAMEWORK_REFERENCES_DOC", "GENERATE_DOCUMENTATION_FILE_DOC", "INTERNALS_VISIBLE_TO_DOC", "OUTPUT_ASSEMBLY_DOC", "RESOURCES_DOC", "SDK_DOC", "compile_impl", "library_runfiles", "output_assembly")
load(":providers.bzl", "CSharpAnalyzerInfo", "CSharpInfo", "CSharpToolchainInfo")
load(":toolchain_impl.bzl", "SEALED_DOTNET_ENV")

def _package_relative_path(f):
    path = f.short_path
    if path.startswith("../"):
        path = path.split("/", 2)[2]
    package = f.owner.package
    return path[len(package) + 1:] if package else path

def _binary_common_impl(ctx, is_test = False):
    toolchain = ctx.toolchains["@rules_csharp//csharp:toolchain_type"].csharp_info

    # The app and everything it loads sit together in their own directory, so the host finds them
    # with or without a runfiles tree (Windows has none by default). The host resolves symlinks on
    # the app dll, so the dll is compiled there rather than linked in.
    app_dir = ctx.label.name + "_/"

    # Compile the assembly
    compile_providers = compile_impl(ctx, is_analyzer = False, out_dir = app_dir)
    csharp_info = compile_providers[0]
    main_dll = csharp_info.runtime_dll
    pdb = csharp_info.pdb
    assembly = output_assembly(ctx)

    # The host loads one assembly per name, so a second one with the same name would silently go missing.
    # One target built for two frameworks is still one assembly. Prebuilt packages often ship the same
    # dll, like Microsoft.TestPlatform.CoreUtilities in both test platform packages. The app keeps the
    # first of those in dependency order where MSBuild would pick the higher version, so only a clash
    # with an assembly built here fails.
    assembly_owners = {}
    for f in csharp_info.transitive_runtime_dlls.to_list():
        other = assembly_owners.setdefault(f.basename.lower(), f)
        if other.owner != f.owner and not (other.is_source and f.is_source):
            built = other if f.is_source else f
            fail("""{} loads two assemblies named {}, from {} and {}. Set output_assembly on {} so each \
name is unique.""".format(ctx.label, f.basename.removesuffix(".dll"), other.owner, f.owner, built.owner))

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
    runtimeconfig_json = ctx.actions.declare_file(app_dir + assembly + ".runtimeconfig.json")
    frameworks = csharp_info.framework_references.to_list()
    if frameworks:
        framework_section = """    "frameworks": [
%s
    ],""" % ",\n".join([
            """      {
        "name": "%s",
        "version": "%s"
      }""" % (name, framework_version)
            for name in ["Microsoft.NETCore.App"] + sorted(frameworks)
        ])
    else:
        framework_section = """    "framework": {
      "name": "Microsoft.NETCore.App",
      "version": "%s"
    },""" % framework_version

    runtimeconfig_content = """{{
  "runtimeOptions": {{
    "tfm": "{tfm}",
{framework_section}
    "additionalProbingPaths": [
      {probing_paths_str}
    ],
    "configProperties": {{
{gc_server}      "System.Reflection.NullabilityInfoContext.IsSupported": true
    }}
  }}
}}
""".format(
        tfm = tfm,
        framework_section = framework_section,
        # Like dotnet build, only the Web SDK turns on server GC.
        gc_server = '      "System.GC.Server": true,\n' if getattr(ctx.attr, "sdk", "") == "Microsoft.NET.Sdk.Web" else "",
        probing_paths_str = probing_paths_str,
    )
    ctx.actions.write(
        output = runtimeconfig_json,
        content = runtimeconfig_content,
    )

    # 2. Synthesize <name>.deps.json
    deps_json = ctx.actions.declare_file(app_dir + assembly + ".deps.json")

    main_deps = {}
    target_entries = []
    library_entries = []

    seen_dep_names = {assembly: True}
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
        name = assembly,
        dll_name = main_dll.basename,
        main_deps_str = main_deps_str,
    )

    root_library_entry = """    "{name}/1.0.0": {{
      "type": "project",
      "serviceable": false,
      "sha512": ""
    }}""".format(name = assembly)

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

    # The apphost looks for .NET in the dotnet directory next to the app dll and nowhere else, so the
    # binary also runs as a build tool and straight from bazel-bin, where bazel run's DOTNET_ROOT
    # doesn't apply. That directory is a link to the toolchain's runtime tree, declared below.
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
            "--assembly-name=" + (app_dir.replace("/", "\\") if is_windows else app_dir) + main_dll.basename,
            "--app-relative-dotnet=dotnet",
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

    # One directory link per binary, to the runtime tree the toolchain builds once. It is a declared
    # output, so every executor stages it with the binary, and it has no "..", which the Windows
    # apphost would resolve against the bazel-bin path without following its junction.
    extra_output_files = []
    if toolchain.runtime_tree:
        runtime_link = ctx.actions.declare_directory(app_dir + "dotnet")
        ctx.actions.symlink(output = runtime_link, target_file = toolchain.runtime_tree)
        extra_output_files.append(runtime_link)
    app_files = {main_dll.basename: True}
    for f in csharp_info.transitive_runtime_dlls.to_list() + csharp_info.transitive_native_libs.to_list():
        if f.basename not in app_files:
            app_files[f.basename] = True
            declared = ctx.actions.declare_file(app_dir + f.basename)
            ctx.actions.symlink(output = declared, target_file = f)
            extra_output_files.append(declared)

    launcher_dll = None
    if is_test and getattr(ctx.attr, "target_type", "exe") == "library":
        launcher_dll = ctx.attr._vstest_launcher[CSharpInfo].runtime_dll
        runfiles_files.append(launcher_dll)
        runfiles_symlinks[prefix + launcher_dll.basename] = launcher_dll

        # The testhost only loads *TestAdapter.dll files from the test dll's own dir. A runtime dll
        # with the same name wins, as MSTest ships some dlls in both lib/ and build/.
        for f in csharp_info.transitive_test_runtime_dlls.to_list():
            if f.basename not in app_files:
                app_files[f.basename] = True
                runfiles_symlinks[prefix + f.basename] = f
                declared = ctx.actions.declare_file(app_dir + f.basename)
                ctx.actions.symlink(output = declared, target_file = f)
                extra_output_files.append(declared)

    content_paths = {}
    for f in getattr(ctx.files, "content", []):
        dest = _package_relative_path(f)
        if dest in content_paths:
            fail("content files {} and {} both land at {}. Use copy_to_output to give one another path.".format(
                content_paths[dest].short_path,
                f.short_path,
                dest,
            ))
        content_paths[dest] = f
        runfiles_symlinks[prefix + dest] = f
        declared = ctx.actions.declare_file(app_dir + dest)
        ctx.actions.symlink(output = declared, target_file = f)
        extra_output_files.append(declared)

    for target, dest_path in getattr(ctx.attr, "copy_to_output", {}).items():
        dest = dest_path if dest_path else target.files.to_list()[0].basename
        for f in target.files.to_list():
            declared = ctx.actions.declare_file(app_dir + dest)
            ctx.actions.symlink(output = declared, target_file = f)
            extra_output_files.append(declared)
            runfiles_symlinks[prefix + dest] = f

    coverlet_dll = ""
    if is_test and ctx.configuration.coverage_enabled:
        # Coverlet finds symbols next to each assembly. Only instrumented targets carry a pdb here.
        # The app dir gets them too, since Windows runs tests without a runfiles tree by default.
        coverage_files = {}
        for dep in ctx.attr.deps:
            if InstrumentedFilesInfo in dep:
                for f in dep[InstrumentedFilesInfo].metadata_files.to_list():
                    coverage_files[f.basename] = f
        for f in ctx.files._coverlet:
            # Keep the package layout so runtimes/<rid> copies never shadow the portable ones.
            coverage_files["coverlet/" + f.short_path.split("tools/net8.0/any/", 1)[1]] = f
            if f.basename == "coverlet.console.dll":
                coverlet_dll = "coverlet/" + f.basename
        if ctx.coverage_instrumented():
            # With --instrument_test_targets the test's own pdb goes next to its dll in runfiles too.
            # The app dir already holds it.
            runfiles_symlinks[prefix + pdb.basename] = pdb
        for dest, f in coverage_files.items():
            runfiles_symlinks[prefix + dest] = f
            if dest not in app_files:
                declared = ctx.actions.declare_file(app_dir + dest)
                ctx.actions.symlink(output = declared, target_file = f)
                extra_output_files.append(declared)

    target_type = getattr(ctx.attr, "target_type", "exe")
    executable_file = exe_file
    if is_test:
        runner_ext = ".bat" if is_windows else ".sh"
        runner_file = ctx.actions.declare_file(ctx.label.name + "_runner" + runner_ext)
        vstest_path = toolchain.vstest_dll.path if hasattr(toolchain, "vstest_dll") and toolchain.vstest_dll else ""
        dotnet_path = toolchain.dotnet_muxer.path
        test_filter = getattr(ctx.attr, "test_filter", "")

        coverage_script = None
        if is_windows and coverlet_dll:
            # cmd can't rewrite the LCOV paths, so a PowerShell script next to the runner runs Coverlet.
            coverage_script = ctx.actions.declare_file(ctx.label.name + "_coverage.ps1")
            ctx.actions.write(output = coverage_script, content = _WINDOWS_COVERAGE_PS1)
            runfiles_files.append(coverage_script)
            extra_output_files.append(coverage_script)

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
rem Processes started in the same second draw the same %RANDOM%, so retry until mkdir makes a new directory.
set SCRATCH_TRIES=0
:make_scratch
set /a SCRATCH_TRIES+=1
set SCRATCH=%TEMP%\\.dotnet_scratch_%RANDOM%
mkdir "%SCRATCH%" 2>nul || if !SCRATCH_TRIES! lss 100 goto make_scratch
set DOTNET_CLI_HOME=%SCRATCH%
set HOME=%SCRATCH%
set USERPROFILE=%SCRATCH%
set APPDATA=%SCRATCH%

set DOTNET_BIN=%SCRIPT_DIR%{dotnet_bin}
set VSTEST_DLL=%SCRIPT_DIR%vstest.console.dll
set EXE_PATH=%SCRIPT_DIR%{exe_name}
set MAIN_DLL_PATH=%SCRIPT_DIR%{main_dll_name}
set LAUNCHER_DLL=%SCRIPT_DIR%{launcher_name}
set RUNTIMECONFIG=%SCRIPT_DIR%{runtimeconfig_name}

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
            if "!R_KEY:~-{launcher_len}!"=="{launcher_name}" (
                if exist "%%B" set "LAUNCHER_DLL=%%B"
            )
            if "!R_KEY:~-{runtimeconfig_len}!"=="{runtimeconfig_name}" (
                if exist "%%B" set "RUNTIMECONFIG=%%B"
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

rem Read the filter with delayed expansion so an exclamation mark in it stays put.
set "FILTER=!TESTBRIDGE_TEST_ONLY!"
if "!FILTER!"=="" set "FILTER={test_filter}"
if defined COVERAGE_DIR if exist "%SCRIPT_DIR%{coverage_script}" if not "{coverlet_dll}"=="" (
    powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%SCRIPT_DIR%{coverage_script}" "!DOTNET_BIN!" "!MAIN_DLL_PATH!" "!VSTEST_DLL!" "!LAUNCHER_DLL!" "!RUNTIMECONFIG!" "{target_type}" %*
    set EXIT_CODE=!ERRORLEVEL!
    rmdir /s /q "%SCRATCH%" 2>nul
    exit /b !EXIT_CODE!
)
if "{target_type}"=="library" (
    "!DOTNET_BIN!" exec --runtimeconfig "!RUNTIMECONFIG!" "!LAUNCHER_DLL!" "!VSTEST_DLL!" "!MAIN_DLL_PATH!" "!FILTER!" %*
) else (
    if not "!FILTER!"=="" set "TESTBRIDGE_TEST_ONLY=!FILTER!"
    "!EXE_PATH!" %*
)
set EXIT_CODE=%ERRORLEVEL%
rmdir /s /q "%SCRATCH%" 2>nul
exit /b %EXIT_CODE%
""".format(
                coverage_script = coverage_script.basename if coverage_script else "",
                coverlet_dll = coverlet_dll,
                dotnet_bin = toolchain.dotnet_muxer.basename,
                dotnet_bin_len = len(toolchain.dotnet_muxer.basename),
                dotnet_path = dotnet_path,
                exe_name = exe_file.basename,
                exe_name_len = len(exe_file.basename),
                launcher_len = len(ctx.attr._vstest_launcher[CSharpInfo].runtime_dll.basename),
                launcher_name = ctx.attr._vstest_launcher[CSharpInfo].runtime_dll.basename,
                main_dll_len = len(main_dll.basename),
                main_dll_name = main_dll.basename,
                runtimeconfig_len = len(runtimeconfig_json.basename),
                runtimeconfig_name = runtimeconfig_json.basename,
                target_type = target_type,
                # The line also expands !FILTER!, so cmd reads ^ and ! as escapes in it.
                test_filter = test_filter.replace("%", "%%").replace("^", "^^").replace("!", "^!"),
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
LAUNCHER_DLL="$DIR/{launcher_name}"
RUNTIMECONFIG="$DIR/{runtimeconfig_name}"

if [ ! -f "$DOTNET_BIN" ] && [ -n "${{RUNFILES_MANIFEST_FILE:-}}" ] && [ -f "$RUNFILES_MANIFEST_FILE" ]; then
    while read -r rpath target; do
        case "$rpath" in
            *{dotnet_bin}) [ -f "$target" ] && DOTNET_BIN="$target" ;;
            *vstest.console.dll) [ -f "$target" ] && VSTEST_DLL="$target" ;;
            *{exe_name}) [ -f "$target" ] && EXE_PATH="$target" ;;
            *{main_dll_name}) [ -f "$target" ] && MAIN_DLL_PATH="$target" ;;
            *{launcher_name}) [ -f "$target" ] && LAUNCHER_DLL="$target" ;;
            *{runtimeconfig_name}) [ -f "$target" ] && RUNTIMECONFIG="$target" ;;
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
    set -- exec --runtimeconfig "$RUNTIMECONFIG" "$LAUNCHER_DLL" "$VSTEST_DLL" "$MAIN_DLL_PATH" "$FILTER" "$@"
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
                launcher_name = ctx.attr._vstest_launcher[CSharpInfo].runtime_dll.basename,
                main_dll_name = main_dll.basename,
                runtimeconfig_name = runtimeconfig_json.basename,
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
    ).merge(library_runfiles(ctx, list(ctx.attr.deps) + list(ctx.attr.exports)))

    providers = [
        DefaultInfo(
            executable = executable_file,
            files = depset([executable_file, main_dll, pdb, runtimeconfig_json, deps_json] + ([csharp_info.xml_doc] if csharp_info.xml_doc else []) + extra_output_files),
            runfiles = runfiles,
        ),
        csharp_info,
    ] + [p for p in compile_providers if type(p) == "InstrumentedFilesInfo"]

    # The apphost template comes from the newest SDK, so the runtime's repository is the owner of its files.
    runtime_owner = toolchain.runtime_pack.to_list()[0].owner
    pack_ws = getattr(runtime_owner, "workspace_name", "") or getattr(runtime_owner, "repo_name", "")
    dotnet_root_rel = "../" + pack_ws if pack_ws else toolchain.dotnet_muxer.dirname

    if is_test:
        test_env = dict(toolchain.dotnet_env) if hasattr(toolchain, "dotnet_env") and toolchain.dotnet_env else dict(SEALED_DOTNET_ENV)
        for k, v in ctx.attr.env.items():
            test_env[k] = ctx.expand_location(v, targets = ctx.attr.data + ctx.attr.deps)
        test_env["DOTNET_ROOT"] = dotnet_root_rel
        providers.append(
            testing.TestEnvironment(
                environment = test_env,
                inherited_environment = list(getattr(ctx.attr, "env_inherit", [])),
            ),
        )
    else:
        # The apphost finds the runtime through DOTNET_ROOT, so bazel run needs it too.
        run_dotnet_root = dotnet_root_rel
        if is_windows:
            # Windows has no runfiles tree by default, and then bazel run starts in <exe>.runfiles
            # instead of <exe>.runfiles/<workspace>. Windows resolves ".." without touching the disk,
            # so going through <workspace>/.. reaches the execroot from either one.
            run_dotnet_root = ctx.workspace_name + "/" + "../" * (len(exe_file.path.split("/")) + 1) + runtime_owner.workspace_root
        # The web and worker hosts default the content root to the working directory, which bazel run
        # sets to the runfiles root. "." resolves against the app's own directory, where content lands.
        run_env = {"DOTNET_CONTENTROOT": "."} if ctx.attr.sdk != "Microsoft.NET.Sdk" else {}
        for k, v in ctx.attr.env.items():
            run_env[k] = ctx.expand_location(v, targets = ctx.attr.data + ctx.attr.deps)
        run_env["DOTNET_ROOT"] = run_dotnet_root
        providers.append(RunEnvironmentInfo(environment = run_env))

    return providers

# Runs a test under Coverlet on Windows and writes Bazel's coverlet.dat. Mirrors the sh runner.
_WINDOWS_COVERAGE_PS1 = """param($Dotnet, $MainDll, $Vstest, $Launcher, $RuntimeConfig, $TargetType)
$ErrorActionPreference = "Stop"
# The filter comes from the runner's environment, so an empty one can't shift the arguments after it.
$Filter = $env:FILTER

function Quote([string]$a) {
    '"' + ($a -replace '(\\\\*)"', '$1$1\\"' -replace '(\\\\+)$', '$1$1') + '"'
}

# Coverlet instruments assemblies in place, so run from a writable copy.
$src = Split-Path -Parent $MainDll
$app = Join-Path $env:SCRATCH "app"
New-Item -ItemType Directory -Force -Path $app | Out-Null
Get-ChildItem -LiteralPath $src -File | Where-Object { (".dll", ".pdb", ".json" -contains $_.Extension) -and $_.Name -ne "vstest.console.dll" } | ForEach-Object {
    $dest = Join-Path $app $_.Name
    Copy-Item -LiteralPath $_.FullName -Destination $dest
    (Get-Item -LiteralPath $dest).IsReadOnly = $false
}
$appDll = Join-Path $app (Split-Path -Leaf $MainDll)

$target = @("exec")
if ($TargetType -eq "library") {
    $target += @("--runtimeconfig", $RuntimeConfig, $Launcher, $Vstest, $appDll, $Filter)
    $target += $args
} else {
    if ($Filter) { $env:TESTBRIDGE_TEST_ONLY = $Filter }
    $target += $appDll
    $target += $args
}

$info = Join-Path $env:SCRATCH "coverlet.info"
$coverlet = @(
    "exec", "--roll-forward", "LatestMajor", (Join-Path $src "coverlet\\coverlet.console.dll"), $appDll,
    "--target", $Dotnet, "--targetargs", (($target | ForEach-Object { Quote $_ }) -join " "),
    "--exclude-assemblies-without-sources", "None", "--include-test-assembly",
    "--format", "lcov", "--output", $info
)
$psi = New-Object System.Diagnostics.ProcessStartInfo $Dotnet
$psi.Arguments = ($coverlet | ForEach-Object { Quote $_ }) -join " "
$psi.UseShellExecute = $false
$process = [System.Diagnostics.Process]::Start($psi)
$process.WaitForExit()

# Coverlet reports the absolute paths the compiler saw. Map each to its exec path in the manifest.
$srcs = @(Get-Content -LiteralPath $env:COVERAGE_MANIFEST | Where-Object { $_ })
$lines = foreach ($line in [System.IO.File]::ReadAllLines($info)) {
    if ($line.StartsWith("SF:")) {
        $p = $line.Substring(3).Replace("\\", "/")
        $best = ""
        foreach ($s in $srcs) {
            if ($s.Length -gt $best.Length -and ($p -eq $s -or $p.EndsWith("/" + $s))) { $best = $s }
        }
        if ($best) { $line = "SF:" + $best }
    }
    $line
}
[System.IO.File]::WriteAllText((Join-Path $env:COVERAGE_DIR "coverlet.dat"), (($lines -join "`n") + "`n"))
exit $process.ExitCode
"""

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
    "additional_compiler_options": attr.string_list(
        default = [],
        doc = ADDITIONAL_COMPILER_OPTIONS_DOC,
    ),
    "allow_unsafe_blocks": attr.bool(
        default = False,
        doc = ALLOW_UNSAFE_BLOCKS_DOC,
    ),
    "data": attr.label_list(
        allow_files = True,
        default = [],
        doc = DATA_DOC,
    ),
    "defines": attr.string_list(
        default = [],
        doc = DEFINES_DOC,
    ),
    "deps": attr.label_list(
        default = [],
        doc = "Direct dependency libraries.",
        providers = [[CSharpInfo]],
    ),
    "editorconfig_files": attr.label_list(
        allow_files = True,
        default = [],
        doc = EDITORCONFIG_FILES_DOC,
    ),
    "env": attr.string_dict(
        default = {},
        doc = "Environment variables for `bazel run` of a binary and `bazel test` of a test. Values expand `$(rlocationpath)` and the other location functions for labels in `data` and `deps`.",
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
        doc = "Static files placed next to the assembly at their path relative to their package, so " +
              "`wwwroot/css/app.css` lands at `wwwroot/css/app.css`. Same as MSBuild `Content` items " +
              "with `CopyToOutputDirectory`. Use `copy_to_output` to pick another path.",
    ),
    "copy_to_output": attr.label_keyed_string_dict(
        allow_files = True,
        default = {},
        doc = "Files mapped to destination output paths.",
    ),
    "framework_references": attr.string_list(
        default = [],
        doc = FRAMEWORK_REFERENCES_DOC,
    ),
    "generate_assembly_info": attr.bool(
        default = True,
        doc = "Synthesize assembly information attributes.",
    ),
    "generate_documentation_file": attr.bool(
        default = False,
        doc = GENERATE_DOCUMENTATION_FILE_DOC,
    ),
    "implicit_usings": attr.bool(
        default = True,
        doc = "Synthesize implicit global usings namespace imports.",
    ),
    "internals_visible_to": attr.string_list(
        default = [],
        doc = INTERNALS_VISIBLE_TO_DOC,
    ),
    "langversion": attr.string(
        default = "latest",
        doc = "Target C# language version specification.",
    ),
    "output_assembly": attr.string(
        default = "",
        doc = OUTPUT_ASSEMBLY_DOC,
    ),
    "plugins": attr.label_list(
        default = [],
        doc = "Roslyn analyzer and generator plugins.",
        providers = [[CSharpAnalyzerInfo]],
    ),
    "resources": attr.label_keyed_string_dict(
        allow_files = True,
        default = {},
        doc = RESOURCES_DOC,
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
        doc = SDK_DOC,
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
        doc = TARGET_FRAMEWORK_DOC,
        values = [""] + TARGET_FRAMEWORKS,
    ),
    "target_type": attr.string(
        default = "exe",
        doc = "Compiler target type output flag.",
    ),
}

csharp_binary = rule(
    doc = """Compiles a C# executable and stamps the native application host binary.

The app runs on the toolchain's .NET runtime without an installed .NET, under `bazel run`, as a tool in
`genrule`, `run_binary` or another rule's action, and straight from `bazel-bin`, on every platform and
for every `target_framework`. The binary's `<name>_/dotnet` directory is a link to that runtime, and the
apphost looks there and nowhere else, so `DOTNET_ROOT` and an installed .NET never matter. The
apphost comes from the newest configured SDK, which must be .NET 9 or later. `deps.json` and
`runtimeconfig.json` stay framework dependent. A copy of the binary outside `bazel-bin` needs its
`<name>_` directory with it.

With `sdk` set to `Microsoft.NET.Sdk.Web` or `Microsoft.NET.Sdk.Worker`, `bazel run` also sets `DOTNET_CONTENTROOT`
to the app's own directory, where `content` files land, so `appsettings.json` and `wwwroot` load as they
do from a `dotnet publish` folder. A value in `env`, or a content root the app sets itself, wins.
""",
    implementation = _csharp_binary_impl,
    attrs = _BINARY_ATTRS,
    cfg = target_framework_transition,
    executable = True,
    toolchains = ["@rules_csharp//csharp:toolchain_type"],
)

_TEST_ATTRS = dict(_BINARY_ATTRS)
_TEST_ATTRS.update({
    "target_type": attr.string(
        default = "exe",
        doc = "`\"exe\"` runs the program's `Main` as the test. `\"library\"` runs the assembly's tests under VSTest.",
    ),
    "_vstest_launcher": attr.label(
        default = Label("//csharp/private/tools:vstest_launcher"),
        doc = "Runs library mode tests under vstest, sharded, with JUnit results.",
        providers = [CSharpInfo],
    ),
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
    "env_inherit": attr.string_list(
        default = [],
        doc = "Environment variables inherited from client environment.",
    ),
    "test_filter": attr.string(
        default = "",
        doc = "Default test filter, overridden by `--test_filter`. In library mode it is a VSTest " +
              "[filter](https://learn.microsoft.com/dotnet/core/testing/selective-unit-tests), such as " +
              "`TestCategory=Fast` or `FullyQualifiedName~Parser`.",
    ),
})

csharp_test = rule(
    doc = """Compiles and executes a C# test binary under the Bazel test harness.

A test runs in one of two ways, picked by `target_type`:

- `"exe"` (the default) builds a program and runs its `Main`. A nonzero exit code fails the test.
  The program owns everything else: it gets `test_filter` in `TESTBRIDGE_TEST_ONLY`, and with
  `shard_count` it reads `TEST_TOTAL_SHARDS` and `TEST_SHARD_INDEX` and must touch
  `TEST_SHARD_STATUS_FILE`. It may write JUnit XML to `XML_OUTPUT_FILE`.
- `"library"` builds a test assembly and runs it under VSTest, the runner behind `dotnet test`.
  Depend on `Microsoft.NET.Test.Sdk` and a test framework with its adapter from NuGet, such as
  `MSTest.TestFramework` with `MSTest.TestAdapter` or `xunit` with `xunit.runner.visualstudio`.
  The rule finds the adapter, fails when no test runs, splits the test cases across `shard_count`
  shards, and writes one `<testcase>` per test to `test.xml`.

`bazel coverage` reports line, branch, and method coverage of instrumented C# sources, collected with
[Coverlet](https://github.com/coverlet-coverage/coverlet) and merged by Bazel into LCOV. That's the code a
test depends on, in both modes. Add `--instrument_test_targets` to count the test's own sources too. CI
checks coverage on Linux, macOS and Windows. On Windows it needs Bazel 9 or later, since older Bazel can't start its
coverage wrapper there.
""",
    implementation = _csharp_test_impl,
    attrs = _TEST_ATTRS,
    cfg = target_framework_transition,
    executable = True,
    test = True,
    toolchains = ["@rules_csharp//csharp:toolchain_type"],
)


