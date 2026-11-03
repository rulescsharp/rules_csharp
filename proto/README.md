<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Protobuf and gRPC rules for rules_csharp.

These rules live in the `rules_csharp_proto` module so the core `rules_csharp` module carries no
protobuf dependency. Add both modules to `MODULE.bazel`:

```starlark
bazel_dep(name = "rules_csharp", version = "0.4.0")
bazel_dep(name = "rules_csharp_proto", version = "0.4.0")
```

Then load the rules from this file:

```starlark
load("@rules_csharp_proto//csharp:defs.bzl", "csharp_grpc_library", "csharp_proto_library")
```

The rules run protoc from protobuf's proto toolchain. By default that's protoc built from source,
which needs a C++17 compiler. To use the prebuilt protoc that protobuf publishes, add this to
`.bazelrc`:

```
common --@protobuf//bazel/toolchains:prefer_prebuilt_protoc
```

On Bazel 7 and 8 also add `common --incompatible_enable_proto_toolchain_resolution`, or
`proto_library` keeps building protoc from source. Bazel 7's default C++ toolchain can't build it.

<a id="csharp_grpc_library"></a>

## csharp_grpc_library

<pre>
load("@rules_csharp_proto//csharp:defs.bzl", "csharp_grpc_library")

csharp_grpc_library(<a href="#csharp_grpc_library-name">name</a>, <a href="#csharp_grpc_library-deps">deps</a>, <a href="#csharp_grpc_library-srcs">srcs</a>, <a href="#csharp_grpc_library-resources">resources</a>, <a href="#csharp_grpc_library-analyzers">analyzers</a>, <a href="#csharp_grpc_library-compile_refs">compile_refs</a>, <a href="#csharp_grpc_library-content">content</a>, <a href="#csharp_grpc_library-copy_to_output">copy_to_output</a>,
                    <a href="#csharp_grpc_library-defines">defines</a>, <a href="#csharp_grpc_library-dlls">dlls</a>, <a href="#csharp_grpc_library-exports">exports</a>, <a href="#csharp_grpc_library-generate_assembly_info">generate_assembly_info</a>, <a href="#csharp_grpc_library-implicit_usings">implicit_usings</a>,
                    <a href="#csharp_grpc_library-internals_visible_to">internals_visible_to</a>, <a href="#csharp_grpc_library-langversion">langversion</a>, <a href="#csharp_grpc_library-native_libs">native_libs</a>, <a href="#csharp_grpc_library-nowarn">nowarn</a>, <a href="#csharp_grpc_library-plugin">plugin</a>, <a href="#csharp_grpc_library-plugins">plugins</a>, <a href="#csharp_grpc_library-proto">proto</a>,
                    <a href="#csharp_grpc_library-runtime_dlls">runtime_dlls</a>, <a href="#csharp_grpc_library-sdk">sdk</a>, <a href="#csharp_grpc_library-target_framework">target_framework</a>, <a href="#csharp_grpc_library-target_type">target_type</a>, <a href="#csharp_grpc_library-warn_as_error">warn_as_error</a>, <a href="#csharp_grpc_library-warning_level">warning_level</a>)
</pre>

Compiles Protocol Buffer and gRPC service definitions into a C# assembly library.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="csharp_grpc_library-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="csharp_grpc_library-deps"></a>deps |  Direct dependency libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_grpc_library-srcs"></a>srcs |  C# source files to compile.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_grpc_library-resources"></a>resources |  Embedded resource files mapped to logical names.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_grpc_library-analyzers"></a>analyzers |  Precompiled Roslyn analyzer DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_grpc_library-compile_refs"></a>compile_refs |  Precompiled reference assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_grpc_library-content"></a>content |  Static content files copied to runtime directories.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_grpc_library-copy_to_output"></a>copy_to_output |  Files mapped to destination output paths.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_grpc_library-defines"></a>defines |  Preprocessor symbols to define during compilation.   | List of strings | optional |  `[]`  |
| <a id="csharp_grpc_library-dlls"></a>dlls |  Precompiled implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_grpc_library-exports"></a>exports |  Dependencies exported to downstream consumers.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_grpc_library-generate_assembly_info"></a>generate_assembly_info |  Synthesize assembly information attributes.   | Boolean | optional |  `True`  |
| <a id="csharp_grpc_library-implicit_usings"></a>implicit_usings |  Synthesize implicit global usings namespace imports.   | Boolean | optional |  `True`  |
| <a id="csharp_grpc_library-internals_visible_to"></a>internals_visible_to |  Friend assembly names for InternalsVisibleTo.   | List of strings | optional |  `[]`  |
| <a id="csharp_grpc_library-langversion"></a>langversion |  Target C# language version specification.   | String | optional |  `"latest"`  |
| <a id="csharp_grpc_library-native_libs"></a>native_libs |  Unmanaged target platform shared libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_grpc_library-nowarn"></a>nowarn |  Compiler diagnostic codes to suppress.   | List of strings | optional |  `[]`  |
| <a id="csharp_grpc_library-plugin"></a>plugin |  The grpc_csharp_plugin executable.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="csharp_grpc_library-plugins"></a>plugins |  Roslyn analyzer and generator plugins.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_grpc_library-proto"></a>proto |  Target providing ProtoInfo with proto sources.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="csharp_grpc_library-runtime_dlls"></a>runtime_dlls |  Precompiled runtime implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_grpc_library-sdk"></a>sdk |  Target .NET SDK project flavor.   | String | optional |  `"Microsoft.NET.Sdk"`  |
| <a id="csharp_grpc_library-target_framework"></a>target_framework |  Target framework moniker, one of net8.0, net9.0, net10.0. Picks the SDK, reference pack, and runtime the target builds and runs against, so its .NET version must be listed in `dotnet_versions` of `csharp.toolchain`. When unset, the target uses the framework of the target that depends on it, or the newest configured version when built directly.   | String | optional |  `""`  |
| <a id="csharp_grpc_library-target_type"></a>target_type |  Compiler target type output flag.   | String | optional |  `"library"`  |
| <a id="csharp_grpc_library-warn_as_error"></a>warn_as_error |  Treat compiler warnings as errors.   | Boolean | optional |  `False`  |
| <a id="csharp_grpc_library-warning_level"></a>warning_level |  Compiler diagnostic severity level.   | Integer | optional |  `4`  |


