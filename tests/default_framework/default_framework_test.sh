#!/usr/bin/env bash
# Builds a target without target_framework in a module whose only SDK is
# 9.0, outside the rules_csharp workspace. Its NuGet package must load the
# lib/net9.0 assembly, not the package's newer lib/net10.0.
set -euo pipefail

RULES_CSHARP="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="$(mktemp -d)"
trap 'bazel --output_base="$WORK/output_base" shutdown >/dev/null 2>&1 || true; chmod -R u+w "$WORK"; rm -rf "$WORK"' EXIT

MODULE="$WORK/module"
mkdir -p "$MODULE"
cp "$RULES_CSHARP/tests/integration/packages.lock.json" "$RULES_CSHARP/tests/integration/PackageAssetsTest.cs" "$MODULE"
cat >"$MODULE/MODULE.bazel" <<MODULE_BAZEL
bazel_dep(name = "rules_csharp")
local_path_override(
    module_name = "rules_csharp",
    path = "$RULES_CSHARP",
)

csharp = use_extension("@rules_csharp//csharp:extensions.bzl", "csharp")
csharp.toolchain(dotnet_versions = ["9.0.200"])

nuget = use_extension("@rules_csharp//csharp:extensions.bzl", "nuget")
nuget.from_lock(packages_lock_json = "//:packages.lock.json")
use_repo(nuget, "nuget")
MODULE_BAZEL
cat >"$MODULE/BUILD.bazel" <<'BUILD_BAZEL'
load("@rules_csharp//csharp:defs.bzl", "csharp_test")

csharp_test(
    name = "package_assets_test",
    srcs = ["PackageAssetsTest.cs"],
    env = {"EXPECTED_FRAMEWORK": ".NETCoreApp,Version=v9.0"},
    deps = ["@nuget//:Microsoft.Extensions.Logging.Abstractions"],
)
BUILD_BAZEL

cd "$MODULE"
bazel --output_base="$WORK/output_base" test --lockfile_mode=off --test_output=errors //:package_assets_test
