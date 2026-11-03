#!/usr/bin/env bash
# Fetches a signed nuget.org package through nuget.from_lock the way a user
# would, outside the rules_csharp workspace.
#
# Usage: fetch_test.sh <grpc address of a remote asset API server>
#
# 1. A fresh fetch through --experimental_remote_downloader passes.
# 2. A new output base with the same repository cache fetches with
#    --repository_disable_download.
# 3. A local feed with one flipped byte in the package fails and names it.
# 4. With use_public_sources = False, a feed without the package fails
#    instead of falling back to nuget.org, and a feed with it passes.
# 5. With use_public_sources = False, an empty contentHash fails, also when
#    a later tag leaves use_public_sources at its default.
# 6. A nuget_config with <clear /> and nuget.org's v3 index.json fetches from
#    nuget.org.
# 7. With use_public_sources = False, an SDK patch version pinned only in
#    sdk_checksums and coverlet.console come from a file mirror, and an empty
#    mirror fails instead of falling back to Microsoft's CDN, also when a later
#    tag leaves use_public_sources at its default.
#
# Output bases and feeds sit under a path with a space and a %.
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <remote downloader grpc address>" >&2
  exit 2
fi
REMOTE="$1"
RULES_CSHARP="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="$(mktemp -d)/fetch 100% test"
mkdir -p "$WORK"
OUTPUT_BASES=()

cleanup() {
  for ob in "${OUTPUT_BASES[@]}"; do
    bazel --output_base="$ob" shutdown >/dev/null 2>&1 || true
  done
  chmod -R u+w "$WORK" 2>/dev/null || true
  rm -rf "$(dirname "$WORK")"
}
trap cleanup EXIT

# PolySharp 1.14.1 is repository signed on nuget.org. The contentHash is the
# one dotnet restore writes, which covers the package without its signature.
PACKAGE_ID=PolySharp
PACKAGE_VERSION=1.14.1
CONTENT_HASH="mOOmFYwad3MIOL14VCjj02LljyF1GNw1wP0YVlxtcPvqdxjGGMNdNJJxHptlry3MOd8b40Flm8RPOM8JOlN2sQ=="

write_module() {
  local dir="$1" from_lock="$2" content_hash="${3-$CONTENT_HASH}"
  mkdir -p "$dir"
  cat >"$dir/MODULE.bazel" <<MODULE
bazel_dep(name = "rules_csharp")
local_path_override(
    module_name = "rules_csharp",
    path = "$RULES_CSHARP",
)

nuget = use_extension("@rules_csharp//csharp:extensions.bzl", "nuget")
nuget.from_lock(
    $from_lock
)
use_repo(nuget, "nuget_polysharp")
MODULE
  touch "$dir/BUILD.bazel"
  cat >"$dir/packages.lock.json" <<LOCK
{
  "version": 2,
  "dependencies": {
    "net8.0": {
      "$PACKAGE_ID": {
        "type": "Direct",
        "requested": "[$PACKAGE_VERSION, )",
        "resolved": "$PACKAGE_VERSION",
        "contentHash": "$content_hash"
      }
    }
  }
}
LOCK
}

