"""Fetches grpc_csharp_plugin from the Grpc.Tools NuGet package."""

# The gRPC project builds the plugin in Grpc.Tools for each host it supports.
_VERSION = "2.85.0"
_SHA256 = "122c2e9a0f73b06a77f51b1753fee810eaa72966a798887cb43fd9aa7a42b6ed"

# The Grpc.Tools folder for each exec platform, as (os, cpu, folder).
_PLATFORMS = [
    ("linux", "x86_64", "linux_x64"),
    ("linux", "aarch64", "linux_arm64"),
    ("linux", "x86_32", "linux_x86"),
    ("macos", "x86_64", "macosx_universal"),
    ("macos", "aarch64", "macosx_universal"),
    ("windows", "x86_64", "windows_x64"),
    ("windows", "x86_32", "windows_x86"),
]

def _plugin(os, folder):
    return "tools/{}/grpc_csharp_plugin{}".format(folder, ".exe" if os == "windows" else "")

def _grpc_csharp_plugin_impl(rctx):
    rctx.download_and_extract(
        url = "https://api.nuget.org/v3-flatcontainer/grpc.tools/{0}/grpc.tools.{0}.nupkg".format(_VERSION),
        sha256 = _SHA256,
        type = "zip",
    )

    # NuGet zips carry no Unix file modes, so the binaries extract without the executable bit.
    if not rctx.os.name.lower().startswith("windows"):
        unix = {_plugin(os, folder): None for os, _, folder in _PLATFORMS if os != "windows"}
        result = rctx.execute(["chmod", "+x"] + list(unix))
        if result.return_code != 0:
            fail("chmod of grpc_csharp_plugin failed: " + result.stderr)

    build = ['package(default_visibility = ["//visibility:public"])', ""]
    branches = []
    for os, cpu, folder in _PLATFORMS:
        name = "{}_{}".format(os, cpu)
        build.append("config_setting(name = {}, constraint_values = [{}, {}])".format(
            repr(name),
            repr("@platforms//os:" + os),
            repr("@platforms//cpu:" + cpu),
        ))
        branches.append("        {}: {},".format(repr(":" + name), repr(_plugin(os, folder))))
    build += [
        "",
        "alias(",
        '    name = "grpc_csharp_plugin",',
        "    actual = select({",
    ] + branches + [
        "    }, no_match_error = " + repr(
            "Grpc.Tools {} has no grpc_csharp_plugin for this exec platform. ".format(_VERSION) +
            "Set plugin on csharp_grpc_library to a grpc_csharp_plugin that runs on it.",
        ) + "),",
        ")",
    ]
    rctx.file("BUILD.bazel", "\n".join(build) + "\n")

grpc_csharp_plugin = repository_rule(
    implementation = _grpc_csharp_plugin_impl,
    doc = "Downloads Grpc.Tools from nuget.org and exposes grpc_csharp_plugin for the exec platform.",
)
