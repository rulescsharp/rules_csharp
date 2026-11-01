"""Defines common constants and utility definitions for compilation rules."""

load("//csharp:toolchains.bzl", "DOTNET_ARTIFACTS", "version_to_tfm")

CS_EXTENSION = ".cs"
DLL_EXTENSION = ".dll"
PDB_EXTENSION = ".pdb"
REFOUT_EXTENSION = ".ref.dll"

TARGET_FRAMEWORKS = [version_to_tfm(v) for v in DOTNET_ARTIFACTS]

TARGET_FRAMEWORK_DOC = """Target framework moniker, one of {}. Picks the SDK, reference pack, and runtime the target \
builds and runs against, so its .NET version must be listed in `dotnet_versions` of `csharp.toolchain`. When unset, the \
target uses the framework of the target that depends on it, or the newest configured version when built directly.""".format(", ".join(TARGET_FRAMEWORKS))

_TFM_FLAG = str(Label("//csharp/settings:target_framework"))

def _target_framework_transition_impl(settings, attr):
    return {_TFM_FLAG: attr.target_framework or settings[_TFM_FLAG]}

# Selects the toolchain for the target's framework. Targets that leave it unset follow their dependent.
target_framework_transition = transition(
    implementation = _target_framework_transition_impl,
    inputs = [_TFM_FLAG],
    outputs = [_TFM_FLAG],
)
