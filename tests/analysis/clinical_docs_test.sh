#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "Running Clinical Documentation Standards and Anti-Slop Test"
echo "============================================================"

# Python script to verify documentation diff and forbidden tokens
python3 - << 'EOF'
import difflib
import os
import pathlib
import re
import sys

# 1. Locate reference README.md and generated Stardoc README.md
ref_readme = None
gen_readme = None

# Search locations in runfiles and working directory
for candidate in ["README.md", "rules_csharp/README.md"]:
    if os.path.exists(candidate) and not candidate.startswith("csharp/"):
        ref_readme = pathlib.Path(candidate)
        break

if not ref_readme:
    # Search runfiles
    for root, dirs, files in os.walk("."):
        if "README.md" in files:
            p = pathlib.Path(root) / "README.md"
            if p.parent.name != "docs" and "external" not in str(p):
                ref_readme = p
                break

for candidate in ["docs/README.md", "rules_csharp/docs/README.md"]:
    if os.path.exists(candidate):
        gen_readme = pathlib.Path(candidate)
        break

if not gen_readme:
    for root, dirs, files in os.walk("."):
        if "README.md" in files:
            p = pathlib.Path(root) / "README.md"
            if p.parent.name == "docs":
                gen_readme = p
                break

if not ref_readme or not ref_readme.exists():
    print(f"FAILED: Could not locate reference README.md. Found candidates: {list(pathlib.Path('.').glob('**/*README.md'))}")
    sys.exit(1)

if not gen_readme or not gen_readme.exists():
    print(f"FAILED: Could not locate generated Stardoc README.md.")
    sys.exit(1)

print(f"Reference README: {ref_readme}")
print(f"Generated Stardoc README: {gen_readme}")

ref_lines = ref_readme.read_text(encoding="utf-8").splitlines(keepends=True)
gen_lines = gen_readme.read_text(encoding="utf-8").splitlines(keepends=True)

diff = list(difflib.unified_diff(
    ref_lines,
    gen_lines,
    fromfile=str(ref_readme),
    tofile=str(gen_readme),
))

if diff:
    print("FAILED: Stardoc generation diffs from reference README.md:")
    sys.stdout.writelines(diff)
    sys.exit(1)

print("Documentation parity check passed: 0 diff between README.md and Stardoc output.")

# 2. Anti-Slop Regex Verification
# Forbidden:
# - Second-person pronouns: you, your
# - Conversational preambles: This rule allows, In order to, It is important to note
# - Qualitative filler: seamlessly, easily, powerful, modern, robust, effortlessly
# - Transitional filler: furthermore, additionally, moreover
# - Em-dash: — or \u2014

FORBIDDEN_PATTERNS = [
    (re.compile(r"\b(you|your|You|Your)\b"), "second-person pronoun"),
    (re.compile(r"(This rule allows|In order to|It is important to note)", re.IGNORECASE), "conversational preamble"),
    (re.compile(r"\b(seamlessly|easily|powerful|modern|robust|effortlessly)\b", re.IGNORECASE), "qualitative filler"),
    (re.compile(r"\b(furthermore|additionally|moreover)\b", re.IGNORECASE), "transitional filler"),
    (re.compile(r"—|\u2014"), "em-dash"),
]

violations = []

files_to_scan = [ref_readme]
for root, dirs, files in os.walk("."):
    if "external" in root:
        continue
    for f in files:
        if f.endswith(".bzl") and "csharp" in root:
            files_to_scan.append(pathlib.Path(root) / f)

print(f"Scanning {len(files_to_scan)} files for anti-slop compliance...")

for p in sorted(set(files_to_scan)):
    lines = p.read_text(encoding="utf-8").splitlines()
    for lineno, line in enumerate(lines, start=1):
        for pattern, category in FORBIDDEN_PATTERNS:
            m = pattern.search(line)
            if m:
                violations.append((str(p), lineno, category, m.group(0), line.strip()))

if violations:
    print(f"FAILED: Found {len(violations)} anti-slop violations:")
    for filepath, lineno, category, match_str, line_text in violations:
        print(f"  {filepath}:{lineno}: [{category}] '{match_str}' in: {line_text}")
    sys.exit(1)

print(f"Anti-slop compliance verified: zero forbidden tokens or em-dashes found across {len(files_to_scan)} files.")
EOF

echo "All clinical documentation and anti-slop checks passed successfully."
exit 0
