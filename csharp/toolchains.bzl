"""Toolchain definitions and repository rules for rules_csharp."""

load(
    "@bazel_tools//tools/build_defs/repo:utils.bzl",
    "read_netrc",
    "read_user_netrc",
    "use_netrc",
)

# SRI integrity of each built-in SDK archive, by version and runtime identifier.
DOTNET_ARTIFACTS = {
    "8.0.403": {
        "linux-arm64": "sha256-5rU53mNLXEDYZjHl41SIr22+aCIp42c3UmHGNa1ejLA=",
        "linux-x64": "sha256-98MfE5dESquRr7742KRuNlMUQ/rO1g+p1AcM8VqBslY=",
        "osx-arm64": "sha256-8iVXW0Sx9JrMDFi+kq0/T/bnuPT0NJeUR4wrJtdRywU=",
        "osx-x64": "sha256-dMsEfqhP1xfQN5a0nmry4Z5Y2Xb65hVxCYURBs/pnF4=",
        "win-x64": "sha256-xFlVCj3Hfjoq821b+INnRmA/cvyg5sFCy/JT1LwfC8c=",
    },
    "9.0.200": {
        "linux-arm64": "sha256-MmYEWpuKU2LcoOFIomM4XprpSSDW8vVoAq0tWZaYi6s=",
        "linux-x64": "sha256-wHKBoKu9LDIA5w/JTTdLrq37tDycP+kMYDglNVW4QzU=",
        "osx-arm64": "sha256-Pz7z60V/QIUozjYkwQg6NdMtMKQ+Vw4uzbXyGIw6NXY=",
        "osx-x64": "sha256-nHHaP/zJviknMHLK44J8Aci4FCr2oTIvyODhHAky0sQ=",
        "win-x64": "sha256-5JPKfoBRdyyrR6++1TgbVe1QAZ0ET5ERyEv26DAGLYg=",
    },
    "10.0.100": {
        "linux-arm64": "sha256-tkJa7vYAmi1Ce/YAos0C+d1qxgjmutAh/S+C9oWRR5M=",
        "linux-x64": "sha256-qWMcxr+tDvFnODrGVLVCVLrZWm+0tvQwn6ePVYBV5jc=",
        "osx-arm64": "sha256-cbOBXvjYOmu+v4YnpWY5YAGT8i1OpqbeL3GFXEs+Y/0=",
        "osx-x64": "sha256-2P1uPy45PK0wB5TUOuJtAfnbMTVslTgbz7nT1/ZtGH4=",
        "win-x64": "sha256-zgm2BjfFJaXM0zaJYtyTbfEBQdOX4wX1QGMY9h2mZwk=",
    },
}

PLATFORMS = {
    "darwin_arm64": {
        "apphost_name": "apphost",
        "archive_ext": "tar.gz",
        "cpu": "@platforms//cpu:aarch64",
        "os": "@platforms//os:osx",
        "rid": "osx-arm64",
    },
    "darwin_x86_64": {
        "apphost_name": "apphost",
        "archive_ext": "tar.gz",
        "cpu": "@platforms//cpu:x86_64",
        "os": "@platforms//os:osx",
        "rid": "osx-x64",
    },
    "linux_arm64": {
        "apphost_name": "apphost",
        "archive_ext": "tar.gz",
        "cpu": "@platforms//cpu:aarch64",
        "os": "@platforms//os:linux",
        "rid": "linux-arm64",
    },
    "linux_x86_64": {
        "apphost_name": "apphost",
        "archive_ext": "tar.gz",
        "cpu": "@platforms//cpu:x86_64",
        "os": "@platforms//os:linux",
        "rid": "linux-x64",
    },
    "windows_x86_64": {
        "apphost_name": "apphost.exe",
        "archive_ext": "zip",
        "cpu": "@platforms//cpu:x86_64",
        "os": "@platforms//os:windows",
        "rid": "win-x64",
    },
}

def version_to_tfm(version):
    """Derives target framework moniker from SDK version."""
    major = version.split(".")[0]
    return "net" + major + ".0"

def _version_key(version):
    return [int(p) for p in version.split(".")]

