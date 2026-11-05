"""Module extensions for rules_csharp."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//csharp:toolchains.bzl", "DOTNET_ARTIFACTS", "PLATFORMS", "csharp_toolchains_hub", "runtime_pack", "sdk_exec")
load("//csharp/private:nuget_repo.bzl", "nuget_hub_repo", "nuget_package_repo", "package_auth", "package_urls")
load("//csharp/private:nupkg.bzl", "base64_to_hex", "hex_to_sri", "sha512_files", "strip_signature")

_COVERLET = "coverlet.console.10.1.0.nupkg"

toolchain_tag = tag_class(
    doc = """Declares .NET SDK versions and where to download them from.

The SDK archives come from `mirror_urls` first, then from Microsoft's download
CDN. The coverage tool, coverlet.console, comes from `{mirror}/""" + _COVERLET + """`
on each mirror first, then from nuget.org. Set `use_public_sources = False` to
download only from the mirrors.
""",
    attrs = {
        "auth_patterns": attr.string_dict(
            doc = "Host to authentication pattern mappings.",
        ),
        "dotnet_versions": attr.string_list(
            default = ["8.0.403", "9.0.200", "10.0.100"],
            doc = """Supported .NET SDK version strings.

rules_csharp knows the checksums of the default versions. Any other version
needs its archives in `sdk_checksums`.""",
        ),
        "mirror_urls": attr.string_list(
            doc = "Candidate mirror base URL list.",
        ),
        "netrc": attr.label(
            doc = "Authentication netrc configuration file label.",
        ),
        "sdk_checksums": attr.string_dict(
            doc = """Checksum of each SDK archive, keyed by archive file name.

This pins any SDK version, including patch releases rules_csharp doesn't know
about, so the download is checked and cached with no network access beyond
the mirror. A value is the `hash` (hex sha512) that
https://builds.dotnet.microsoft.com/dotnet/release-metadata/<major.minor>/releases.json
lists for the file, or an SRI value such as `sha256-...`. The closest MSBuild
equivalent is the `contentHash` that packages.lock.json records for each
package. `dotnet` itself doesn't download an SDK.

```starlark
csharp.toolchain(
    dotnet_versions = ["8.0.404"],
    mirror_urls = ["https://artifacts.example.com/dotnet"],
    sdk_checksums = {
        "dotnet-sdk-8.0.404-linux-x64.tar.gz": "<sha512 from releases.json>",
    },
)
```

Each platform a build uses needs its archive here. An archive with no
checksum fails when Bazel fetches it and names the file.""",
        ),
        "url_templates": attr.string_list(
            default = [
                "{mirror}/dotnet/Sdk/{version}/{archive}",
                "{mirror}/artifactory/dotnet-sdk/{version}/{archive}",
            ],
            doc = "URL templates for mirror expansion.",
        ),
        "use_public_sources": attr.bool(
            default = True,
            doc = """Whether to fall back to Microsoft's download CDN and nuget.org.

When False, the SDK archives and coverlet.console come only from
`mirror_urls`, and Bazel never contacts a public host for them. This is the
same as a NuGet.Config whose `<packageSources>` starts with `<clear />`.
Setting it needs `mirror_urls`. Once any `csharp.toolchain` tag sets it to
False, other tags can't turn it back on.""",
        ),
    },
)