# Runs bazel query on the package in a module with its own output base.
fetch() {
  local dir="$1" ob="$2"
  shift 2
  OUTPUT_BASES+=("$ob")
  (cd "$dir" && bazel --output_base="$ob" query "$@" @nuget_polysharp//:PolySharp)
}

REPO_CACHE="$WORK/repository cache"

echo "--- fresh fetch through the remote downloader"
write_module "$WORK/module" 'packages_lock_json = "//:packages.lock.json",'
fetch "$WORK/module" "$WORK/output base 1" \
  --repository_cache="$REPO_CACHE" \
  --experimental_remote_downloader="$REMOTE" \
  --remote_cache="$REMOTE"

echo "--- new output base, same repository cache, downloads disabled"
fetch "$WORK/module" "$WORK/output base 2" \
  --repository_cache="$REPO_CACHE" \
  --repository_disable_download

echo "--- tampered package in a local feed"
FEED="$WORK/local feed"
mkdir -p "$FEED"
NUPKG="$FEED/$PACKAGE_ID.$PACKAGE_VERSION.nupkg"
curl -fsSL -o "$NUPKG" \
  "https://api.nuget.org/v3-flatcontainer/polysharp/$PACKAGE_VERSION/polysharp.$PACKAGE_VERSION.nupkg"
# Offset 100 is inside the compressed _rels/.rels, the first entry, which the
# contentHash covers.
byte=$(od -An -tu1 -j100 -N1 "$NUPKG" | tr -d ' ')
printf "$(printf '\\%03o' $((byte ^ 1)))" | dd of="$NUPKG" bs=1 seek=100 conv=notrunc 2>/dev/null
write_module "$WORK/tampered" "packages_lock_json = \"//:packages.lock.json\",
    local_package_dirs = [\"$FEED\"],"
if fetch "$WORK/tampered" "$WORK/output base 3" \
  --repository_cache="$REPO_CACHE" >"$WORK/tampered.log" 2>&1; then
  cat "$WORK/tampered.log"
  echo "FAIL: the tampered package fetched" >&2
  exit 1
fi
if ! grep -q "$PACKAGE_ID $PACKAGE_VERSION: the downloaded package does not match its contentHash" "$WORK/tampered.log"; then
  cat "$WORK/tampered.log"
  echo "FAIL: the tampered fetch failed without naming the package" >&2
  exit 1
fi

echo "--- public sources off, feed without the package"
EMPTY_FEED="$WORK/empty feed"
mkdir -p "$EMPTY_FEED"
write_module "$WORK/private missing" "packages_lock_json = \"//:packages.lock.json\",
    local_package_dirs = [\"$EMPTY_FEED\"],
    use_public_sources = False,"
if fetch "$WORK/private missing" "$WORK/output base 4" >"$WORK/private_missing.log" 2>&1; then
  cat "$WORK/private_missing.log"
  echo "FAIL: the package fetched from a public source" >&2
  exit 1
fi
if grep -q "api.nuget.org" "$WORK/private_missing.log"; then
  cat "$WORK/private_missing.log"
  echo "FAIL: the fetch tried nuget.org" >&2
  exit 1
fi

echo "--- public sources off, feed with the package"
PRIVATE_FEED="$WORK/private feed"
mkdir -p "$PRIVATE_FEED"
curl -fsSL -o "$PRIVATE_FEED/$PACKAGE_ID.$PACKAGE_VERSION.nupkg" \
  "https://api.nuget.org/v3-flatcontainer/polysharp/$PACKAGE_VERSION/polysharp.$PACKAGE_VERSION.nupkg"
write_module "$WORK/private" "packages_lock_json = \"//:packages.lock.json\",
    local_package_dirs = [\"$PRIVATE_FEED\"],
    use_public_sources = False,"
fetch "$WORK/private" "$WORK/output base 5"

echo "--- public sources off, empty contentHash"
write_module "$WORK/no hash" "packages_lock_json = \"//:packages.lock.json\",
    local_package_dirs = [\"$PRIVATE_FEED\"],
    use_public_sources = False," ""
if fetch "$WORK/no hash" "$WORK/output base 6" >"$WORK/no_hash.log" 2>&1; then
  cat "$WORK/no_hash.log"
  echo "FAIL: a package with an empty contentHash fetched" >&2
  exit 1
fi
if ! grep -q "$PACKAGE_ID $PACKAGE_VERSION has an empty contentHash" "$WORK/no_hash.log"; then
  cat "$WORK/no_hash.log"
  echo "FAIL: the empty contentHash fetch failed without naming the package" >&2
  exit 1
fi

echo "--- public sources off in one tag, empty contentHash in a later tag"
write_module "$WORK/two tags" "packages_lock_json = \"//:empty.lock.json\",
    local_package_dirs = [\"$PRIVATE_FEED\"],
    use_public_sources = False,"
echo '{"version": 2, "dependencies": {}}' >"$WORK/two tags/empty.lock.json"
cp "$WORK/no hash/packages.lock.json" "$WORK/two tags/no_hash.lock.json"
cat >>"$WORK/two tags/MODULE.bazel" <<MODULE
nuget.from_lock(
    packages_lock_json = "//:no_hash.lock.json",
)
MODULE
if fetch "$WORK/two tags" "$WORK/output base 9" >"$WORK/two_tags.log" 2>&1; then
  cat "$WORK/two_tags.log"
  echo "FAIL: a later tag turned public sources back on" >&2
  exit 1
fi
if ! grep -q "$PACKAGE_ID $PACKAGE_VERSION has an empty contentHash" "$WORK/two_tags.log"; then
  cat "$WORK/two_tags.log"
  echo "FAIL: the two tag fetch failed without naming the package" >&2
  exit 1
fi

echo "--- nuget_config with <clear /> and nuget.org's index.json"
write_module "$WORK/nuget config" 'packages_lock_json = "//:packages.lock.json",
    nuget_config = "//:NuGet.Config",'
cat >"$WORK/nuget config/NuGet.Config" <<CONFIG
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" />
  </packageSources>
</configuration>
CONFIG
fetch "$WORK/nuget config" "$WORK/output base 10"

# 8.0.404 isn't one of the SDKs rules_csharp knows, so only sdk_checksums
# pins it. The hash is the one releases.json lists for the file.
SDK_VERSION=8.0.404
SDK_ARCHIVE="dotnet-sdk-$SDK_VERSION-linux-x64.tar.gz"
SDK_SHA512=2f166f7f3bd508154d72d1783ffac6e0e3c92023ccc2c6de49d22b411fc8b9e6dd03e7576acc1bb5870a6951181129ba77f3bf94bb45fe9c70105b1b896b9bb9
SDK_MIRROR="$WORK/sdk mirror"
COVERLET=coverlet.console.10.1.0.nupkg

write_sdk_module() {
  local dir="$1" mirror_url="$2"
  mkdir -p "$dir"
  cat >"$dir/MODULE.bazel" <<MODULE
bazel_dep(name = "rules_csharp")
local_path_override(
    module_name = "rules_csharp",
    path = "$RULES_CSHARP",
)

csharp = use_extension("@rules_csharp//csharp:extensions.bzl", "csharp")
csharp.toolchain(
    dotnet_versions = ["$SDK_VERSION"],
    mirror_urls = ["$mirror_url"],
    sdk_checksums = {"$SDK_ARCHIVE": "$SDK_SHA512"},
    use_public_sources = False,
)
use_repo(csharp, "csharp_coverlet", "dotnet_sdk_8_0_404_linux_x86_64")
MODULE
  touch "$dir/BUILD.bazel"
}

# file:// URL of a path, with the space and % escaped.
file_url() {
  local path="${1//%/%25}"
  echo "file://${path// /%20}"
}

echo "--- public sources off, SDK and coverlet from an empty mirror"
EMPTY_MIRROR="$WORK/empty mirror"
mkdir -p "$EMPTY_MIRROR"
write_sdk_module "$WORK/sdk missing" "$(file_url "$EMPTY_MIRROR")"
OUTPUT_BASES+=("$WORK/output base 7")
if (cd "$WORK/sdk missing" && bazel --output_base="$WORK/output base 7" query --repository_cache="$WORK/sdk repo cache" @dotnet_sdk_8_0_404_linux_x86_64//:all) >"$WORK/sdk_missing.log" 2>&1; then
  cat "$WORK/sdk_missing.log"
  echo "FAIL: the SDK fetched from a public source" >&2
  exit 1
fi
if grep -q "azureedge.net" "$WORK/sdk_missing.log"; then
  cat "$WORK/sdk_missing.log"
  echo "FAIL: the SDK fetch tried Microsoft's CDN" >&2
  exit 1
fi

echo "--- public sources off in one toolchain tag, default in a later tag"
write_sdk_module "$WORK/sdk two tags" "$(file_url "$EMPTY_MIRROR")"
cat >>"$WORK/sdk two tags/MODULE.bazel" <<MODULE
csharp.toolchain(
    dotnet_versions = ["$SDK_VERSION"],
)
MODULE
OUTPUT_BASES+=("$WORK/output base 11")
if (cd "$WORK/sdk two tags" && bazel --output_base="$WORK/output base 11" query --repository_cache="$WORK/sdk repo cache" @dotnet_sdk_8_0_404_linux_x86_64//:all) >"$WORK/sdk_two_tags.log" 2>&1; then
  cat "$WORK/sdk_two_tags.log"
  echo "FAIL: a later toolchain tag turned public sources back on" >&2
  exit 1
fi
if grep -q "azureedge.net" "$WORK/sdk_two_tags.log"; then
  cat "$WORK/sdk_two_tags.log"
  echo "FAIL: the SDK fetch tried Microsoft's CDN" >&2
  exit 1
fi

echo "--- public sources off, SDK and coverlet from a mirror"
mkdir -p "$SDK_MIRROR/dotnet/Sdk/$SDK_VERSION"
curl -fsSL -o "$SDK_MIRROR/dotnet/Sdk/$SDK_VERSION/$SDK_ARCHIVE" \
  "https://builds.dotnet.microsoft.com/dotnet/Sdk/$SDK_VERSION/$SDK_ARCHIVE"
curl -fsSL -o "$SDK_MIRROR/$COVERLET" \
  "https://api.nuget.org/v3-flatcontainer/coverlet.console/10.1.0/$COVERLET"
write_sdk_module "$WORK/sdk" "$(file_url "$SDK_MIRROR")"
OUTPUT_BASES+=("$WORK/output base 8")
(cd "$WORK/sdk" && bazel --output_base="$WORK/output base 8" query \
  --repository_cache="$WORK/sdk repo cache" "@dotnet_sdk_8_0_404_linux_x86_64//:all + @csharp_coverlet//:files")

echo "PASS"
