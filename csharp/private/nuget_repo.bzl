"""Repository rules for NuGet packages and hub target declarations."""

load(
    "@bazel_tools//tools/build_defs/repo:utils.bzl",
    "read_netrc",
    "read_user_netrc",
    "use_netrc",
)
load(":nupkg.bzl", "build_references", "file_url")

TFM_PRECEDENCE = [
    "net10.0",
    "net9.0",
    "net8.0",
    "net7.0",
    "net6.0",
    "netstandard2.1",
    "netstandard2.0",
    "net5.0",
    "netcoreapp3.1",
    "netcoreapp3.0",
    "netstandard1.6",
    "netstandard1.5",
    "netstandard1.4",
    "netstandard1.3",
    "netstandard1.2",
    "netstandard1.1",
    "netstandard1.0",
    "net48",
    "net472",
    "net471",
    "net47",
    "net462",
    "net461",
    "net452",
    "net451",
    "net45",
    "net40",
]

SUPPORTED_RIDS = {
    "osx-arm64": "@rules_csharp//csharp/constraints:osx_arm64",
    "linux-x64": "@rules_csharp//csharp/constraints:linux_x64",
    "linux-arm64": "@rules_csharp//csharp/constraints:linux_arm64",
    "win-x64": "@rules_csharp//csharp/constraints:win_x64",
}

def _has_dlls(path):
    if not path.exists or not path.is_dir:
        return False
    for child in path.readdir():
        if not child.is_dir and child.basename.lower().endswith(".dll"):
            return True
    return False

def _has_files(path):
    if not path.exists or not path.is_dir:
        return False
    for child in path.readdir():
        if not child.is_dir:
            return True
    return False

def _has_dlls_iterative(path):
    if not path.exists:
        return False
    if not path.is_dir:
        return path.basename.lower().endswith(".dll")
    stack = [path]
    for _ in range(100):
        if not stack:
            break
        curr = stack.pop()
        for child in curr.readdir():
            if not child.is_dir and child.basename.lower().endswith(".dll"):
                return True
            if child.is_dir:
                stack.append(child)
    return False

def _find_best_tfm_dir(repository_ctx, base_rel):
    base_path = repository_ctx.path(base_rel)
    if not base_path.exists or not base_path.is_dir:
        return None

    for tfm in TFM_PRECEDENCE:
        child = base_path.get_child(tfm)
        if _has_dlls(child):
            return base_rel + "/" + tfm

    for child in base_path.readdir():
        if _has_dlls(child):
            return base_rel + "/" + child.basename

    return None

def _find_analyzer_dir(repository_ctx):
    analyzers_path = repository_ctx.path("analyzers")
    if not analyzers_path.exists or not analyzers_path.is_dir:
        return None

    # 1. Direct analyzers/dotnet/cs
    direct_cs = repository_ctx.path("analyzers/dotnet/cs")
    if direct_cs.exists and direct_cs.is_dir and _has_dlls_iterative(direct_cs):
        return "analyzers/dotnet/cs"

    # 2. Roslyn versioned: analyzers/roslynX.Y/dotnet/cs
    roslyn_dirs = []
    for child in analyzers_path.readdir():
        if child.is_dir and child.basename.startswith("roslyn"):
            cs_path = child.get_child("dotnet").get_child("cs")
            if cs_path.exists and cs_path.is_dir and _has_dlls_iterative(cs_path):
                roslyn_dirs.append(child.basename)

    if roslyn_dirs:
        sorted_dirs = sorted(roslyn_dirs)
        highest = sorted_dirs[-1]
        return "analyzers/" + highest + "/dotnet/cs"

    # 3. Any subdirectory of analyzers containing dotnet/cs
    for child in analyzers_path.readdir():
        if child.is_dir:
            cs_path = child.get_child("dotnet").get_child("cs")
            if cs_path.exists and cs_path.is_dir and _has_dlls_iterative(cs_path):
                return "analyzers/" + child.basename + "/dotnet/cs"

    # 4. Any dlls anywhere in analyzers
    if _has_dlls_iterative(analyzers_path):
        return "analyzers"

    return None