def _csharp_impl(module_ctx):
    dotnet_versions = ["8.0.403", "9.0.200", "10.0.100"]
    mirror_urls = []
    url_templates = [
        "{mirror}/dotnet/Sdk/{version}/{archive}",
        "{mirror}/artifactory/dotnet-sdk/{version}/{archive}",
    ]
    netrc = None
    auth_patterns = {}
    sdk_checksums = {}
    use_public_sources = True

    # The root module's tags win over its dependencies' tags.
    tags = [t for mod in module_ctx.modules if not mod.is_root for t in mod.tags.toolchain]
    tags += [t for mod in module_ctx.modules if mod.is_root for t in mod.tags.toolchain]
    for tag in tags:
        if tag.dotnet_versions:
            dotnet_versions = tag.dotnet_versions
        if tag.mirror_urls:
            mirror_urls = tag.mirror_urls
        if tag.url_templates:
            url_templates = tag.url_templates
        if tag.netrc:
            netrc = tag.netrc
        if tag.auth_patterns:
            auth_patterns = tag.auth_patterns
        sdk_checksums.update(tag.sdk_checksums)

        # Once any tag turns public sources off they stay off, so another tag can't quietly turn them back on.
        use_public_sources = use_public_sources and tag.use_public_sources

    if not use_public_sources and not mirror_urls:
        fail("csharp.toolchain sets use_public_sources = False, so it needs mirror_urls to download the SDK from.")
    mirrors = [m[:-1] if m.endswith("/") else m for m in mirror_urls]

    for version in dotnet_versions:
        v_slug = version.replace(".", "_")
        for p_name, p_info in PLATFORMS.items():
            rid = p_info["rid"]
            ext = p_info["archive_ext"]
            archive = "dotnet-sdk-{}-{}.{}".format(version, rid, ext)

            candidate_urls = []
            for base in mirrors:
                for tmpl in url_templates:
                    candidate_urls.append(tmpl.format(
                        archive = archive,
                        mirror = base,
                        rid = rid,
                        version = version,
                    ))
            if use_public_sources:
                candidate_urls.append("https://dotnetcli.azureedge.net/dotnet/Sdk/{}/{}".format(version, archive))

            if archive in sdk_checksums:
                integrity = hex_to_sri(sdk_checksums[archive])
            else:
                integrity = DOTNET_ARTIFACTS.get(version, {}).get(rid, "")

            sdk_name = "dotnet_sdk_{}_{}".format(v_slug, p_name)
            sdk_exec(
                name = sdk_name,
                archive_ext = ext,
                auth_patterns = auth_patterns,
                dotnet_version = version,
                integrity = integrity,
                netrc = netrc,
                platform = p_name,
                rid = rid,
                urls = candidate_urls,
            )

            pack_name = "csharp_pack_{}_{}".format(v_slug, p_name)
            runtime_pack(
                name = pack_name,
                archive_ext = ext,
                auth_patterns = auth_patterns,
                dotnet_version = version,
                integrity = integrity,
                netrc = netrc,
                platform = p_name,
                rid = rid,
                urls = candidate_urls,
            )

    coverlet_urls = [base + "/" + _COVERLET for base in mirrors]
    if use_public_sources:
        coverlet_urls.append("https://api.nuget.org/v3-flatcontainer/coverlet.console/10.1.0/" + _COVERLET)
    http_archive(
        name = "csharp_coverlet",
        build_file_content = """filegroup(
    name = "files",
    srcs = glob(["tools/net8.0/any/**"]),
    visibility = ["//visibility:public"],
)
""",
        sha256 = "b01e98cead98a7888745b5f2a48c4e71d4b5372e6c70e751b81cc8ccf4af0a76",
        type = "zip",
        urls = coverlet_urls,
    )

    csharp_toolchains_hub(
        name = "dotnet_toolchains",
        dotnet_versions = dotnet_versions,
    )
    csharp_toolchains_hub(
        name = "csharp_toolchains",
        dotnet_versions = dotnet_versions,
    )

csharp = module_extension(
    doc = "Configures .NET toolchain SDK and runtime pack repositories.",
    implementation = _csharp_impl,
    tag_classes = {
        "toolchain": toolchain_tag,
    },
)

from_lock_tag = tag_class(
    doc = """Configures NuGet package resolution from lockfile definitions.

Takes a `packages.lock.json` exactly as `dotnet restore` writes it with
`RestorePackagesWithLockFile` set. The extension downloads each package once
and checks it against its `contentHash`, so a package that does not match its
lock entry fails. For a signed package, which includes every package on
nuget.org, the hash covers the package without its signature, the same way
NuGet checks it. The extension then pins the sha256 of each downloaded file,
which MODULE.bazel.lock records. Later fetches check that sha256 and are
served from the repository cache.

Packages come from `local_package_dirs` first, then `feeds` (or the sources
in `nuget_config`), then nuget.org. Set `use_public_sources = False` to
download only from those directories and feeds.

A package whose `contentHash` is empty, as `CsprojSync --bootstrap-lock` writes
when restore fails, can't be checked. With public sources on, the extension
warns and downloads it unverified. With them off, it fails.

Feeds must use https or local directories. Bazel does not download over plain
http without a known checksum.
""",
    attrs = {
        "auth_patterns": attr.string_dict(
            doc = "Host to authentication pattern mappings.",
        ),
        "directory_packages_props": attr.label(
            doc = "Path to Directory.Packages.props file.",
        ),
        "feeds": attr.string_list(
            doc = """Package feed URLs, tried in order. Each is a v3 feed's `index.json`, the
same URL a NuGet.Config `<add>` uses, or the package base URL that `index.json`
lists as `PackageBaseAddress/3.0.0`.""",
        ),
        "local_package_dirs": attr.string_list(
            doc = "Local filesystem package directory paths.",
        ),
        "name": attr.string(
            default = "nuget",
            doc = "Hub repository name.",
        ),
        "netrc": attr.label(
            doc = "Authentication netrc configuration file label.",
        ),
        "nuget_config": attr.label(
            doc = "Path to NuGet.Config XML configuration file.",
        ),
        "packages_lock_json": attr.label(
            doc = "Path to packages.lock.json lockfile written by `dotnet restore`.",
            mandatory = True,
        ),
        "use_public_sources": attr.bool(
            default = True,
            doc = """Whether to fall back to nuget.org after the directories and feeds.

When False, packages come only from `local_package_dirs`, `feeds` and the
sources in `nuget_config`, so Bazel never contacts nuget.org for them, and a
package with an empty `contentHash` fails instead of downloading unverified.
A `nuget_config` whose `<packageSources>` has `<clear />` turns this off too,
as it does for `dotnet restore`. Setting it needs at least one directory or
feed. Once any `nuget.from_lock` tag turns it off, other tags can't turn it
back on.""",
        ),
    },
)

