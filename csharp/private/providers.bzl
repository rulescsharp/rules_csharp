"""Providers for compilation, tooling, and runtime artifacts."""

CSharpInfo = provider(
    doc = "Propagates compilation references, runtime assemblies, and unmanaged libraries.",
    fields = {
        "compile_ref": "Metadata-only reference assembly File produced by -refout.",
        "friend_refs": "Depset of structs with `public` and `internal` reference assembly Files and the `friends` assembly names of each library with `internals_visible_to`. A friend compiles against `internal`, every other dependent against `public`. Providers created before this field existed lack it, so read it with getattr.",
        "framework_references": "Depset of shared framework names (for example Microsoft.AspNetCore.App) this target and its dependencies need at compile time and run time. Providers created before this field existed lack it, so read it with getattr.",
        "pdb": "Portable program database symbol File.",
        "runtime_dll": "Implementation assembly File.",
        "target_framework": "Target framework moniker string (for example net8.0).",
        "transitive_compile_refs": "Depset of reference assembly Files for compilation.",
        "transitive_native_libs": "Depset of target platform unmanaged shared libraries.",
        "transitive_runtime_dlls": "Depset of runtime assembly Files for execution.",
        "transitive_satellites": "Depset of satellite resource assembly Files, each in a directory named after its culture, such as `fr/Name.resources.dll`. Providers created before this field existed lack it, so read it with getattr.",
        "transitive_test_runtime_dlls": "Depset of Files that a library csharp_test stages next to the test assembly, such as VSTest adapters. Optional, treated as empty when unset.",
        "xml_doc": "XML documentation File written with `generate_documentation_file`, or None. Providers created before this field existed lack it, so read it with getattr.",
    },
)

CSharpAnalyzerInfo = provider(
    doc = "Propagates Roslyn analyzer and source generator assembly files.",
    fields = {
        "analyzers": "Depset of Roslyn analyzer and generator assembly Files.",
    },
)

CSharpToolchainInfo = provider(
    doc = "Defines resolved C# SDK tools, packs, and target monikers.",
    fields = {
        "aspnetcore_ref_pack": "Depset of reference assembly Files for Microsoft.AspNetCore.App.",
        "csc_dll": "Host File for Roslyn compiler assembly.",
        "csc_worker": "Host executable File for persistent compilation worker.",
        "csc_worker_files": "Depset of files required by csc_worker.",
        "dotnet_env": "Dictionary of sealed environment variables for hermetic dotnet execution.",
        "dotnet_muxer": "Host executable File for dotnet driver.",
        "host_pack": "Binary template File for target platform application host.",
        "host_rid": "Host runtime identifier string.",
        "ref_pack": "Depset of reference assembly Files for target framework.",
        "runtime_pack": "Depset of runtime assembly Files for target platform.",
        "target_framework": "Target framework moniker string.",
        "target_rid": "Target runtime identifier string.",
        "vstest_dll": "Host File for vstest.console.dll.",
    },
)