def _sanitize_name(name):
    return name.replace(".", "_").replace("-", "_").lower()

def package_urls(pkg_id, version, feeds, local_package_dirs, use_public_sources):
    """Returns the URLs to try, in order, for one package version.

    Local directories come first, then feeds, then nuget.org unless
    use_public_sources is False.
    """
    id_lower = pkg_id.lower()
    ver_lower = version.lower()

    configured_feeds = list(feeds)
    candidate_urls = []

    for local_dir in local_package_dirs:
        clean_dir = local_dir[:-1] if local_dir.endswith("/") else local_dir
        if not clean_dir.startswith("file://"):
            clean_dir = file_url(clean_dir)
        candidate_urls.append("{}/{}.{}.nupkg".format(clean_dir, pkg_id, version))
        candidate_urls.append("{}/{}.{}.nupkg".format(clean_dir, id_lower, version))
        candidate_urls.append("{}/{}/{}/{}.{}.nupkg".format(clean_dir, id_lower, version, id_lower, version))

    for feed in configured_feeds:
        clean_feed = feed[:-1] if feed.endswith("/") else feed
        if clean_feed.endswith("/index.json"):
            clean_feed = clean_feed[:-len("/index.json")]

        # nuget.org's v3 service index serves packages from its flat container.
        if clean_feed.lower() == "https://api.nuget.org/v3":
            clean_feed = "https://api.nuget.org/v3-flatcontainer"

        candidate_urls.append("{}/{}/{}/{}.{}.nupkg".format(
            clean_feed,
            id_lower,
            ver_lower,
            id_lower,
            ver_lower,
        ))
        candidate_urls.append("{}/{}/{}/{}.{}.nupkg".format(
            clean_feed,
            pkg_id,
            version,
            pkg_id,
            version,
        ))
        candidate_urls.append("{}/Download/{}/{}".format(
            clean_feed,
            pkg_id,
            version,
        ))

    official_flat = "https://api.nuget.org/v3-flatcontainer/{}/{}/{}.{}.nupkg".format(
        id_lower,
        ver_lower,
        id_lower,
        ver_lower,
    )
    if use_public_sources and official_flat not in candidate_urls:
        candidate_urls.append(official_flat)
    return candidate_urls

def package_auth(ctx, netrc, urls, auth_patterns):
    """Returns the download auth for urls from netrc, $NETRC or the user's .netrc."""
    if netrc:
        netrc_data = read_netrc(ctx, netrc)
    elif "NETRC" in ctx.os.environ:
        netrc_data = read_netrc(ctx, ctx.os.environ["NETRC"])
    else:
        netrc_data = read_user_netrc(ctx)
    return use_netrc(netrc_data, urls, auth_patterns)

