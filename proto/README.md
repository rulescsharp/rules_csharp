<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Protobuf and gRPC rules for rules_csharp.

These rules live in the `rules_csharp_proto` module so the core `rules_csharp` module carries no
protobuf dependency. Add both modules to `MODULE.bazel`:

```starlark
bazel_dep(name = "rules_csharp", version = "0.5.0")
bazel_dep(name = "rules_csharp_proto", version = "0.5.0")
```

Then load the rules from this file:

```starlark
load("@rules_csharp_proto//csharp:defs.bzl", "csharp_grpc_library", "csharp_proto_library")
```

Each `csharp_proto_library` compiles the `.proto` files of one `proto_library`. When `order.proto`
imports `money.proto` from another `proto_library`, give that one its own `csharp_proto_library`
and put it in `deps` or `exports`. List it there directly, since a `csharp_library` that re-exports
it isn't seen. Protos whose C# ships in a NuGet package other than `Google.Protobuf` need their own
`csharp_proto_library` too. The generated code also needs the `Google.Protobuf` package, which has
the well-known types such as `google.protobuf.Timestamp`:

```starlark
csharp_proto_library(
    name = "money_cs_proto",
    proto = ":money_proto",
    deps = ["@nuget//:Google.Protobuf"],
)

csharp_proto_library(
    name = "order_cs_proto",
    proto = ":order_proto",  # imports money.proto and google/protobuf/timestamp.proto
    deps = [
        ":money_cs_proto",
        "@nuget//:Google.Protobuf",
    ],
)
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

csharp_grpc_library(<a href="#csharp_grpc_library-name">name</a>, <a href="#csharp_grpc_library-deps">deps</a>, <a href="#csharp_grpc_library-srcs">srcs</a>, <a href="#csharp_grpc_library-data">data</a>, <a href="#csharp_grpc_library-resources">resources</a>, <a href="#csharp_grpc_library-additional_compiler_options">additional_compiler_options</a>,
                    <a href="#csharp_grpc_library-allow_unsafe_blocks">allow_unsafe_blocks</a>, <a href="#csharp_grpc_library-analyzers">analyzers</a>, <a href="#csharp_grpc_library-compile_refs">compile_refs</a>, <a href="#csharp_grpc_library-content">content</a>, <a href="#csharp_grpc_library-copy_to_output">copy_to_output</a>, <a href="#csharp_grpc_library-defines">defines</a>,
                    <a href="#csharp_grpc_library-dlls">dlls</a>, <a href="#csharp_grpc_library-editorconfig_files">editorconfig_files</a>, <a href="#csharp_grpc_library-exports">exports</a>, <a href="#csharp_grpc_library-framework_references">framework_references</a>, <a href="#csharp_grpc_library-generate_assembly_info">generate_assembly_info</a>,
                    <a href="#csharp_grpc_library-generate_documentation_file">generate_documentation_file</a>, <a href="#csharp_grpc_library-implicit_usings">implicit_usings</a>, <a href="#csharp_grpc_library-internals_visible_to">internals_visible_to</a>, <a href="#csharp_grpc_library-langversion">langversion</a>,
                    <a href="#csharp_grpc_library-native_libs">native_libs</a>, <a href="#csharp_grpc_library-nowarn">nowarn</a>, <a href="#csharp_grpc_library-output_assembly">output_assembly</a>, <a href="#csharp_grpc_library-plugin">plugin</a>, <a href="#csharp_grpc_library-plugins">plugins</a>, <a href="#csharp_grpc_library-proto">proto</a>, <a href="#csharp_grpc_library-runtime_dlls">runtime_dlls</a>, <a href="#csharp_grpc_library-sdk">sdk</a>,
                    <a href="#csharp_grpc_library-target_framework">target_framework</a>, <a href="#csharp_grpc_library-target_type">target_type</a>, <a href="#csharp_grpc_library-warn_as_error">warn_as_error</a>, <a href="#csharp_grpc_library-warning_level">warning_level</a>)
</pre>

Compiles Protocol Buffer and gRPC service definitions into a C# assembly library.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="csharp_grpc_library-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="csharp_grpc_library-deps"></a>deps |  Direct dependency libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_grpc_library-srcs"></a>srcs |  C# source files to compile.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_grpc_library-data"></a>data |  Files and targets needed at run time. Their files and runfiles join the runfiles of this target and of every executable that depends on it, along with the `content` of libraries it depends on.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_grpc_library-resources"></a>resources |  Embedded resource files mapped to logical names.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_grpc_library-additional_compiler_options"></a>additional_compiler_options |  Extra `csc` tokens appended after the rule's own flags, the same as MSBuild `AdditionalOptions`. Each entry is one token such as `-checked+` or `-highentropyva-`. Prefer the dedicated attributes (`defines`, `nowarn`, `langversion`, `warning_level`, `warn_as_error`) when they cover the flag. Empty entries and response files that start with `@` fail analysis.   | List of strings | optional |  `[]`  |
| <a id="csharp_grpc_library-allow_unsafe_blocks"></a>allow_unsafe_blocks |  Allows `unsafe` code, the same as MSBuild `AllowUnsafeBlocks`. Without it the compiler rejects any `unsafe` block or member with CS0227.   | Boolean | optional |  `False`  |
| <a id="csharp_grpc_library-analyzers"></a>analyzers |  Precompiled Roslyn analyzer DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_grpc_library-compile_refs"></a>compile_refs |  Precompiled reference assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_grpc_library-content"></a>content |  Static content files copied to runtime directories.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_grpc_library-copy_to_output"></a>copy_to_output |  Files mapped to destination output paths.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_grpc_library-defines"></a>defines |  Preprocessor symbols to define during compilation, the same as MSBuild `DefineConstants`. Every compilation mode except `-c opt` also defines `DEBUG` and `TRACE`, like the MSBuild Debug configuration. `-c opt` defines `TRACE` and `RELEASE` and turns on optimizations, like the Release configuration. Like dotnet build, every target also gets the symbols of its target framework: `NET`, `NETCOREAPP`, `NET<major>_0`, `NET5_0_OR_GREATER` up to `NET<major>_0_OR_GREATER`, and `NETCOREAPP1_0_OR_GREATER` up to `NETCOREAPP3_1_OR_GREATER`. So a `net8.0` target defines `NET8_0` and `NET8_0_OR_GREATER` but not `NET9_0_OR_GREATER`.   | List of strings | optional |  `[]`  |
| <a id="csharp_grpc_library-dlls"></a>dlls |  Precompiled implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_grpc_library-editorconfig_files"></a>editorconfig_files |  `.editorconfig` and global analyzer config files passed to the compiler with `-analyzerconfig`, the same as MSBuild `EditorConfigFiles` items. Sections such as `[*.cs]` match source paths under the directory of the file, so keep a `.editorconfig` next to or above the sources it covers. Severity settings such as `dotnet_diagnostic.CS8618.severity = none` apply to compiler warnings. CA and IDE rules come from analyzers, so they take effect only when the analyzer package is in `plugins` or `deps`.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_grpc_library-exports"></a>exports |  Dependencies exported to downstream consumers.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_grpc_library-framework_references"></a>framework_references |  Shared frameworks this target uses, the same as MSBuild `FrameworkReference` items. The only supported value is `"Microsoft.AspNetCore.App"`, since `Microsoft.NETCore.App` is always referenced. A target gets the framework's reference assemblies at compile time, and everything that depends on it gets them too, so an executable lists the framework in its runtimeconfig.json and the runtime loads it. `sdk = "Microsoft.NET.Sdk.Web"` implies `"Microsoft.AspNetCore.App"`.   | List of strings | optional |  `[]`  |
| <a id="csharp_grpc_library-generate_assembly_info"></a>generate_assembly_info |  Synthesize assembly information attributes.   | Boolean | optional |  `True`  |
| <a id="csharp_grpc_library-generate_documentation_file"></a>generate_documentation_file |  Writes the `///` comments to `<assembly>.xml` next to the dll, the same as MSBuild `GenerateDocumentationFile`. IDEs read that file to show the docs for anyone who references the assembly. Like MSBuild, the compiler then warns with CS1591 for each public member that has no `///` comment, which fails the build under `warn_as_error` unless `nowarn` lists it.   | Boolean | optional |  `False`  |
| <a id="csharp_grpc_library-implicit_usings"></a>implicit_usings |  Synthesize implicit global usings namespace imports.   | Boolean | optional |  `True`  |
| <a id="csharp_grpc_library-internals_visible_to"></a>internals_visible_to |  Friend assembly names for InternalsVisibleTo.   | List of strings | optional |  `[]`  |
| <a id="csharp_grpc_library-langversion"></a>langversion |  Target C# language version specification.   | String | optional |  `"latest"`  |
| <a id="csharp_grpc_library-native_libs"></a>native_libs |  Unmanaged target platform shared libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_grpc_library-nowarn"></a>nowarn |  Compiler diagnostic codes to suppress, the same as MSBuild `NoWarn`. CS1701 and CS1702 are always suppressed like in MSBuild, so a target on a newer framework than its dependencies builds quietly.   | List of strings | optional |  `[]`  |
| <a id="csharp_grpc_library-output_assembly"></a>output_assembly |  Name of the compiled assembly, the same as MSBuild `AssemblyName`. Defaults to the target name. It names the dll, pdb and reference assembly, and for executables the runtimeconfig.json and deps.json, and it is the default prefix of embedded resource names. The executable Bazel runs keeps the target name. Two assemblies with the same name can't load into one app, so an executable fails analysis when two of its assemblies share a name and one of them is built from sources.   | String | optional |  `""`  |
| <a id="csharp_grpc_library-plugin"></a>plugin |  The grpc_csharp_plugin executable.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="csharp_grpc_library-plugins"></a>plugins |  Roslyn analyzer and generator plugins.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_grpc_library-proto"></a>proto |  The `proto_library` whose `.proto` files this target compiles to C#. Protos it imports from other `proto_library` targets aren't compiled here. Put a `csharp_proto_library` for each of those directly in `deps` or `exports`, the same as a `ProjectReference` to the project that compiles them. A `csharp_library` that re-exports one isn't seen. Analysis fails and names the missing protos otherwise. The well-known types such as `google/protobuf/timestamp.proto` come from the `Google.Protobuf` package.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="csharp_grpc_library-runtime_dlls"></a>runtime_dlls |  Precompiled runtime implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_grpc_library-sdk"></a>sdk |  Project SDK the target follows, the same as the `Sdk` of an MSBuild project. `Microsoft.NET.Sdk.Web` adds the ASP.NET Core implicit usings, references `Microsoft.AspNetCore.App` and, for an executable, turns on server garbage collection (MSBuild `ServerGarbageCollection`) in its runtimeconfig.json. Other executables use workstation garbage collection and the default roll forward, which stays on their own .NET major version, like dotnet build. `Microsoft.NET.Sdk.Worker` adds the Microsoft.Extensions hosting usings and, as in MSBuild, no reference, so the target also needs `framework_references = ["Microsoft.AspNetCore.App"]` or the Microsoft.Extensions.Hosting NuGet package.   | String | optional |  `"Microsoft.NET.Sdk"`  |
| <a id="csharp_grpc_library-target_framework"></a>target_framework |  Target framework moniker, one of net8.0, net9.0, net10.0. Picks the SDK, reference pack, and runtime the target builds and runs against, so its .NET version must be listed in `dotnet_versions` of `csharp.toolchain`. When unset, the target uses the framework of the target that depends on it, or the newest configured version when built directly.   | String | optional |  `""`  |
| <a id="csharp_grpc_library-target_type"></a>target_type |  Compiler target type output flag.   | String | optional |  `"library"`  |
| <a id="csharp_grpc_library-warn_as_error"></a>warn_as_error |  Treat compiler warnings as errors, the same as MSBuild `TreatWarningsAsErrors`. Warnings that `nowarn` suppresses, and CS1701 and CS1702, never fail the build.   | Boolean | optional |  `False`  |
| <a id="csharp_grpc_library-warning_level"></a>warning_level |  Compiler diagnostic severity level.   | Integer | optional |  `4`  |