<a id="csharp_proto_library"></a>

## csharp_proto_library

<pre>
load("@rules_csharp_proto//csharp:defs.bzl", "csharp_proto_library")

csharp_proto_library(<a href="#csharp_proto_library-name">name</a>, <a href="#csharp_proto_library-deps">deps</a>, <a href="#csharp_proto_library-srcs">srcs</a>, <a href="#csharp_proto_library-resources">resources</a>, <a href="#csharp_proto_library-analyzers">analyzers</a>, <a href="#csharp_proto_library-compile_refs">compile_refs</a>, <a href="#csharp_proto_library-content">content</a>, <a href="#csharp_proto_library-copy_to_output">copy_to_output</a>,
                     <a href="#csharp_proto_library-defines">defines</a>, <a href="#csharp_proto_library-dlls">dlls</a>, <a href="#csharp_proto_library-exports">exports</a>, <a href="#csharp_proto_library-generate_assembly_info">generate_assembly_info</a>, <a href="#csharp_proto_library-implicit_usings">implicit_usings</a>,
                     <a href="#csharp_proto_library-internals_visible_to">internals_visible_to</a>, <a href="#csharp_proto_library-langversion">langversion</a>, <a href="#csharp_proto_library-native_libs">native_libs</a>, <a href="#csharp_proto_library-nowarn">nowarn</a>, <a href="#csharp_proto_library-plugins">plugins</a>, <a href="#csharp_proto_library-proto">proto</a>,
                     <a href="#csharp_proto_library-runtime_dlls">runtime_dlls</a>, <a href="#csharp_proto_library-sdk">sdk</a>, <a href="#csharp_proto_library-target_framework">target_framework</a>, <a href="#csharp_proto_library-target_type">target_type</a>, <a href="#csharp_proto_library-warn_as_error">warn_as_error</a>, <a href="#csharp_proto_library-warning_level">warning_level</a>)
</pre>

Compiles Protocol Buffer definitions into a C# assembly library.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="csharp_proto_library-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="csharp_proto_library-deps"></a>deps |  Direct dependency libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_proto_library-srcs"></a>srcs |  C# source files to compile.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_proto_library-resources"></a>resources |  Embedded resource files mapped to logical names.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_proto_library-analyzers"></a>analyzers |  Precompiled Roslyn analyzer DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_proto_library-compile_refs"></a>compile_refs |  Precompiled reference assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_proto_library-content"></a>content |  Static content files copied to runtime directories.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_proto_library-copy_to_output"></a>copy_to_output |  Files mapped to destination output paths.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_proto_library-defines"></a>defines |  Preprocessor symbols to define during compilation.   | List of strings | optional |  `[]`  |
| <a id="csharp_proto_library-dlls"></a>dlls |  Precompiled implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_proto_library-exports"></a>exports |  Dependencies exported to downstream consumers.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_proto_library-generate_assembly_info"></a>generate_assembly_info |  Synthesize assembly information attributes.   | Boolean | optional |  `True`  |
| <a id="csharp_proto_library-implicit_usings"></a>implicit_usings |  Synthesize implicit global usings namespace imports.   | Boolean | optional |  `True`  |
| <a id="csharp_proto_library-internals_visible_to"></a>internals_visible_to |  Friend assembly names for InternalsVisibleTo.   | List of strings | optional |  `[]`  |
| <a id="csharp_proto_library-langversion"></a>langversion |  Target C# language version specification.   | String | optional |  `"latest"`  |
| <a id="csharp_proto_library-native_libs"></a>native_libs |  Unmanaged target platform shared libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_proto_library-nowarn"></a>nowarn |  Compiler diagnostic codes to suppress.   | List of strings | optional |  `[]`  |
| <a id="csharp_proto_library-plugins"></a>plugins |  Roslyn analyzer and generator plugins.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_proto_library-proto"></a>proto |  Target providing ProtoInfo with proto sources.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="csharp_proto_library-runtime_dlls"></a>runtime_dlls |  Precompiled runtime implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_proto_library-sdk"></a>sdk |  Target .NET SDK project flavor.   | String | optional |  `"Microsoft.NET.Sdk"`  |
| <a id="csharp_proto_library-target_framework"></a>target_framework |  Target framework moniker, one of net8.0, net9.0, net10.0. Picks the SDK, reference pack, and runtime the target builds and runs against, so its .NET version must be listed in `dotnet_versions` of `csharp.toolchain`. When unset, the target uses the framework of the target that depends on it, or the newest configured version when built directly.   | String | optional |  `""`  |
| <a id="csharp_proto_library-target_type"></a>target_type |  Compiler target type output flag.   | String | optional |  `"library"`  |
| <a id="csharp_proto_library-warn_as_error"></a>warn_as_error |  Treat compiler warnings as errors.   | Boolean | optional |  `False`  |
| <a id="csharp_proto_library-warning_level"></a>warning_level |  Compiler diagnostic severity level.   | Integer | optional |  `4`  |


