"""Module extensions for rules_csharp."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//csharp:toolchains.bzl", "DOTNET_ARTIFACTS", "PLATFORMS", "csharp_toolchains_hub", "runtime_pack", "sdk_exec")
load("//csharp/private:nuget_repo.bzl", "nuget_hub_repo", "nuget_package_repo")

toolchain_tag = tag_class(
    doc = "Declares .NET SDK versions and remote mirror configurations.",
    attrs = {
        "auth_patterns": attr.string_dict(
            doc = "Host to authentication pattern mappings.",
        ),
        "dotnet_versions": attr.string_list(
            default = ["8.0.403", "9.0.200", "10.0.100"],
            doc = "Supported .NET SDK version strings.",
        ),
        "mirror_urls": attr.string_list(
            doc = "Candidate mirror base URL list.",
        ),
        "netrc": attr.label(
            doc = "Authentication netrc configuration file label.",
        ),
        "url_templates": attr.string_list(
            default = [
                "{mirror}/dotnet/Sdk/{version}/{archive}",
                "{mirror}/artifactory/dotnet-sdk/{version}/{archive}",
            ],
            doc = "URL templates for mirror expansion.",
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

    for mod in module_ctx.modules:
        if not mod.is_root:
            for tag in mod.tags.toolchain:
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

    for mod in module_ctx.modules:
        if mod.is_root:
            for tag in mod.tags.toolchain:
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

    for version in dotnet_versions:
        v_slug = version.replace(".", "_")
        for p_name, p_info in PLATFORMS.items():
            rid = p_info["rid"]
            ext = p_info["archive_ext"]
            archive = "dotnet-sdk-{}-{}.{}".format(version, rid, ext)

            candidate_urls = []
            for m in mirror_urls:
                base = m[:-1] if m.endswith("/") else m
                for tmpl in url_templates:
                    candidate_urls.append(tmpl.format(
                        archive = archive,
                        mirror = base,
                        rid = rid,
                        version = version,
                    ))
            candidate_urls.append("https://dotnetcli.azureedge.net/dotnet/Sdk/{}/{}".format(version, archive))

            integrity = ""
            if version in DOTNET_ARTIFACTS and rid in DOTNET_ARTIFACTS[version]:
                integrity = DOTNET_ARTIFACTS[version][rid]["sdk"]

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
        urls = ["https://api.nuget.org/v3-flatcontainer/coverlet.console/10.1.0/coverlet.console.10.1.0.nupkg"],
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
    doc = "Configures NuGet package resolution from lockfile definitions.",
    attrs = {
        "auth_patterns": attr.string_dict(
            doc = "Host to authentication pattern mappings.",
        ),
        "directory_packages_props": attr.label(
            doc = "Path to Directory.Packages.props file.",
        ),
        "feeds": attr.string_list(
            doc = "Candidate package feed URLs.",
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
            doc = "Path to packages.lock.json lockfile.",
            mandatory = True,
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
    sources = []
    sources_block = _extract_block(content, "<packageSources>", "</packageSources>")
    if sources_block:
        for line in sources_block.splitlines():
            line = line.strip()
            if line.startswith("<clear") or "<clear/>" in line or "<clear />" in line:
                sources = []
            elif line.startswith("<add"):
                val = _extract_attr(line, "value")
                if val:
                    sources.append(val)
    return sources

def _sanitize_name(name):
    return name.replace(".", "_").replace("-", "_").lower()

def _nuget_impl(module_ctx):
    packages = {}
    hub_name = "nuget"
    feeds = []
    local_dirs = []
    netrc = None
    auth_patterns = {}

    for mod in module_ctx.modules:
        for tag in mod.tags.from_lock:
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
                parsed_sources = _parse_nuget_config(xml_content)
                if parsed_sources:
                    feeds = parsed_sources

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

    hub_packages = {}
    for pkg_id, info in packages.items():
        repo_name = "nuget_" + _sanitize_name(pkg_id)
        hub_packages[pkg_id] = repo_name
        nuget_package_repo(
            name = repo_name,
            auth_patterns = auth_patterns,
            content_hash = info["content_hash"],
            dependencies = info["dependencies"],
            feeds = feeds,
            local_package_dirs = local_dirs,
            netrc = netrc,
            package_id = pkg_id,
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