def _extract_attr(tag_str, attr_name):
    key1 = attr_name + '="'
    pos1 = tag_str.find(key1)
    if pos1 != -1:
        end1 = tag_str.find('"', pos1 + len(key1))
        if end1 != -1:
            return tag_str[pos1 + len(key1):end1]
    key2 = attr_name + "='"
    pos2 = tag_str.find(key2)
    if pos2 != -1:
        end2 = tag_str.find("'", pos2 + len(key2))
        if end2 != -1:
            return tag_str[pos2 + len(key2):end2]
    return None

def _extract_block(content, start_tag, end_tag):
    start = content.find(start_tag)
    if start == -1:
        return ""
    start += len(start_tag)
    end = content.find(end_tag, start)
    if end == -1:
        return ""
    return content[start:end]

def _parse_nuget_config(content):
    """Returns the package sources and whether a <clear /> dropped the inherited ones."""
    sources = []
    cleared = False

    # Go by tags, not lines, since a tag can share a line or span several.
    block = _extract_block(_strip_comments(content), "<packageSources>", "</packageSources>")
    for tag in block.split("<")[1:]:
        tag = tag.split(">")[0]
        name = tag.replace("/", " ").replace("\n", " ").replace("\r", " ").replace("\t", " ").strip().split(" ")[0]
        if name == "clear":
            sources = []
            cleared = True
        elif name == "add":
            val = _extract_attr(tag, "value")
            if val:
                sources.append(val)
    return sources, cleared

def _strip_comments(content):
    parts = content.split("<!--")
    return parts[0] + "".join([p[p.find("-->") + 3:] if "-->" in p else "" for p in parts[1:]])

def _sanitize_name(name):
    return name.replace(".", "_").replace("-", "_").lower()

def _package_base(module_ctx, feed, index, netrc, auth_patterns):
    """Returns the PackageBaseAddress/3.0.0 a v3 index.json lists, or feed as it is."""
    url = feed.rstrip("/")
    if not url.endswith("/index.json") or url.lower() == "https://api.nuget.org/v3/index.json":
        return feed
    output = "feeds/{}/index.json".format(index)
    module_ctx.download(
        url = url,
        output = output,
        auth = package_auth(module_ctx, netrc, [url], auth_patterns),
    )
    service_index = json.decode(module_ctx.read(output), default = None)
    if type(service_index) != "dict":
        fail("{} is not a v3 service index.".format(url))
    for resource in service_index.get("resources", []):
        types = resource.get("@type", [])
        if type(types) == "string":
            types = [types]
        if "PackageBaseAddress/3.0.0" in types and resource.get("@id"):
            return resource["@id"]
    fail("{} lists no PackageBaseAddress/3.0.0 resource, so packages can't be downloaded from it.".format(url))