def _nuget_package_repo_impl(repository_ctx):
    urls = package_urls(
        repository_ctx.attr.package_id,
        repository_ctx.attr.version,
        repository_ctx.attr.feeds,
        repository_ctx.attr.local_package_dirs,
        repository_ctx.attr.use_public_sources,
    )
    repository_ctx.download_and_extract(
        url = urls,
        type = "zip",
        sha256 = repository_ctx.attr.sha256,
        auth = package_auth(repository_ctx, repository_ctx.attr.netrc, urls, repository_ctx.attr.auth_patterns),
    )

    pkg_id = repository_ctx.attr.package_id

    # 1. Compile references: ref/<tfm>/ falling back to lib/<tfm>/
    compile_dir = _find_best_tfm_dir(repository_ctx, "ref")
    if not compile_dir:
        compile_dir = _find_best_tfm_dir(repository_ctx, "lib")

    # 2. Default runtime assemblies: lib/<tfm>/
    default_runtime_dir = _find_best_tfm_dir(repository_ctx, "lib")
    if not default_runtime_dir and compile_dir:
        default_runtime_dir = compile_dir

    # 3. RID-specific runtime assemblies: runtimes/<rid>/lib/<tfm>/
    rid_lib_dirs = {}
    for rid in SUPPORTED_RIDS.keys():
        r_dir = _find_best_tfm_dir(repository_ctx, "runtimes/" + rid + "/lib")
        if r_dir:
            rid_lib_dirs[rid] = r_dir

    # 4. Native libraries: runtimes/<rid>/native/
    rid_native_dirs = {}
    for rid in SUPPORTED_RIDS.keys():
        n_path = repository_ctx.path("runtimes/" + rid + "/native")
        if _has_files(n_path):
            rid_native_dirs[rid] = "runtimes/" + rid + "/native/*"

    # 5. Analyzers
    analyzer_dir = _find_analyzer_dir(repository_ctx)

    # 6. build/<tfm>/*.dll: MSBuild targets copy these next to a test, like the VSTest adapters.
    # The ones the package's own props or targets add as a <Reference> are compile and runtime dlls too.
    # Other build/ dlls, such as MSBuild tasks, also land next to library tests, where nothing loads them.
    test_runtime_dir = _find_best_tfm_dir(repository_ctx, "build")
    build_refs = []
    if test_runtime_dir:
        referenced = []
        for f in repository_ctx.path(test_runtime_dir).readdir():
            if f.basename.lower().endswith((".props", ".targets")):
                referenced.extend([n.lower() + ".dll" for n in build_references(repository_ctx.read(f))])
        build_refs = sorted([
            test_runtime_dir + "/" + f.basename
            for f in repository_ctx.path(test_runtime_dir).readdir()
            if f.basename.lower() in referenced
        ])

    # Build file generation
    lines = [
        '"""Generated BUILD.bazel for NuGet package: {}"""'.format(pkg_id),
        'load("@rules_csharp//csharp:defs.bzl", "csharp_import", "csharp_analyzer_library")',
        'package(default_visibility = ["//visibility:public"])',
        '',
    ]

    has_analyzers = bool(analyzer_dir)
    if has_analyzers:
        lines.append('csharp_analyzer_library(')
        lines.append('    name = "analyzers",')
        lines.append('    dlls = glob(["{}/**/*.dll", "{}/*.dll"]),'.format(analyzer_dir, analyzer_dir))
        lines.append(')')
        lines.append('')

    # Dependencies mapping
    dep_labels = []
    for dep in repository_ctx.attr.dependencies:
        dep_labels.append('"@nuget_{}//:{}"'.format(_sanitize_name(dep), dep))

    # Compile refs expression
    if compile_dir:
        compile_refs_expr = 'glob(["{}/*.dll"])'.format(compile_dir)
    else:
        compile_refs_expr = '[]'

    # Runtime dlls expression
    if rid_lib_dirs:
        select_cases = []
        for rid, constraint in SUPPORTED_RIDS.items():
            if rid in rid_lib_dirs:
                select_cases.append('        "{}": glob(["{}/*.dll"]),'.format(constraint, rid_lib_dirs[rid]))
            elif default_runtime_dir:
                select_cases.append('        "{}": glob(["{}/*.dll"]),'.format(constraint, default_runtime_dir))
            else:
                select_cases.append('        "{}": [],'.format(constraint))
        if default_runtime_dir:
            select_cases.append('        "//conditions:default": glob(["{}/*.dll"]),'.format(default_runtime_dir))
        else:
            select_cases.append('        "//conditions:default": [],')

        runtime_dlls_expr = 'select({\n' + '\n'.join(select_cases) + '\n    })'
    elif default_runtime_dir:
        runtime_dlls_expr = 'glob(["{}/*.dll"])'.format(default_runtime_dir)
    else:
        runtime_dlls_expr = '[]'

    # Native libs expression
    if rid_native_dirs:
        select_cases = []
        for rid, constraint in SUPPORTED_RIDS.items():
            if rid in rid_native_dirs:
                select_cases.append('        "{}": glob(["{}"]),'.format(constraint, rid_native_dirs[rid]))
            else:
                select_cases.append('        "{}": [],'.format(constraint))
        select_cases.append('        "//conditions:default": [],')
        native_libs_expr = 'select({\n' + '\n'.join(select_cases) + '\n    })'
    else:
        native_libs_expr = '[]'

    plugins_expr = '[":analyzers"]' if has_analyzers else '[]'
    deps_expr = '[\n        ' + ',\n        '.join(dep_labels) + '\n    ]' if dep_labels else '[]'

    lines.append('csharp_import(')
    lines.append('    name = "{}",'.format(pkg_id))
    if build_refs:
        compile_refs_expr += " + {}".format(repr(build_refs))
        runtime_dlls_expr += " + {}".format(repr(build_refs))
    lines.append('    compile_refs = {},'.format(compile_refs_expr))
    lines.append('    runtime_dlls = {},'.format(runtime_dlls_expr))
    lines.append('    native_libs = {},'.format(native_libs_expr))
    if test_runtime_dir:
        lines.append('    test_runtime_dlls = glob(["{}/*.dll"]),'.format(test_runtime_dir))
    lines.append('    deps = {},'.format(deps_expr))
    lines.append('    plugins = {},'.format(plugins_expr))
    lines.append(')')
    lines.append('')

    # Aliases
    lines.append('alias(')
    lines.append('    name = "pkg",')
    lines.append('    actual = ":{}",'.format(pkg_id))
    lines.append(')')
    lines.append('')

    if pkg_id.lower() != pkg_id:
        lines.append('alias(')
        lines.append('    name = "{}",'.format(pkg_id.lower()))
        lines.append('    actual = ":{}",'.format(pkg_id))
        lines.append(')')
        lines.append('')

    repository_ctx.file("BUILD.bazel", "\n".join(lines) + "\n")