def merge_dotnet_versions(root_versions, dep_versions):
    """Adds the SDKs dependencies ask for to the root module's SDKs.

    The root's version wins for each target framework it lists. For the others the
    newest version any dependency asks for wins, the way Bazel picks module versions.

    Args:
      root_versions: SDK versions of the root module.
      dep_versions: SDK versions of every dependency module, in any order.

    Returns:
      root_versions followed by one dependency version per target framework the root lacks.
    """
    root_tfms = [version_to_tfm(v) for v in root_versions]
    extra = {}
    for v in dep_versions:
        tfm = version_to_tfm(v)
        if tfm not in root_tfms and (tfm not in extra or _version_key(v) > _version_key(extra[tfm])):
            extra[tfm] = v
    return root_versions + sorted(extra.values(), key = _version_key)

def _resolve_netrc_auth(repository_ctx, urls):
    if repository_ctx.attr.netrc:
        netrc_data = read_netrc(repository_ctx, repository_ctx.attr.netrc)
    elif "NETRC" in repository_ctx.os.environ:
        netrc_data = read_netrc(repository_ctx, repository_ctx.os.environ["NETRC"])
    else:
        netrc_data = read_user_netrc(repository_ctx)
    auth_patterns = repository_ctx.attr.auth_patterns if hasattr(repository_ctx.attr, "auth_patterns") else {}
    return use_netrc(netrc_data, urls, auth_patterns)

def _host_rid(repository_ctx):
    name = repository_ctx.os.name.lower()
    if name.startswith("mac") or name.startswith("darwin"):
        os = "osx"
    elif name.startswith("windows"):
        os = "win"
    else:
        os = "linux"
    cpu = "arm64" if repository_ctx.os.arch.lower() in ("aarch64", "arm64") else "x64"
    return os + "-" + cpu

