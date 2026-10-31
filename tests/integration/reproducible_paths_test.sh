#!/usr/bin/env bash
set -euo pipefail

# Absolute build paths in a dll or pdb make outputs differ per machine, output base and sandbox.
DLL=$(find -L . -path "*tests/integration/lib.dll" | head -n 1)
PDB=$(find -L . -path "*tests/integration/lib.pdb" | head -n 1)
if [[ -z "$DLL" || -z "$PDB" ]]; then
    echo "FAILED: lib.dll or lib.pdb not found in runfiles."
    exit 1
fi

for f in "$DLL" "$PDB"; do
    if grep -a -q -e execroot -e sandbox "$f"; then
        echo "FAILED: $f embeds an absolute build path:"
        grep -a -o -E '[^[:cntrl:]]*(execroot|sandbox)[^[:cntrl:]]*' "$f" | head -n 3
        exit 1
    fi
done

if ! grep -a -q "/_/" "$DLL"; then
    echo "FAILED: $DLL has no /_/ mapped pdb path."
    exit 1
fi

echo "PASSED: lib.dll and lib.pdb carry only mapped paths."