def _pin_packages(module_ctx, packages, feeds, local_dirs, use_public_sources, netrc, auth_patterns):
    """Checks each package against its contentHash and returns its sha256 by id.

    For a signed package, and every package on nuget.org is signed, the
    contentHash covers the zip without its .signature.p7s entry, not the file
    (https://learn.microsoft.com/en-us/nuget/reference/signed-packages-reference).
    Bazel can only check and cache a download by the hash of the file. So
    download each package once here, check it, and pin the file's sha256 on the
    package repo. MODULE.bazel.lock records the pin, so later fetches are
    checked by Bazel and served from the repository cache.
    """
    pending = []
    for pkg_id, info in packages.items():
        if not info["content_hash"]:
            if not use_public_sources:
                fail("{} {} has an empty contentHash in packages.lock.json. Run `dotnet restore --use-lock-file` to fill it in.".format(pkg_id, info["version"]))

            # buildifier: disable=print
            print("WARNING: {} {} has an empty contentHash in packages.lock.json, so it is downloaded unverified. Run `dotnet restore --use-lock-file` to fill it in.".format(pkg_id, info["version"]))
            continue
        urls = package_urls(pkg_id, info["version"], feeds, local_dirs, use_public_sources)
        output = "nupkg/{}.{}.nupkg".format(pkg_id, info["version"])
        pending.append(struct(
            pkg_id = pkg_id,
            info = info,
            output = output,
            download = module_ctx.download(
                url = urls,
                output = output,
                auth = package_auth(module_ctx, netrc, urls, auth_patterns),
                block = False,
            ),
        ))

    hashed = []
    sha256 = {}
    for p in pending:
        sha256[p.pkg_id] = p.download.wait().sha256
        data = module_ctx.read(p.output)
        stripped = strip_signature(data)
        path = p.output
        if len(stripped) != len(data):
            path = p.output + ".stripped"
            module_ctx.file(path, stripped, executable = False, legacy_utf8 = False)
        hashed.append(module_ctx.path(path))

    for p, actual in zip(pending, sha512_files(module_ctx, hashed)):
        if actual != base64_to_hex(p.info["content_hash"]):
            fail("{} {}: the downloaded package does not match its contentHash in packages.lock.json".format(
                p.pkg_id,
                p.info["version"],
            ))
    return sha256

def _nuget_impl(module_ctx):
    packages = {}
    hub_name = "nuget"
    feeds = []
    local_dirs = []
    netrc = None
    auth_patterns = {}
    use_public_sources = True

    for mod in module_ctx.modules:
        for tag in mod.tags.from_lock:
            # Once any tag or <clear /> turns public sources off they stay off.
            use_public_sources = use_public_sources and tag.use_public_sources
            if tag.name:
                hub_name = tag.name
            if tag.feeds:
                feeds = list(tag.feeds)
            if tag.local_package_dirs:
                local_dirs = list(tag.local_package_dirs)
            if tag.netrc:
                netrc = tag.netrc
            if tag.auth_patterns:
                auth_patterns = tag.auth_patterns

            if tag.nuget_config:
                xml_content = module_ctx.read(tag.nuget_config)
                parsed_sources, cleared = _parse_nuget_config(xml_content)
                if parsed_sources:
                    feeds = parsed_sources
                if cleared:
                    use_public_sources = False

            content = module_ctx.read(tag.packages_lock_json)
            data = json.decode(content)

            dependencies = data.get("dependencies", {})
            for _framework, fw_pkgs in dependencies.items():
                for pkg_id, pkg_info in fw_pkgs.items():
                    resolved = pkg_info.get("resolved", "")
                    content_hash = pkg_info.get("contentHash", "")
                    dep_dict = pkg_info.get("dependencies", {})

                    if pkg_id not in packages:
                        packages[pkg_id] = {
                            "content_hash": content_hash,
                            "dependencies": list(dep_dict.keys()),
                            "version": resolved,
                        }
                    else:
                        existing_deps = packages[pkg_id]["dependencies"]
                        for d in dep_dict.keys():
                            if d not in existing_deps:
                                existing_deps.append(d)

    if not use_public_sources and not feeds and not local_dirs:
        fail("nuget.from_lock has public sources off (use_public_sources = False or <clear /> in nuget_config), so it needs local_package_dirs, feeds or a nuget_config with sources.")
    feeds = [_package_base(module_ctx, feed, i, netrc, auth_patterns) for i, feed in enumerate(feeds)]
    sha256 = _pin_packages(module_ctx, packages, feeds, local_dirs, use_public_sources, netrc, auth_patterns)

    hub_packages = {}
    for pkg_id, info in packages.items():
        repo_name = "nuget_" + _sanitize_name(pkg_id)
        hub_packages[pkg_id] = repo_name
        nuget_package_repo(
            name = repo_name,
            auth_patterns = auth_patterns,
            dependencies = info["dependencies"],
            feeds = feeds,
            local_package_dirs = local_dirs,
            netrc = netrc,
            package_id = pkg_id,
            sha256 = sha256.get(pkg_id, ""),
            use_public_sources = use_public_sources,
            version = info["version"],
        )

    nuget_hub_repo(
        name = hub_name,
        packages = hub_packages,
    )

nuget = module_extension(
    doc = "Resolves and downloads external NuGet packages from lockfile definitions.",
    implementation = _nuget_impl,
    tag_classes = {
        "from_lock": from_lock_tag,
    },
)