def _sdk_exec_impl(repository_ctx):
    version = repository_ctx.attr.dotnet_version
    rid = repository_ctx.attr.rid
    ext = repository_ctx.attr.archive_ext
    archive = "dotnet-sdk-{}-{}.{}".format(version, rid, ext)

    urls = list(repository_ctx.attr.urls)
    if not urls:
        urls = ["https://dotnetcli.azureedge.net/dotnet/Sdk/{}/{}".format(version, archive)]

    auth = _resolve_netrc_auth(repository_ctx, urls)
    type_ext = "zip" if ext == "zip" else "tar.gz"

    integrity = repository_ctx.attr.integrity if hasattr(repository_ctx.attr, "integrity") and repository_ctx.attr.integrity else ""
    sha256 = repository_ctx.attr.sha256 if hasattr(repository_ctx.attr, "sha256") and repository_ctx.attr.sha256 else ""

    if not integrity and not sha256:
        integrity = DOTNET_ARTIFACTS.get(version, {}).get(rid, "")

    if not integrity and not sha256:
        fail("No checksum for {}. Add it to sdk_checksums on the csharp.toolchain tag.".format(archive))

    download_kwargs = {
        "auth": auth,
        "type": type_ext,
        "url": urls,
    }
    if integrity:
        download_kwargs["integrity"] = integrity
    elif sha256:
        download_kwargs["sha256"] = sha256

    repository_ctx.download_and_extract(**download_kwargs)

    is_windows = "win" in rid
    dotnet_bin = "dotnet.exe" if is_windows else "dotnet"
    worker_name = "CscWorker.bat" if is_windows else "CscWorker"

    # Keep CscWorker.dll byte-identical across output bases so CSharpCompile
    # actions share the remote and disk cache. Absolute -r: paths and an
    # absolute source path embed the output base into the DLL (PE timestamp
    # and MVID) even with matching sources.
    # https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/compiler-options/advanced#deterministic
    worker_src = repository_ctx.path(Label("//csharp/private/tools:CscWorker.cs"))

    # Refetch when CscWorker.cs changes, such as on a rules_csharp upgrade.
    repository_ctx.watch(worker_src)
    repository_ctx.symlink(worker_src, "CscWorker.cs")
    repository_ctx.file("CscWorker.runtimeconfig.json", """{
  "runtimeOptions": {
    "tfm": "net8.0",
    "rollForward": "LatestMajor",
    "framework": {
      "name": "Microsoft.NETCore.App",
      "version": "8.0.0"
    }
  }
}""")

    csc_candidates = []
    sdk_dir = repository_ctx.path("sdk")
    if sdk_dir.exists:
        for v_dir in sdk_dir.readdir():
            cand = v_dir.get_child("Roslyn").get_child("bincore").get_child("csc.dll")
            if cand.exists:
                csc_candidates.append(cand)

    ref_dlls = []
    packs_dir = repository_ctx.path("packs/Microsoft.NETCore.App.Ref")
    if packs_dir.exists:
        for v_dir in packs_dir.readdir():
            ref_sub = v_dir.get_child("ref")
            if ref_sub.exists:
                for tfm_dir in ref_sub.readdir():
                    for f in tfm_dir.readdir():
                        if f.basename.endswith(".dll"):
                            # Repo-relative so the argv (and thus the DLL) does
                            # not depend on the absolute output path.
                            rel = "packs/Microsoft.NETCore.App.Ref/{}/{}/{}/{}".format(
                                v_dir.basename,
                                "ref",
                                tfm_dir.basename,
                                f.basename,
                            )
                            ref_dlls.append("-r:" + rel)

    if not csc_candidates:
        fail("No sdk/*/Roslyn/bincore/csc.dll in the .NET SDK archive " + archive)
    csc_path = str(csc_candidates[0])

    # The host can only run its own dotnet, so only the host's SDK builds CscWorker.dll. An exec platform
    # with another OS or CPU runs remotely, where there is no local worker, and the toolchain hub gives it
    # no csc_worker. Its wrapper still exists for the exported label and runs csc.dll directly.
    is_host = rid == _host_rid(repository_ctx)
    if is_host:
        if not ref_dlls:
            fail("No packs/Microsoft.NETCore.App.Ref/*/ref/*/*.dll in the .NET SDK archive " + archive)
        dotnet_path = str(repository_ctx.path(dotnet_bin))
        compile_cmd = [
            dotnet_path,
            "exec",
            csc_path,
            "-target:exe",
            "-out:CscWorker.dll",
            "-noconfig",
            "-nostdlib+",
            "-deterministic+",
        ] + ref_dlls + ["CscWorker.cs"]
        # cwd is the repository root, so relative -r: and CscWorker.cs resolve.
        result = repository_ctx.execute(compile_cmd)
        if result.return_code != 0:
            fail("Compiling CscWorker.cs failed with exit code {}:\n{}{}".format(result.return_code, result.stdout, result.stderr))
    csc_rel = "sdk/{}/Roslyn/bincore/csc.dll".format(csc_candidates[0].dirname.dirname.dirname.basename)

    if is_host:
        bat_run = '"%SCRIPT_DIR%dotnet.exe" exec "%SCRIPT_DIR%CscWorker.dll" %*'
        sh_run = 'exec "$SCRIPT_DIR/dotnet" exec "$SCRIPT_DIR/CscWorker.dll" "$@"'
    else:
        bat_run = """set ARGS=
:loop
if "%~1"=="" goto :run
if not "%~1"=="--persistent_worker" set ARGS=%ARGS% "%~1"
shift
goto :loop
:run
"%SCRIPT_DIR%dotnet.exe" exec "%SCRIPT_DIR%{csc}" %ARGS%""".replace("{csc}", csc_rel.replace("/", "\\"))
        sh_run = """ARGS=()
for arg in "$@"; do
    [ "$arg" = "--persistent_worker" ] || ARGS+=("$arg")
done
exec "$SCRIPT_DIR/dotnet" exec "$SCRIPT_DIR/{csc}" "${ARGS[@]}\"""".replace("{csc}", csc_rel)

    if is_windows:
        repository_ctx.file(
            worker_name,
            content = """@echo off
setlocal
set SCRIPT_DIR=%~dp0
set DOTNET_ROOT=%SCRIPT_DIR%
set DOTNET_MULTILEVEL_LOOKUP=0
set DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
set DOTNET_CLI_TELEMETRY_OPTOUT=1
set DOTNET_NOLOGO=1
set VBCSCOMPILER_TTL=0
set MSBUILDDISABLENODEREUSE=1
set DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
{run}
exit /b %ERRORLEVEL%
""".replace("{run}", bat_run),
            executable = True,
        )
    else:
        repository_ctx.file(
            worker_name,
            content = """#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTNET_ROOT="$SCRIPT_DIR"
export DOTNET_MULTILEVEL_LOOKUP=0
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1
export VBCSCOMPILER_TTL=0
export MSBUILDDISABLENODEREUSE=1
export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
{run}
""".replace("{run}", sh_run),
            executable = True,
        )

    build_content = """package(default_visibility = ["//visibility:public"])

exports_files(["{dotnet_bin}", "{worker_name}", "CscWorker.dll", "CscWorker.runtimeconfig.json"])

filegroup(
    name = "dotnet_muxer",
    srcs = ["{dotnet_bin}"],
)

filegroup(
    name = "csc_worker",
    srcs = ["{worker_name}"],
)

filegroup(
    name = "csc_worker_files",
    srcs = glob([
        "CscWorker.dll",
        "CscWorker.runtimeconfig.json",
        "{dotnet_bin}",
        "host/**",
        "shared/**",
        "sdk/*/Roslyn/bincore/**",
    ], allow_empty = True),
)

# What the SDK dotnet needs to run a framework-dependent app, such as the apphost patcher.
filegroup(
    name = "dotnet_runtime_files",
    srcs = glob([
        "{dotnet_bin}",
        "host/fxr/**",
        "shared/Microsoft.NETCore.App/**",
    ], allow_empty = True),
)

filegroup(
    name = "csc_dll",
    srcs = glob(["sdk/*/Roslyn/bincore/csc.dll"]),
)

filegroup(
    name = "vstest_dll",
    srcs = glob(["sdk/*/vstest.console.dll"]),
)

# vstest.console.dll loads its siblings, its extensions and testhost from its own directory.
filegroup(
    name = "vstest_files",
    srcs = glob([
        "sdk/*/vstest.console*",
        "sdk/*/testhost*",
        "sdk/*/Microsoft.TestPlatform.*",
        "sdk/*/Microsoft.VisualStudio.TestPlatform.*",
        "sdk/*/Microsoft.Extensions.DependencyModel.dll",
        "sdk/*/Microsoft.Extensions.FileSystemGlobbing.dll",
        "sdk/*/Newtonsoft.Json.dll",
        "sdk/*/Extensions/**",
        "sdk/*/*/vstest.console.resources.dll",
        "sdk/*/*/Microsoft.TestPlatform.*.resources.dll",
        "sdk/*/*/Microsoft.VisualStudio.TestPlatform.*.resources.dll",
    ], allow_empty = True),
)

filegroup(
    name = "sdk_files",
    srcs = glob(["**/*"]),
)
""".format(dotnet_bin = dotnet_bin, worker_name = worker_name)

    repository_ctx.file("BUILD.bazel", build_content)

