#!/usr/bin/env bash
# Writes the release version into both modules before the archive is made, so the
# rules_csharp_proto that BCR gets depends on the rules_csharp released with it.
set -euo pipefail
VERSION="$1"

# The version line inside the module() call, and in proto/ the rules_csharp bazel_dep.
sed -i -E "/^module\(/,/^\)/s/version = \"[^\"]+\"/version = \"${VERSION}\"/" MODULE.bazel proto/MODULE.bazel
sed -i -E "s/^bazel_dep\(name = \"rules_csharp\", version = \"[^\"]+\"\)$/bazel_dep(name = \"rules_csharp\", version = \"${VERSION}\")/" proto/MODULE.bazel

# Fail if a file changed anywhere else, or if a line we need didn't take the version.
test "$(git diff -U0 MODULE.bazel | grep -c '^+[^+]')" -le 1
test "$(git diff -U0 proto/MODULE.bazel | grep -c '^+[^+]')" -le 2
grep -qx "    version = \"${VERSION}\"," MODULE.bazel
grep -qx "    version = \"${VERSION}\"," proto/MODULE.bazel
grep -qx "bazel_dep(name = \"rules_csharp\", version = \"${VERSION}\")" proto/MODULE.bazel
