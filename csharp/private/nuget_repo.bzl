"""Repository rules for NuGet packages and hub target declarations."""

load(
    "@bazel_tools//tools/build_defs/repo:utils.bzl",
    "read_netrc",
    "read_user_netrc",
    "use_netrc",
)
load(":common.bzl", "TARGET_FRAMEWORKS")
load(":nupkg.bzl", "build_references", "file_url", "nearest_framework")

SUPPORTED_RIDS = {
    "osx-arm64": "@rules_csharp//csharp/constraints:osx_arm64",
    "osx-x64": "@rules_csharp//csharp/constraints:osx_x64",
    "linux-x64": "@rules_csharp//csharp/constraints:linux_x64",
    "linux-arm64": "@rules_csharp//csharp/constraints:linux_arm64",
    "win-x64": "@rules_csharp//csharp/constraints:win_x64",
}

# The os and cpu of each RID, for config_settings that also match a target framework.
_RID_CONSTRAINTS = {
    "osx-arm64": ["@platforms//os:osx", "@platforms//cpu:aarch64"],
    "osx-x64": ["@platforms//os:osx", "@platforms//cpu:x86_64"],
    "linux-x64": ["@platforms//os:linux", "@platforms//cpu:x86_64"],
    "linux-arm64": ["@platforms//os:linux", "@platforms//cpu:aarch64"],
    "win-x64": ["@platforms//os:windows", "@platforms//cpu:x86_64"],
}

_TFM_FLAG = str(Label("//csharp/settings:target_framework"))