sdk_exec = repository_rule(
    doc = "Downloads and extracts host .NET SDK binaries.",
    implementation = _sdk_exec_impl,
    attrs = {
        "archive_ext": attr.string(
            default = "tar.gz",
            doc = "Archive file extension string.",
        ),
        "auth_patterns": attr.string_dict(
            doc = "Host to authentication pattern mappings.",
        ),
        "dotnet_version": attr.string(
            doc = ".NET SDK version string.",
            mandatory = True,
        ),
        "integrity": attr.string(
            doc = "Expected Subresource Integrity hash string.",
        ),
        "netrc": attr.label(
            doc = "Authentication netrc configuration file label.",
        ),
        "platform": attr.string(
            doc = "Platform moniker string.",
            mandatory = True,
        ),
        "rid": attr.string(
            doc = "Runtime identifier string.",
            mandatory = True,
        ),
        "sha256": attr.string(
            doc = "Expected SHA-256 integrity hash string.",
        ),
        "urls": attr.string_list(
            doc = "Ordered candidate download URL list.",
        ),
    },
)

def _runtime_pack_impl(repository_ctx):
    version = repository_ctx.attr.dotnet_version
    rid = repository_ctx.attr.rid
    ext = repository_ctx.attr.archive_ext
    archive = "dotnet-sdk-{}-{}.{}".format(version, rid, ext)

    urls = list(repository_ctx.attr.urls)
    if not urls:
        urls = ["https://dotnetcli.azureedge.net/dotnet/Sdk/{}/{}".format(version, archive)]

    auth = _resolve_netrc_auth(repository_ctx, urls)
    type_ext = "zip" if ext == "zip" else "tar.gz"

    integrity = repository_ctx.attr.integrity if hasattr(repository_ctx.attr, "integrity") and repository_ctx.attr.integrity else ""
    sha256 = repository_ctx.attr.sha256 if hasattr(repository_ctx.attr, "sha256") and repository_ctx.attr.sha256 else ""

    if not integrity and not sha256:
        integrity = DOTNET_ARTIFACTS.get(version, {}).get(rid, "")

    if not integrity and not sha256:
        fail("No checksum for {}. Add it to sdk_checksums on the csharp.toolchain tag.".format(archive))

    download_kwargs = {
        "auth": auth,
        "type": type_ext,
        "url": urls,
    }
    if integrity:
        download_kwargs["integrity"] = integrity
    elif sha256:
        download_kwargs["sha256"] = sha256

    repository_ctx.download_and_extract(**download_kwargs)

    is_windows = "win" in rid
    apphost_name = "apphost.exe" if is_windows else "apphost"

    build_content = """package(default_visibility = ["//visibility:public"])

filegroup(
    name = "ref_pack",
    srcs = glob(["packs/Microsoft.NETCore.App.Ref/*/ref/*/*.dll"]),
)

filegroup(
    name = "aspnetcore_ref_pack",
    srcs = glob(["packs/Microsoft.AspNetCore.App.Ref/*/ref/*/*.dll"]),
)

filegroup(
    name = "host_pack",
    srcs = glob(["packs/Microsoft.NETCore.App.Host.{rid}/*/runtimes/{rid}/native/{apphost_name}"], allow_empty = True),
)

filegroup(
    name = "runtime_pack",
    srcs = glob([
        "shared/Microsoft.NETCore.App/**",
        "shared/Microsoft.AspNetCore.App/**",
        "host/fxr/**",
    ], allow_empty = True),
)

filegroup(
    name = "all_files",
    srcs = glob(["**/*"]),
)
""".format(apphost_name = apphost_name, rid = rid)

    repository_ctx.file("BUILD.bazel", build_content)