<a id="csharp_proto_library"></a>

## csharp_proto_library

<pre>
load("@rules_csharp_proto//csharp:defs.bzl", "csharp_proto_library")

csharp_proto_library(<a href="#csharp_proto_library-name">name</a>, <a href="#csharp_proto_library-deps">deps</a>, <a href="#csharp_proto_library-srcs">srcs</a>, <a href="#csharp_proto_library-data">data</a>, <a href="#csharp_proto_library-resources">resources</a>, <a href="#csharp_proto_library-additional_compiler_options">additional_compiler_options</a>,
                     <a href="#csharp_proto_library-allow_unsafe_blocks">allow_unsafe_blocks</a>, <a href="#csharp_proto_library-analyzers">analyzers</a>, <a href="#csharp_proto_library-compile_refs">compile_refs</a>, <a href="#csharp_proto_library-content">content</a>, <a href="#csharp_proto_library-copy_to_output">copy_to_output</a>, <a href="#csharp_proto_library-defines">defines</a>,
                     <a href="#csharp_proto_library-dlls">dlls</a>, <a href="#csharp_proto_library-editorconfig_files">editorconfig_files</a>, <a href="#csharp_proto_library-exports">exports</a>, <a href="#csharp_proto_library-framework_references">framework_references</a>, <a href="#csharp_proto_library-generate_assembly_info">generate_assembly_info</a>,
                     <a href="#csharp_proto_library-generate_documentation_file">generate_documentation_file</a>, <a href="#csharp_proto_library-implicit_usings">implicit_usings</a>, <a href="#csharp_proto_library-internals_visible_to">internals_visible_to</a>, <a href="#csharp_proto_library-langversion">langversion</a>,
                     <a href="#csharp_proto_library-native_libs">native_libs</a>, <a href="#csharp_proto_library-nowarn">nowarn</a>, <a href="#csharp_proto_library-output_assembly">output_assembly</a>, <a href="#csharp_proto_library-plugins">plugins</a>, <a href="#csharp_proto_library-proto">proto</a>, <a href="#csharp_proto_library-runtime_dlls">runtime_dlls</a>, <a href="#csharp_proto_library-sdk">sdk</a>,
                     <a href="#csharp_proto_library-target_framework">target_framework</a>, <a href="#csharp_proto_library-target_type">target_type</a>, <a href="#csharp_proto_library-warn_as_error">warn_as_error</a>, <a href="#csharp_proto_library-warning_level">warning_level</a>)