# Each RID and the more general RIDs NuGet falls back to, from
# https://learn.microsoft.com/en-us/dotnet/core/rid-catalog
RID_FALLBACKS = {
    "osx-arm64": ["osx-arm64", "osx", "unix"],
    "osx-x64": ["osx-x64", "osx", "unix"],
    "linux-x64": ["linux-x64", "linux", "unix"],
    "linux-arm64": ["linux-arm64", "linux", "unix"],
    "win-x64": ["win-x64", "win"],
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

def _find_best_tfm_dir(repository_ctx, base_rel, max_tfm = None):
    """Returns the folder under base_rel that restore picks for max_tfm, or the newest when max_tfm is None."""
    base_path = repository_ctx.path(base_rel)
    if not base_path.exists or not base_path.is_dir:
        return None
    best = nearest_framework([c.basename for c in base_path.readdir() if _has_dlls(c)], max_tfm)
    return base_rel + "/" + best if best else None

def _roslyn_version(name):
    """Returns (major, minor) for roslynX.Y, or None."""
    parts = name.removeprefix("roslyn").split(".")
    if not name.startswith("roslyn") or len(parts) != 2 or not parts[0].isdigit() or not parts[1].isdigit():
        return None
    return (int(parts[0]), int(parts[1]))

def _highest_roslyn_dir(base_path, suffix):
    """Returns the roslynX.Y child of base_path with the highest version whose suffix folder has dlls."""
    best = None
    for child in base_path.readdir():
        version = _roslyn_version(child.basename)
        if not child.is_dir or version == None:
            continue
        cs_path = child
        for part in suffix:
            cs_path = cs_path.get_child(part)
        if _has_dlls(cs_path) and (best == None or version > best[0]):
            best = (version, child.basename)
    return best[1] if best else None

def _find_analyzer_dir(repository_ctx):
    """Returns the one folder of C# analyzer dlls NuGet passes to csc, like restore does.

    Packages ship one copy of a generator per Roslyn version, in analyzers/dotnet/roslynX.Y/cs or
    analyzers/roslynX.Y/dotnet/cs. The compiler takes the highest, and culture subfolders hold only
    resources.
    """
    analyzers_path = repository_ctx.path("analyzers")
    if not analyzers_path.exists or not analyzers_path.is_dir:
        return None

    dotnet_path = analyzers_path.get_child("dotnet")
    if dotnet_path.exists and dotnet_path.is_dir:
        roslyn = _highest_roslyn_dir(dotnet_path, ["cs"])
        if roslyn:
            return "analyzers/dotnet/" + roslyn + "/cs"
        if _has_dlls(dotnet_path.get_child("cs")):
            return "analyzers/dotnet/cs"

    roslyn = _highest_roslyn_dir(analyzers_path, ["dotnet", "cs"])
    if roslyn:
        return "analyzers/" + roslyn + "/dotnet/cs"

    for child in analyzers_path.readdir():
        if child.is_dir and _has_dlls(child.get_child("dotnet").get_child("cs")):
            return "analyzers/" + child.basename + "/dotnet/cs"

    if _has_dlls_iterative(analyzers_path):
        return "analyzers"

    return None

def _compile_dir(repository_ctx, tfm):
    return _find_best_tfm_dir(repository_ctx, "ref", tfm) or _find_best_tfm_dir(repository_ctx, "lib", tfm)

def _runtime_dir(repository_ctx, tfm):
    return _find_best_tfm_dir(repository_ctx, "lib", tfm) or _compile_dir(repository_ctx, tfm)

def _rid_runtime_dir(repository_ctx, rid, tfm):
    """Returns runtimes/<rid>/lib/<tfm>/ for the first RID along the fallback chain."""
    for fallback in RID_FALLBACKS[rid]:
        r_dir = _find_best_tfm_dir(repository_ctx, "runtimes/" + fallback + "/lib", tfm)
        if r_dir:
            return r_dir
    return None

def _glob(d):
    return 'glob(["{}/*.dll"])'.format(d) if d else "[]"

def _select(cases, default, prune = True):
    """Returns default, or a select() over cases when any differs from it.

    prune drops the cases equal to default, which is only right when no case specializes another.
    """
    if all([v == default for v in cases.values()]):
        return default
    lines = ['        "{}": {},'.format(k, v) for k, v in cases.items() if not prune or v != default]
    lines.append('        "//conditions:default": {},'.format(default))
    return "select({\n" + "\n".join(lines) + "\n    })"

def _targets_files(repository_ctx):
    """Returns the .targets files under build/ and buildTransitive/ and their framework folders."""
    files = []
    for top in ["build", "buildTransitive"]:
        path = repository_ctx.path(top)
        if not path.exists or not path.is_dir:
            continue
        for child in path.readdir():
            if child.is_dir:
                files.extend([f for f in child.readdir() if f.basename.lower().endswith(".targets")])
            elif child.basename.lower().endswith(".targets"):
                files.append(child)
    return files

def _interceptors_namespaces(content):
    """Returns the namespaces a package's targets add to InterceptorsNamespaces outside any target or condition.

    Matches `<InterceptorsNamespaces>$(InterceptorsNamespaces);Ns</InterceptorsNamespaces>` in an unconditioned
    top-level PropertyGroup, which MSBuild always evaluates and passes to csc as a feature.
    """
    lower = content.lower()

    # Drop target bodies: properties set inside a target depend on that target running.
    kept = []
    pos = 0
    for _ in range(len(lower)):
        start = lower.find("<target", pos)
        if start < 0:
            break
        kept.append((pos, start))
        end = lower.find("</target>", start)
        if end < 0:
            pos = len(lower)
            break
        pos = end + len("</target>")
    kept.append((pos, len(lower)))

    namespaces = []
    for a, b in kept:
        part, part_lower = content[a:b], lower[a:b]
        offset = 0
        for group in part_lower.split("<propertygroup")[1:]:
            offset = part_lower.find("<propertygroup", offset) + len("<propertygroup")
            header = group.split(">", 1)[0]
            if "condition=" in header:
                continue
            body = group.split("</propertygroup>", 1)[0]
            body_orig = part[offset:offset + len(body)]
            search = 0
            for _ in range(len(body)):
                i = body.find("<interceptorsnamespaces", search)
                if i < 0:
                    break
                close = body.find(">", i)
                end = body.find("</interceptorsnamespaces>", close)
                if close < 0 or end < 0:
                    break
                search = end
                if "condition=" in body[i:close] or body[close - 1] == "/":
                    continue
                for ns in body_orig[close + 1:end].split(";"):
                    ns = ns.strip()
                    if ns and "$(" not in ns and "@(" not in ns and "%(" not in ns and ns not in namespaces:
                        namespaces.append(ns)
    return namespaces

def _removes_own_analyzers(content, pkg_id):
    """Whether a target removes the package's analyzers unless a property is 'true'.

    Opt-in generators such as the configuration binder ship
    <Target Condition="'$(EnableConfigurationBindingGenerator)' != 'true'"> with
    <Analyzer Remove="@(Analyzer->WithMetadataValue('NuGetPackageId', '<id>'))" />, so dotnet build
    leaves them out by default.
    """
    content = content.lower()
    pkg = "'" + pkg_id.lower() + "'"
    for target in content.split("<target")[1:]:
        header = target.split(">", 1)[0]
        if "condition=" not in header or "!= 'true'" not in header:
            continue
        body = target.split("</target>", 1)[0]
        for item in body.split("<analyzer")[1:]:
            # Not up to ">", which the "->" item transform also has.
            tag = item.split("<", 1)[0]
            if "remove=" in tag and "nugetpackageid" in tag and pkg in tag and "condition=" not in tag:
                return True
    return False

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

    # Restore picks lib, ref and runtimes folders for the consumer's framework, so each one gets its own
    # folder through //csharp/settings:target_framework. None is an empty flag, which builds for the newest.
    tfms = TARGET_FRAMEWORKS + [None]

    compile_dirs = {tfm: _compile_dir(repository_ctx, tfm) for tfm in tfms}
    runtime_dirs = {tfm: _runtime_dir(repository_ctx, tfm) for tfm in tfms}
    rid_lib_dirs = {(rid, tfm): _rid_runtime_dir(repository_ctx, rid, tfm) for rid in SUPPORTED_RIDS.keys() for tfm in tfms}
    default_runtime_dir = runtime_dirs[None]

    # Native libraries: runtimes/<rid>/native/ for the first RID along the fallback chain
    rid_native_dirs = {}
    for rid in SUPPORTED_RIDS.keys():
        for fallback in RID_FALLBACKS[rid]:
            if _has_files(repository_ctx.path("runtimes/" + fallback + "/native")):
                rid_native_dirs[rid] = "runtimes/" + fallback + "/native/*"
                break

    # Analyzers, unless the package's targets leave them out by default
    analyzer_dir = _find_analyzer_dir(repository_ctx)
    if analyzer_dir and any([_removes_own_analyzers(repository_ctx.read(f), pkg_id) for f in _targets_files(repository_ctx)]):
        analyzer_dir = None

    # InterceptorsNamespaces the package's targets always set, which dotnet build passes to csc as a feature.
    interceptors_namespaces = []
    for f in _targets_files(repository_ctx):
        for ns in _interceptors_namespaces(repository_ctx.read(f)):
            if ns not in interceptors_namespaces:
                interceptors_namespaces.append(ns)

    # build/<tfm>/*.dll: MSBuild targets copy these next to a test, like the VSTest adapters.
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
        pattern = "analyzers/**/*.dll" if analyzer_dir == "analyzers" else analyzer_dir + "/*.dll"
        lines.append('    dlls = glob(["{}"]),'.format(pattern))
        lines.append(')')
        lines.append('')

    # Dependencies mapping
    dep_labels = []
    for dep in repository_ctx.attr.dependencies:
        dep_labels.append('"@{}_{}//:{}"'.format(repository_ctx.attr.hub, _sanitize_name(dep), dep))

    compile_refs_expr = _select(
        {":" + t: _glob(compile_dirs[t]) for t in TARGET_FRAMEWORKS},
        _glob(compile_dirs[None]),
    )

    # Runtime dlls expression. A RID and framework key specializes both the RID key and the framework key.
    runtime_cases = {}
    if any([d for d in rid_lib_dirs.values()]):
        for rid, constraint in SUPPORTED_RIDS.items():
            for t in TARGET_FRAMEWORKS:
                runtime_cases[":{}_{}".format(rid, t)] = _glob(rid_lib_dirs[(rid, t)] or runtime_dirs[t])
            runtime_cases[constraint] = _glob(rid_lib_dirs[(rid, None)] or default_runtime_dir)
    for t in TARGET_FRAMEWORKS:
        runtime_cases[":" + t] = _glob(runtime_dirs[t])
    runtime_dlls_expr = _select(runtime_cases, _glob(default_runtime_dir), prune = len(runtime_cases) == len(TARGET_FRAMEWORKS))

    satellites_expr = _select(
        {":" + t: 'glob(["{}/*/*.resources.dll"], allow_empty = True)'.format(runtime_dirs[t]) if runtime_dirs[t] and runtime_dirs[t].startswith("lib/") else "[]" for t in TARGET_FRAMEWORKS},
        'glob(["{}/*/*.resources.dll"], allow_empty = True)'.format(default_runtime_dir) if default_runtime_dir and default_runtime_dir.startswith("lib/") else "[]",
    )

    for t in TARGET_FRAMEWORKS:
        lines.append('config_setting(')
        lines.append('    name = "{}",'.format(t))
        lines.append('    flag_values = {{"{}": "{}"}},'.format(_TFM_FLAG, t))
        lines.append(')')
        lines.append('')
        if any([d for d in rid_lib_dirs.values()]):
            for rid in SUPPORTED_RIDS.keys():
                lines.append('config_setting(')
                lines.append('    name = "{}_{}",'.format(rid, t))
                lines.append('    constraint_values = {},'.format(repr(_RID_CONSTRAINTS[rid])))
                lines.append('    flag_values = {{"{}": "{}"}},'.format(_TFM_FLAG, t))
                lines.append(')')
                lines.append('')

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
    if satellites_expr != "[]":
        lines.append('    satellites = {},'.format(satellites_expr))
    if test_runtime_dir:
        lines.append('    test_runtime_dlls = glob(["{}/*.dll"]),'.format(test_runtime_dir))
    lines.append('    deps = {},'.format(deps_expr))
    lines.append('    plugins = {},'.format(plugins_expr))
    if interceptors_namespaces:
        lines.append('    interceptors_namespaces = {},'.format(repr(interceptors_namespaces)))
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
        "hub": attr.string(
            default = "nuget",
            doc = "Hub name. Dependencies resolve to its `<hub>_<package id>` repos.",
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