nuget_package_repo = repository_rule(
    doc = "Downloads and extracts individual NuGet packages and generates target definitions.",
    implementation = _nuget_package_repo_impl,
    attrs = {
        "auth_patterns": attr.string_dict(
            doc = "Host to authentication pattern mappings.",
        ),
        "dependencies": attr.string_list(
            doc = "Direct dependency package identifier list.",
        ),
        "feeds": attr.string_list(
            doc = "Candidate package feed URLs.",
        ),
        "local_package_dirs": attr.string_list(
            doc = "Local filesystem package directory paths.",
        ),
        "netrc": attr.label(
            doc = "Authentication netrc configuration file label.",
        ),
        "package_id": attr.string(
            doc = "NuGet package identifier string.",
            mandatory = True,
        ),
        "sha256": attr.string(
            doc = "SHA-256 of the downloaded .nupkg file. Empty downloads it unverified.",
        ),
        "use_public_sources": attr.bool(
            default = True,
            doc = "Whether to fall back to nuget.org after the feeds.",
        ),
        "version": attr.string(
            doc = "NuGet package version string.",
            mandatory = True,
        ),
    },
)

def _nuget_hub_repo_impl(repository_ctx):
    packages = repository_ctx.attr.packages
    lines = [
        '"""Generated hub BUILD.bazel for NuGet packages."""',
        'package(default_visibility = ["//visibility:public"])',
        '',
    ]

    for pkg_id, repo_name in packages.items():
        lines.append('alias(')
        lines.append('    name = "{}",'.format(pkg_id))
        lines.append('    actual = "@{}//:{}",'.format(repo_name, pkg_id))
        lines.append(')')
        lines.append('')

        if pkg_id.lower() != pkg_id:
            lines.append('alias(')
            lines.append('    name = "{}",'.format(pkg_id.lower()))
            lines.append('    actual = "@{}//:{}",'.format(repo_name, pkg_id))
            lines.append(')')
            lines.append('')

        sanitized = _sanitize_name(pkg_id)
        if sanitized != pkg_id and sanitized != pkg_id.lower():
            lines.append('alias(')
            lines.append('    name = "{}",'.format(sanitized))
            lines.append('    actual = "@{}//:{}",'.format(repo_name, pkg_id))
            lines.append(')')
            lines.append('')

    repository_ctx.file("BUILD.bazel", "\n".join(lines) + "\n")

nuget_hub_repo = repository_rule(
    doc = "Generates package alias targets mapping canonical package names to individual package repos.",
    implementation = _nuget_hub_repo_impl,
    attrs = {
        "packages": attr.string_dict(
            doc = "Mapping from package identifier to repository name.",
        ),
    },
)

