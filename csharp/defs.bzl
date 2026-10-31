"""Public API for rules_csharp.

Compiled assemblies and pdbs record source paths under `/_/` instead of the absolute build path, so
outputs are identical across machines and sandboxes. Map `/_/` to the workspace root in a debugger to
step into sources.
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
    "//csharp:proto.bzl",
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
