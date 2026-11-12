"""Toolchain implementation for rules_csharp."""

load(":providers.bzl", "CSharpToolchainInfo")

SEALED_DOTNET_ENV = {
    "APPDATA": ".dotnet_scratch",
    "DOTNET_CLI_HOME": ".dotnet_scratch",
    "DOTNET_CLI_TELEMETRY_OPTOUT": "1",
    "DOTNET_MULTILEVEL_LOOKUP": "0",
    "DOTNET_NOLOGO": "1",
    "DOTNET_SKIP_FIRST_TIME_EXPERIENCE": "1",
    "DOTNET_SYSTEM_GLOBALIZATION_INVARIANT": "1",
    "HOME": ".dotnet_scratch",
    "MSBUILDDISABLENODEREUSE": "1",
    "USERPROFILE": ".dotnet_scratch",
    "VBCSCOMPILER_TTL": "0",
}

def _msbuild_escape(s):
    """Escapes the characters MSBuild treats as syntax in an item path."""
    for ch, code in [("%", "25"), ("$", "24"), ("@", "40"), (";", "3B"), ("'", "27"), ("(", "28"), (")", "29"), ("*", "2A"), ("?", "3F")]:
        s = s.replace(ch, "%" + code)
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")

def _runtime_layout(files):
    """Maps each shared framework and hostfxr file to its path in a .NET root."""
    layout = {}
    for f in files:
        # short_path of a file in a repository is ../<repo>/<path in the repo>
        rel = f.short_path.split("/", 2)[2] if f.short_path.startswith("../") else f.short_path
        if rel.startswith("shared/") or rel.startswith("host/fxr/"):
            layout[rel] = f
    return layout

def _declare_runtime_tree(ctx, runtime_files):
    """Declares one directory laid out as a .NET root: host/fxr and the shared frameworks.

    The toolchain builds it once per configuration. Every csharp_binary links to it as its
    own `dotnet` directory, so the runtime is part of the binary's outputs and each
    executor stages it with the binary.
    """
    layout = _runtime_layout(runtime_files)
    if not layout:
        return None
    tree = ctx.actions.declare_directory(ctx.label.name + "_dotnet")

    # MSBuild's Copy task makes the directories and copies the same way on every OS, so there is
    # no shell or batch file to depend on. Relative paths resolve from the execroot.
    items = []
    for rel in sorted(layout):
        items.append('    <F Include="{src}" Dest="{rel}" />'.format(
            src = _msbuild_escape(layout[rel].path),
            rel = _msbuild_escape(rel),
        ))
    project = ctx.actions.declare_file(ctx.label.name + "_dotnet.proj")
    ctx.actions.write(project, "\n".join([
        "<Project>",
        "  <ItemGroup>",
    ] + items + [
        "  </ItemGroup>",
        '  <Target Name="Build">',
        "    <Copy SourceFiles=\"@(F->'$(MSBuildStartupDirectory)/%(Identity)')\"",
        "          DestinationFiles=\"@(F->'{out}/%(Dest)')\" />".format(
            out = "$(MSBuildStartupDirectory)/" + _msbuild_escape(tree.path),
        ),
        "  </Target>",
        "</Project>",
        "",
    ]))

    env = dict(SEALED_DOTNET_ENV)
    env["DOTNET_ROOT"] = ctx.file.dotnet_muxer.dirname
    env["DOTNET_CLI_WORKLOAD_UPDATE_NOTIFY_DISABLE"] = "1"
    env["PATH"] = "C:\\Windows\\System32;C:\\Windows" if "win" in ctx.attr.host_rid else "/usr/bin:/bin"
    ctx.actions.run(
        executable = ctx.file.dotnet_muxer,
        arguments = ["msbuild", project.path, "-nologo", "-verbosity:quiet", "-nodeReuse:false", "-maxcpucount:1"],
        inputs = [project] + layout.values(),
        outputs = [tree],
        env = env,
        mnemonic = "CSharpRuntimeTree",
        progress_message = "Laying out the .NET runtime for %{label}",
        use_default_shell_env = False,
    )
    return tree

