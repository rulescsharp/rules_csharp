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
  local dir="$1" from_lock="$2"
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
        "contentHash": "$CONTENT_HASH"
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

echo "PASS"
