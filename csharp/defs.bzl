"""Public API for rules_csharp.

Works with Bazel 7, 8 and 9 with Bzlmod, on Linux, macOS and Windows.

Compiled assemblies and pdbs record source paths under `/_/` instead of the absolute build path, so
outputs are identical across machines and sandboxes. Map `/_/` to the workspace root in a debugger to
step into sources.

`csharp_proto_library` and `csharp_grpc_library` live in the separate `rules_csharp_proto` module, so
the core module pulls in no protobuf. See [rules_csharp_proto](../proto/README.md) for setup. The names
below remain as stubs that fail the build with migration steps.
"""

load("//csharp/private:binary.bzl", _csharp_binary = "csharp_binary", _csharp_test = "csharp_test")
load(
    "//csharp/private:compile.bzl",
    _csharp_analyzer_import = "csharp_analyzer_import",
    _csharp_analyzer_library = "csharp_analyzer_library",
    _csharp_import = "csharp_import",
    _csharp_library = "csharp_library",
)
load(
    "//csharp/private:providers.bzl",
    _CSharpAnalyzerInfo = "CSharpAnalyzerInfo",
    _CSharpInfo = "CSharpInfo",
    _CSharpToolchainInfo = "CSharpToolchainInfo",
)
load(
    "//csharp/private:proto_moved.bzl",
    _csharp_grpc_library = "csharp_grpc_library",
    _csharp_proto_library = "csharp_proto_library",
)

csharp_library = _csharp_library
csharp_binary = _csharp_binary
csharp_test = _csharp_test
csharp_analyzer_library = _csharp_analyzer_library
csharp_import = _csharp_import
csharp_analyzer_import = _csharp_analyzer_import
csharp_proto_library = _csharp_proto_library
csharp_grpc_library = _csharp_grpc_library

CSharpInfo = _CSharpInfo
CSharpAnalyzerInfo = _CSharpAnalyzerInfo
CSharpToolchainInfo = _CSharpToolchainInfo