def _csharp_toolchain_impl(ctx):
    ref_files = []
    if ctx.attr.ref_pack:
        ref_files = ctx.files.ref_pack

    aspnet_files = []
    if ctx.attr.aspnetcore_ref_pack:
        aspnet_files = ctx.files.aspnetcore_ref_pack

    worker_files = []
    if hasattr(ctx.attr, "csc_worker_files") and ctx.attr.csc_worker_files:
        worker_files = ctx.files.csc_worker_files

    runtime_files = []
    if ctx.attr.runtime_pack:
        runtime_files = ctx.files.runtime_pack

    toolchain_info = CSharpToolchainInfo(
        aspnetcore_ref_pack = depset(aspnet_files),
        csc_dll = ctx.file.csc_dll,
        csc_worker = ctx.executable.csc_worker if ctx.attr.csc_worker else None,
        csc_worker_files = depset(worker_files),
        dotnet_env = dict(SEALED_DOTNET_ENV),
        dotnet_muxer = ctx.file.dotnet_muxer,
        host_pack = ctx.file.host_pack,
        host_rid = ctx.attr.host_rid,
        ref_pack = depset(ref_files),
        runtime_pack = depset(runtime_files),
        runtime_tree = _declare_runtime_tree(ctx, runtime_files),
        target_framework = ctx.attr.target_framework,
        target_rid = ctx.attr.target_rid,
        vstest_dll = ctx.file.vstest_dll if hasattr(ctx.file, "vstest_dll") else None,
    )

    return [
        platform_common.ToolchainInfo(
            csharp_info = toolchain_info,
            csharp = toolchain_info,
            toolchain_info = toolchain_info,
        ),
        toolchain_info,
    ]

csharp_toolchain = rule(
    doc = "Defines a C# toolchain linking host SDK tools to target framework packs.",
    implementation = _csharp_toolchain_impl,
    attrs = {
        "aspnetcore_ref_pack": attr.label_list(
            allow_files = True,
            cfg = "target",
            doc = "Reference assembly files for Microsoft.AspNetCore.App.",
        ),
        "csc_dll": attr.label(
            allow_single_file = True,
            cfg = "exec",
            doc = "Host file for Roslyn csc.dll compiler assembly.",
            mandatory = True,
        ),
        "csc_worker": attr.label(
            allow_single_file = True,
            cfg = "exec",
            doc = "Host executable file for persistent multiplex worker.",
            executable = True,
        ),
        "csc_worker_files": attr.label_list(
            allow_files = True,
            cfg = "exec",
            doc = "Files required to run csc_worker.",
        ),
        "dotnet_muxer": attr.label(
            allow_single_file = True,
            cfg = "exec",
            doc = "Host executable file for dotnet driver binary.",
            mandatory = True,
        ),
        "host_pack": attr.label(
            allow_single_file = True,
            cfg = "target",
            doc = "Native application host binary template file for target platform.",
        ),
        "host_rid": attr.string(
            doc = "Host runtime identifier string.",
            mandatory = True,
        ),
        "ref_pack": attr.label_list(
            allow_files = True,
            cfg = "target",
            doc = "Reference assembly files for target framework.",
        ),
        "runtime_pack": attr.label_list(
            allow_files = True,
            cfg = "target",
            doc = "Runtime assembly files for target framework.",
        ),
        "target_framework": attr.string(
            doc = "Target framework moniker string.",
            mandatory = True,
        ),
        "target_rid": attr.string(
            doc = "Target runtime identifier string.",
            mandatory = True,
        ),
        "vstest_dll": attr.label(
            allow_single_file = True,
            cfg = "exec",
            doc = "Host file for vstest.console.dll test runner assembly.",
        ),
    },
)