runtime_pack = repository_rule(
    doc = "Downloads and extracts target platform reference and runtime packs.",
    implementation = _runtime_pack_impl,
    attrs = {
        "archive_ext": attr.string(
            default = "tar.gz",
            doc = "Archive file extension string.",
        ),
        "auth_patterns": attr.string_dict(
            doc = "Host to authentication pattern mappings.",
        ),
        "dotnet_version": attr.string(
            doc = ".NET SDK version string.",
            mandatory = True,
        ),
        "integrity": attr.string(
            doc = "Expected Subresource Integrity hash string.",
        ),
        "netrc": attr.label(
            doc = "Authentication netrc configuration file label.",
        ),
        "platform": attr.string(
            doc = "Platform moniker string.",
            mandatory = True,
        ),
        "rid": attr.string(
            doc = "Runtime identifier string.",
            mandatory = True,
        ),
        "sha256": attr.string(
            doc = "Expected SHA-256 integrity hash string.",
        ),
        "urls": attr.string_list(
            doc = "Ordered candidate download URL list.",
        ),
    },
)

def _csharp_toolchains_hub_impl(repository_ctx):
    lines = [
        "load(\"@rules_csharp//csharp/private:toolchain_impl.bzl\", \"csharp_toolchain\")",
        "package(default_visibility = [\"//visibility:public\"])",
        "",
    ]

    versions = repository_ctx.attr.dotnet_versions
    newest = max(versions, key = _version_key)
    default = repository_ctx.attr.default_version or newest

    # Binaries search only the dotnet directory next to the app, an option that the apphost of .NET 9
    # and later carries. Every target framework stamps that apphost, net8.0 included.
    if int(newest.split(".")[0]) < 9:
        fail("csharp.toolchain dotnet_versions needs an SDK of .NET 9 or later, whose apphost csharp_binary stamps for every target_framework. Got: {}.".format(", ".join(versions)))
    newest_slug = newest.replace(".", "_")
    host_rid = _host_rid(repository_ctx)
    for tfm in [""] + [version_to_tfm(v) for v in versions]:
        lines.append("""config_setting(
    name = "target_framework_{name}",
    flag_values = {{"@rules_csharp//csharp/settings:target_framework": "{tfm}"}},
)
""".format(name = tfm or "default", tfm = tfm))

    for version in versions:
        v_slug = version.replace(".", "_")
        tfm = version_to_tfm(version)
        target_settings = [tfm] + (["default"] if version == default else [])

        for exec_p, exec_info in PLATFORMS.items():
            worker_name = "CscWorker.bat" if "win" in exec_info["rid"] else "CscWorker"
            # Only the host's SDK repo builds CscWorker.dll. Other exec platforms compile with csc.dll directly,
            # which still needs the dotnet runtime from csc_worker_files.
            worker_attr = """
    csc_worker = "@dotnet_sdk_{v_slug}_{exec_p}//:{worker_name}",""".format(
                exec_p = exec_p,
                v_slug = v_slug,
                worker_name = worker_name,
            ) if exec_info["rid"] == host_rid else ""
            for target_p, target_info in PLATFORMS.items():
                impl_name = "csharp_toolchain_{}_{}_{}".format(v_slug, exec_p, target_p)
                tc_name = "toolchain_{}_{}_{}".format(v_slug, exec_p, target_p)

                lines.append("""csharp_toolchain(
    name = "{impl_name}",
    dotnet_muxer = "@dotnet_sdk_{v_slug}_{exec_p}//:dotnet_muxer",
    csc_dll = "@dotnet_sdk_{v_slug}_{exec_p}//:csc_dll",{worker_attr}
    csc_worker_files = ["@dotnet_sdk_{v_slug}_{exec_p}//:csc_worker_files"],
    dotnet_runtime_files = ["@dotnet_sdk_{v_slug}_{exec_p}//:dotnet_runtime_files"],
    ref_pack = ["@csharp_pack_{v_slug}_{target_p}//:ref_pack"],
    aspnetcore_ref_pack = ["@csharp_pack_{v_slug}_{target_p}//:aspnetcore_ref_pack"],
    host_pack = "@csharp_pack_{newest_slug}_{target_p}//:host_pack",
    runtime_pack = ["@csharp_pack_{v_slug}_{target_p}//:runtime_pack"],
    target_framework = "{tfm}",
    target_rid = "{target_rid}",
    host_rid = "{host_rid}",
    vstest_dll = "@dotnet_sdk_{v_slug}_{exec_p}//:vstest_dll",
    vstest_files = ["@dotnet_sdk_{v_slug}_{exec_p}//:vstest_files"],
)
""".format(
                    exec_p = exec_p,
                    host_rid = exec_info["rid"],
                    impl_name = impl_name,
                    newest_slug = newest_slug,
                    target_p = target_p,
                    target_rid = target_info["rid"],
                    tfm = tfm,
                    v_slug = v_slug,
                    worker_attr = worker_attr,
                ))

                for setting in target_settings:
                    lines.append("""toolchain(
    name = "{tc_name}",
    toolchain_type = "@rules_csharp//csharp:toolchain_type",
    toolchain = ":{impl_name}",
    exec_compatible_with = [
        "{exec_os}",
        "{exec_cpu}",
    ],
    target_compatible_with = [
        "{target_os}",
        "{target_cpu}",
    ],
    target_settings = [":target_framework_{setting}"],
)
""".format(
                        exec_cpu = exec_info["cpu"],
                        exec_os = exec_info["os"],
                        impl_name = impl_name,
                        setting = setting,
                        target_cpu = target_info["cpu"],
                        target_os = target_info["os"],
                        tc_name = tc_name if setting == tfm else tc_name + "_default",
                    ))

    repository_ctx.file("BUILD.bazel", "\n".join(lines))
    repository_ctx.file("defs.bzl", "DEFAULT_TARGET_FRAMEWORK = \"{}\"\n".format(version_to_tfm(default)))

csharp_toolchains_hub = repository_rule(
    doc = "Generates toolchain target declarations for all platform combinations.",
    implementation = _csharp_toolchains_hub_impl,
    attrs = {
        "default_version": attr.string(
            doc = "SDK version that targets with no target_framework build with. Defaults to the newest in dotnet_versions.",
        ),
        "dotnet_versions": attr.string_list(
            default = ["8.0.403", "9.0.200", "10.0.100"],
            doc = "Supported .NET SDK version strings.",
        ),
    },
)