</pre>

Compiles Protocol Buffer definitions into a C# assembly library.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="csharp_proto_library-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="csharp_proto_library-deps"></a>deps |  Direct dependency libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_proto_library-srcs"></a>srcs |  C# source files to compile.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_proto_library-data"></a>data |  Files and targets needed at run time. Their files and runfiles join the runfiles of this target and of every executable that depends on it, along with the `content` of libraries it depends on.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_proto_library-resources"></a>resources |  Embedded resource files mapped to logical names.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_proto_library-additional_compiler_options"></a>additional_compiler_options |  Extra `csc` tokens appended after the rule's own flags, the same as MSBuild `AdditionalOptions`. Each entry is one token such as `-checked+` or `-highentropyva-`. Prefer the dedicated attributes (`defines`, `nowarn`, `langversion`, `warning_level`, `warn_as_error`) when they cover the flag. Empty entries and response files that start with `@` fail analysis.   | List of strings | optional |  `[]`  |
| <a id="csharp_proto_library-allow_unsafe_blocks"></a>allow_unsafe_blocks |  Allows `unsafe` code, the same as MSBuild `AllowUnsafeBlocks`. Without it the compiler rejects any `unsafe` block or member with CS0227.   | Boolean | optional |  `False`  |
| <a id="csharp_proto_library-analyzers"></a>analyzers |  Precompiled Roslyn analyzer DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_proto_library-compile_refs"></a>compile_refs |  Precompiled reference assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_proto_library-content"></a>content |  Static content files copied to runtime directories.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_proto_library-copy_to_output"></a>copy_to_output |  Files mapped to destination output paths.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_proto_library-defines"></a>defines |  Preprocessor symbols to define during compilation, the same as MSBuild `DefineConstants`. Every compilation mode except `-c opt` also defines `DEBUG` and `TRACE`, like the MSBuild Debug configuration. `-c opt` defines `TRACE` and `RELEASE` and turns on optimizations, like the Release configuration. Like dotnet build, every target also gets the symbols of its target framework: `NET`, `NETCOREAPP`, `NET<major>_0`, `NET5_0_OR_GREATER` up to `NET<major>_0_OR_GREATER`, and `NETCOREAPP1_0_OR_GREATER` up to `NETCOREAPP3_1_OR_GREATER`. So a `net8.0` target defines `NET8_0` and `NET8_0_OR_GREATER` but not `NET9_0_OR_GREATER`.   | List of strings | optional |  `[]`  |
| <a id="csharp_proto_library-dlls"></a>dlls |  Precompiled implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_proto_library-editorconfig_files"></a>editorconfig_files |  `.editorconfig` and global analyzer config files passed to the compiler with `-analyzerconfig`, the same as MSBuild `EditorConfigFiles` items. Sections such as `[*.cs]` match source paths under the directory of the file, so keep a `.editorconfig` next to or above the sources it covers. Severity settings such as `dotnet_diagnostic.CS8618.severity = none` apply to compiler warnings. CA and IDE rules come from analyzers, so they take effect only when the analyzer package is in `plugins` or `deps`.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_proto_library-exports"></a>exports |  Dependencies exported to downstream consumers.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_proto_library-framework_references"></a>framework_references |  Shared frameworks this target uses, the same as MSBuild `FrameworkReference` items. The only supported value is `"Microsoft.AspNetCore.App"`, since `Microsoft.NETCore.App` is always referenced. A target gets the framework's reference assemblies at compile time, and everything that depends on it gets them too, so an executable lists the framework in its runtimeconfig.json and the runtime loads it. `sdk = "Microsoft.NET.Sdk.Web"` implies `"Microsoft.AspNetCore.App"`.   | List of strings | optional |  `[]`  |
| <a id="csharp_proto_library-generate_assembly_info"></a>generate_assembly_info |  Synthesize assembly information attributes.   | Boolean | optional |  `True`  |
| <a id="csharp_proto_library-generate_documentation_file"></a>generate_documentation_file |  Writes the `///` comments to `<assembly>.xml` next to the dll, the same as MSBuild `GenerateDocumentationFile`. IDEs read that file to show the docs for anyone who references the assembly. Like MSBuild, the compiler then warns with CS1591 for each public member that has no `///` comment, which fails the build under `warn_as_error` unless `nowarn` lists it.   | Boolean | optional |  `False`  |
| <a id="csharp_proto_library-implicit_usings"></a>implicit_usings |  Synthesize implicit global usings namespace imports.   | Boolean | optional |  `True`  |
| <a id="csharp_proto_library-internals_visible_to"></a>internals_visible_to |  Friend assembly names for InternalsVisibleTo.   | List of strings | optional |  `[]`  |
| <a id="csharp_proto_library-langversion"></a>langversion |  Target C# language version specification.   | String | optional |  `"latest"`  |
| <a id="csharp_proto_library-native_libs"></a>native_libs |  Unmanaged target platform shared libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_proto_library-nowarn"></a>nowarn |  Compiler diagnostic codes to suppress, the same as MSBuild `NoWarn`. CS1701 and CS1702 are always suppressed like in MSBuild, so a target on a newer framework than its dependencies builds quietly.   | List of strings | optional |  `[]`  |
| <a id="csharp_proto_library-output_assembly"></a>output_assembly |  Name of the compiled assembly, the same as MSBuild `AssemblyName`. Defaults to the target name. It names the dll, pdb and reference assembly, and for executables the runtimeconfig.json and deps.json, and it is the default prefix of embedded resource names. The executable Bazel runs keeps the target name. Two assemblies with the same name can't load into one app, so an executable fails analysis when two of its assemblies share a name and one of them is built from sources.   | String | optional |  `""`  |
| <a id="csharp_proto_library-plugins"></a>plugins |  Roslyn analyzer and generator plugins.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_proto_library-proto"></a>proto |  The `proto_library` whose `.proto` files this target compiles to C#. Protos it imports from other `proto_library` targets aren't compiled here. Put a `csharp_proto_library` for each of those directly in `deps` or `exports`, the same as a `ProjectReference` to the project that compiles them. A `csharp_library` that re-exports one isn't seen. Analysis fails and names the missing protos otherwise. The well-known types such as `google/protobuf/timestamp.proto` come from the `Google.Protobuf` package.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="csharp_proto_library-runtime_dlls"></a>runtime_dlls |  Precompiled runtime implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_proto_library-sdk"></a>sdk |  Project SDK the target follows, the same as the `Sdk` of an MSBuild project. `Microsoft.NET.Sdk.Web` adds the ASP.NET Core implicit usings, references `Microsoft.AspNetCore.App` and, for an executable, turns on server garbage collection (MSBuild `ServerGarbageCollection`) in its runtimeconfig.json. Other executables use workstation garbage collection and the default roll forward, which stays on their own .NET major version, like dotnet build. `Microsoft.NET.Sdk.Worker` adds the Microsoft.Extensions hosting usings and, as in MSBuild, no reference, so the target also needs `framework_references = ["Microsoft.AspNetCore.App"]` or the Microsoft.Extensions.Hosting NuGet package.   | String | optional |  `"Microsoft.NET.Sdk"`  |
| <a id="csharp_proto_library-target_framework"></a>target_framework |  Target framework moniker, one of net8.0, net9.0, net10.0. Picks the SDK, reference pack, and runtime the target builds and runs against, so its .NET version must be listed in `dotnet_versions` of `csharp.toolchain`. When unset, the target uses the framework of the target that depends on it, or the newest configured version when built directly.   | String | optional |  `""`  |
| <a id="csharp_proto_library-target_type"></a>target_type |  Compiler target type output flag.   | String | optional |  `"library"`  |
| <a id="csharp_proto_library-warn_as_error"></a>warn_as_error |  Treat compiler warnings as errors, the same as MSBuild `TreatWarningsAsErrors`. Warnings that `nowarn` suppresses, and CS1701 and CS1702, never fail the build.   | Boolean | optional |  `False`  |
| <a id="csharp_proto_library-warning_level"></a>warning_level |  Compiler diagnostic severity level.   | Integer | optional |  `4`  |


