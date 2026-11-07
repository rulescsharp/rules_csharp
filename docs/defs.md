<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API for rules_csharp.

Works with Bazel 7, 8 and 9 with Bzlmod, on Linux, macOS and Windows.

Compiled assemblies and pdbs record source paths under `/_/` instead of the absolute build path, so
outputs are identical across machines and sandboxes. Map `/_/` to the workspace root in a debugger to
step into sources.

`csharp_proto_library` and `csharp_grpc_library` live in the separate `rules_csharp_proto` module, so
the core module pulls in no protobuf. See [rules_csharp_proto](../proto/README.md) for setup. The old names
remain as stubs that fail the build with migration steps.

<a id="csharp_analyzer_import"></a>

## csharp_analyzer_import

<pre>
load("@rules_csharp//csharp:defs.bzl", "csharp_analyzer_import")

csharp_analyzer_import(<a href="#csharp_analyzer_import-name">name</a>, <a href="#csharp_analyzer_import-analyzers">analyzers</a>, <a href="#csharp_analyzer_import-dlls">dlls</a>)
</pre>

Imports precompiled Roslyn analyzer and source generator assemblies.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="csharp_analyzer_import-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="csharp_analyzer_import-analyzers"></a>analyzers |  Precompiled Roslyn analyzer DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_import-dlls"></a>dlls |  Precompiled implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |


<a id="csharp_analyzer_library"></a>

## csharp_analyzer_library

<pre>
load("@rules_csharp//csharp:defs.bzl", "csharp_analyzer_library")

csharp_analyzer_library(<a href="#csharp_analyzer_library-name">name</a>, <a href="#csharp_analyzer_library-deps">deps</a>, <a href="#csharp_analyzer_library-srcs">srcs</a>, <a href="#csharp_analyzer_library-data">data</a>, <a href="#csharp_analyzer_library-resources">resources</a>, <a href="#csharp_analyzer_library-additional_compiler_options">additional_compiler_options</a>,
                        <a href="#csharp_analyzer_library-allow_unsafe_blocks">allow_unsafe_blocks</a>, <a href="#csharp_analyzer_library-analyzers">analyzers</a>, <a href="#csharp_analyzer_library-compile_refs">compile_refs</a>, <a href="#csharp_analyzer_library-content">content</a>, <a href="#csharp_analyzer_library-copy_to_output">copy_to_output</a>,
                        <a href="#csharp_analyzer_library-defines">defines</a>, <a href="#csharp_analyzer_library-dlls">dlls</a>, <a href="#csharp_analyzer_library-editorconfig_files">editorconfig_files</a>, <a href="#csharp_analyzer_library-exports">exports</a>, <a href="#csharp_analyzer_library-framework_references">framework_references</a>,
                        <a href="#csharp_analyzer_library-generate_assembly_info">generate_assembly_info</a>, <a href="#csharp_analyzer_library-generate_documentation_file">generate_documentation_file</a>, <a href="#csharp_analyzer_library-implicit_usings">implicit_usings</a>,
                        <a href="#csharp_analyzer_library-internals_visible_to">internals_visible_to</a>, <a href="#csharp_analyzer_library-langversion">langversion</a>, <a href="#csharp_analyzer_library-native_libs">native_libs</a>, <a href="#csharp_analyzer_library-nowarn">nowarn</a>, <a href="#csharp_analyzer_library-output_assembly">output_assembly</a>,
                        <a href="#csharp_analyzer_library-plugins">plugins</a>, <a href="#csharp_analyzer_library-runtime_dlls">runtime_dlls</a>, <a href="#csharp_analyzer_library-sdk">sdk</a>, <a href="#csharp_analyzer_library-target_framework">target_framework</a>, <a href="#csharp_analyzer_library-target_type">target_type</a>, <a href="#csharp_analyzer_library-warn_as_error">warn_as_error</a>,
                        <a href="#csharp_analyzer_library-warning_level">warning_level</a>)
</pre>

Compiles Roslyn analyzer or source generator assemblies.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="csharp_analyzer_library-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="csharp_analyzer_library-deps"></a>deps |  Direct dependency libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-srcs"></a>srcs |  C# source files to compile.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-data"></a>data |  Files and targets needed at run time. Their files and runfiles join the runfiles of this target and of every executable that depends on it, along with the `content` of libraries it depends on.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-resources"></a>resources |  Embedded resource files mapped to logical names.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_analyzer_library-additional_compiler_options"></a>additional_compiler_options |  Extra `csc` tokens appended after the rule's own flags, the same as MSBuild `AdditionalOptions`. Each entry is one token such as `-checked+` or `-highentropyva-`. Prefer the dedicated attributes (`defines`, `nowarn`, `langversion`, `warning_level`, `warn_as_error`) when they cover the flag. Empty entries and response files that start with `@` fail analysis.   | List of strings | optional |  `[]`  |
| <a id="csharp_analyzer_library-allow_unsafe_blocks"></a>allow_unsafe_blocks |  Allows `unsafe` code, the same as MSBuild `AllowUnsafeBlocks`. Without it the compiler rejects any `unsafe` block or member with CS0227.   | Boolean | optional |  `False`  |
| <a id="csharp_analyzer_library-analyzers"></a>analyzers |  Precompiled Roslyn analyzer DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-compile_refs"></a>compile_refs |  Precompiled reference assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-content"></a>content |  Static content files copied to runtime directories.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-copy_to_output"></a>copy_to_output |  Files mapped to destination output paths.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_analyzer_library-defines"></a>defines |  Preprocessor symbols to define during compilation, the same as MSBuild `DefineConstants`. Every compilation mode except `-c opt` also defines `DEBUG` and `TRACE`, like the MSBuild Debug configuration. `-c opt` defines `TRACE` and `RELEASE` and turns on optimizations, like the Release configuration. Like dotnet build, every target also gets the symbols of its target framework: `NET`, `NETCOREAPP`, `NET<major>_0`, `NET5_0_OR_GREATER` up to `NET<major>_0_OR_GREATER`, and `NETCOREAPP1_0_OR_GREATER` up to `NETCOREAPP3_1_OR_GREATER`. So a `net8.0` target defines `NET8_0` and `NET8_0_OR_GREATER` but not `NET9_0_OR_GREATER`.   | List of strings | optional |  `[]`  |
| <a id="csharp_analyzer_library-dlls"></a>dlls |  Precompiled implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-editorconfig_files"></a>editorconfig_files |  `.editorconfig` and global analyzer config files passed to the compiler with `-analyzerconfig`, the same as MSBuild `EditorConfigFiles` items. Sections such as `[*.cs]` match source paths under the directory of the file, so keep a `.editorconfig` next to or above the sources it covers. Severity settings such as `dotnet_diagnostic.CS8618.severity = none` apply to compiler warnings. CA and IDE rules come from analyzers, so they take effect only when the analyzer package is in `plugins` or `deps`.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-exports"></a>exports |  Dependencies exported to downstream consumers.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-framework_references"></a>framework_references |  Shared frameworks this target uses, the same as MSBuild `FrameworkReference` items. The only supported value is `"Microsoft.AspNetCore.App"`, since `Microsoft.NETCore.App` is always referenced. A target gets the framework's reference assemblies at compile time, and everything that depends on it gets them too, so an executable lists the framework in its runtimeconfig.json and the runtime loads it. `sdk = "Microsoft.NET.Sdk.Web"` implies `"Microsoft.AspNetCore.App"`.   | List of strings | optional |  `[]`  |
| <a id="csharp_analyzer_library-generate_assembly_info"></a>generate_assembly_info |  Synthesize assembly information attributes.   | Boolean | optional |  `True`  |
| <a id="csharp_analyzer_library-generate_documentation_file"></a>generate_documentation_file |  Writes the `///` comments to `<assembly>.xml` next to the dll, the same as MSBuild `GenerateDocumentationFile`. IDEs read that file to show the docs for anyone who references the assembly. Like MSBuild, the compiler then warns with CS1591 for each public member that has no `///` comment, which fails the build under `warn_as_error` unless `nowarn` lists it.   | Boolean | optional |  `False`  |
| <a id="csharp_analyzer_library-implicit_usings"></a>implicit_usings |  Synthesize implicit global usings namespace imports.   | Boolean | optional |  `True`  |
| <a id="csharp_analyzer_library-internals_visible_to"></a>internals_visible_to |  Friend assembly names for InternalsVisibleTo.   | List of strings | optional |  `[]`  |
| <a id="csharp_analyzer_library-langversion"></a>langversion |  Target C# language version specification.   | String | optional |  `"latest"`  |
| <a id="csharp_analyzer_library-native_libs"></a>native_libs |  Unmanaged target platform shared libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-nowarn"></a>nowarn |  Compiler diagnostic codes to suppress.   | List of strings | optional |  `[]`  |
| <a id="csharp_analyzer_library-output_assembly"></a>output_assembly |  Name of the compiled assembly, the same as MSBuild `AssemblyName`. Defaults to the target name. It names the dll, pdb and reference assembly, and for executables the runtimeconfig.json and deps.json, and it is the default prefix of embedded resource names. The executable Bazel runs keeps the target name. Two assemblies with the same name can't load into one app, so an executable fails analysis when two of its assemblies share a name and one of them is built from sources.   | String | optional |  `""`  |
| <a id="csharp_analyzer_library-plugins"></a>plugins |  Roslyn analyzer and generator plugins.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-runtime_dlls"></a>runtime_dlls |  Precompiled runtime implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-sdk"></a>sdk |  Project SDK the target follows, the same as the `Sdk` of an MSBuild project. `Microsoft.NET.Sdk.Web` adds the ASP.NET Core implicit usings, references `Microsoft.AspNetCore.App` and, for an executable, turns on server garbage collection (MSBuild `ServerGarbageCollection`) in its runtimeconfig.json. Other executables use workstation garbage collection and the default roll forward, which stays on their own .NET major version, like dotnet build. `Microsoft.NET.Sdk.Worker` adds the Microsoft.Extensions hosting usings and, as in MSBuild, no reference, so the target also needs `framework_references = ["Microsoft.AspNetCore.App"]` or the Microsoft.Extensions.Hosting NuGet package.   | String | optional |  `"Microsoft.NET.Sdk"`  |
| <a id="csharp_analyzer_library-target_framework"></a>target_framework |  Target framework moniker, one of net8.0, net9.0, net10.0. Picks the SDK, reference pack, and runtime the target builds and runs against, so its .NET version must be listed in `dotnet_versions` of `csharp.toolchain`. When unset, the target uses the framework of the target that depends on it, or the newest configured version when built directly.   | String | optional |  `""`  |
| <a id="csharp_analyzer_library-target_type"></a>target_type |  Compiler target type output flag.   | String | optional |  `"library"`  |
| <a id="csharp_analyzer_library-warn_as_error"></a>warn_as_error |  Treat compiler warnings as errors.   | Boolean | optional |  `False`  |
| <a id="csharp_analyzer_library-warning_level"></a>warning_level |  Compiler diagnostic severity level.   | Integer | optional |  `4`  |


<a id="csharp_binary"></a>

## csharp_binary

<pre>
load("@rules_csharp//csharp:defs.bzl", "csharp_binary")

csharp_binary(<a href="#csharp_binary-name">name</a>, <a href="#csharp_binary-deps">deps</a>, <a href="#csharp_binary-srcs">srcs</a>, <a href="#csharp_binary-data">data</a>, <a href="#csharp_binary-resources">resources</a>, <a href="#csharp_binary-additional_compiler_options">additional_compiler_options</a>, <a href="#csharp_binary-allow_unsafe_blocks">allow_unsafe_blocks</a>,
              <a href="#csharp_binary-content">content</a>, <a href="#csharp_binary-copy_to_output">copy_to_output</a>, <a href="#csharp_binary-defines">defines</a>, <a href="#csharp_binary-editorconfig_files">editorconfig_files</a>, <a href="#csharp_binary-exports">exports</a>, <a href="#csharp_binary-framework_references">framework_references</a>,
              <a href="#csharp_binary-generate_assembly_info">generate_assembly_info</a>, <a href="#csharp_binary-generate_documentation_file">generate_documentation_file</a>, <a href="#csharp_binary-implicit_usings">implicit_usings</a>,
              <a href="#csharp_binary-internals_visible_to">internals_visible_to</a>, <a href="#csharp_binary-langversion">langversion</a>, <a href="#csharp_binary-nowarn">nowarn</a>, <a href="#csharp_binary-output_assembly">output_assembly</a>, <a href="#csharp_binary-plugins">plugins</a>, <a href="#csharp_binary-sdk">sdk</a>,
              <a href="#csharp_binary-target_framework">target_framework</a>, <a href="#csharp_binary-target_type">target_type</a>, <a href="#csharp_binary-warn_as_error">warn_as_error</a>, <a href="#csharp_binary-warning_level">warning_level</a>)
</pre>

Compiles a C# executable and stamps the native application host binary.

`bazel run` sets `DOTNET_ROOT` to the toolchain's .NET runtime, so the app runs without an installed .NET.
Running the output outside Bazel needs a .NET install with the app's runtime in `DOTNET_ROOT` or the
default install location.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="csharp_binary-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="csharp_binary-deps"></a>deps |  Direct dependency libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_binary-srcs"></a>srcs |  C# source files to compile.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_binary-data"></a>data |  Files and targets needed at run time. Their files and runfiles join the runfiles of this target and of every executable that depends on it, along with the `content` of libraries it depends on.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_binary-resources"></a>resources |  Embedded resource files mapped to logical names.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_binary-additional_compiler_options"></a>additional_compiler_options |  Extra `csc` tokens appended after the rule's own flags, the same as MSBuild `AdditionalOptions`. Each entry is one token such as `-checked+` or `-highentropyva-`. Prefer the dedicated attributes (`defines`, `nowarn`, `langversion`, `warning_level`, `warn_as_error`) when they cover the flag. Empty entries and response files that start with `@` fail analysis.   | List of strings | optional |  `[]`  |
| <a id="csharp_binary-allow_unsafe_blocks"></a>allow_unsafe_blocks |  Allows `unsafe` code, the same as MSBuild `AllowUnsafeBlocks`. Without it the compiler rejects any `unsafe` block or member with CS0227.   | Boolean | optional |  `False`  |
| <a id="csharp_binary-content"></a>content |  Static content files copied to runtime directories.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_binary-copy_to_output"></a>copy_to_output |  Files mapped to destination output paths.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_binary-defines"></a>defines |  Preprocessor symbols to define during compilation, the same as MSBuild `DefineConstants`. Every compilation mode except `-c opt` also defines `DEBUG` and `TRACE`, like the MSBuild Debug configuration. `-c opt` defines `TRACE` and `RELEASE` and turns on optimizations, like the Release configuration. Like dotnet build, every target also gets the symbols of its target framework: `NET`, `NETCOREAPP`, `NET<major>_0`, `NET5_0_OR_GREATER` up to `NET<major>_0_OR_GREATER`, and `NETCOREAPP1_0_OR_GREATER` up to `NETCOREAPP3_1_OR_GREATER`. So a `net8.0` target defines `NET8_0` and `NET8_0_OR_GREATER` but not `NET9_0_OR_GREATER`.   | List of strings | optional |  `[]`  |
| <a id="csharp_binary-editorconfig_files"></a>editorconfig_files |  `.editorconfig` and global analyzer config files passed to the compiler with `-analyzerconfig`, the same as MSBuild `EditorConfigFiles` items. Sections such as `[*.cs]` match source paths under the directory of the file, so keep a `.editorconfig` next to or above the sources it covers. Severity settings such as `dotnet_diagnostic.CS8618.severity = none` apply to compiler warnings. CA and IDE rules come from analyzers, so they take effect only when the analyzer package is in `plugins` or `deps`.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_binary-exports"></a>exports |  Dependencies exported to downstream consumers.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_binary-framework_references"></a>framework_references |  Shared frameworks this target uses, the same as MSBuild `FrameworkReference` items. The only supported value is `"Microsoft.AspNetCore.App"`, since `Microsoft.NETCore.App` is always referenced. A target gets the framework's reference assemblies at compile time, and everything that depends on it gets them too, so an executable lists the framework in its runtimeconfig.json and the runtime loads it. `sdk = "Microsoft.NET.Sdk.Web"` implies `"Microsoft.AspNetCore.App"`.   | List of strings | optional |  `[]`  |
| <a id="csharp_binary-generate_assembly_info"></a>generate_assembly_info |  Synthesize assembly information attributes.   | Boolean | optional |  `True`  |
| <a id="csharp_binary-generate_documentation_file"></a>generate_documentation_file |  Writes the `///` comments to `<assembly>.xml` next to the dll, the same as MSBuild `GenerateDocumentationFile`. IDEs read that file to show the docs for anyone who references the assembly. Like MSBuild, the compiler then warns with CS1591 for each public member that has no `///` comment, which fails the build under `warn_as_error` unless `nowarn` lists it.   | Boolean | optional |  `False`  |
| <a id="csharp_binary-implicit_usings"></a>implicit_usings |  Synthesize implicit global usings namespace imports.   | Boolean | optional |  `True`  |
| <a id="csharp_binary-internals_visible_to"></a>internals_visible_to |  Friend assembly names for InternalsVisibleTo.   | List of strings | optional |  `[]`  |
| <a id="csharp_binary-langversion"></a>langversion |  Target C# language version specification.   | String | optional |  `"latest"`  |
| <a id="csharp_binary-nowarn"></a>nowarn |  Compiler diagnostic codes to suppress.   | List of strings | optional |  `[]`  |
| <a id="csharp_binary-output_assembly"></a>output_assembly |  Name of the compiled assembly, the same as MSBuild `AssemblyName`. Defaults to the target name. It names the dll, pdb and reference assembly, and for executables the runtimeconfig.json and deps.json, and it is the default prefix of embedded resource names. The executable Bazel runs keeps the target name. Two assemblies with the same name can't load into one app, so an executable fails analysis when two of its assemblies share a name and one of them is built from sources.   | String | optional |  `""`  |
| <a id="csharp_binary-plugins"></a>plugins |  Roslyn analyzer and generator plugins.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_binary-sdk"></a>sdk |  Project SDK the target follows, the same as the `Sdk` of an MSBuild project. `Microsoft.NET.Sdk.Web` adds the ASP.NET Core implicit usings, references `Microsoft.AspNetCore.App` and, for an executable, turns on server garbage collection (MSBuild `ServerGarbageCollection`) in its runtimeconfig.json. Other executables use workstation garbage collection and the default roll forward, which stays on their own .NET major version, like dotnet build. `Microsoft.NET.Sdk.Worker` adds the Microsoft.Extensions hosting usings and, as in MSBuild, no reference, so the target also needs `framework_references = ["Microsoft.AspNetCore.App"]` or the Microsoft.Extensions.Hosting NuGet package.   | String | optional |  `"Microsoft.NET.Sdk"`  |
| <a id="csharp_binary-target_framework"></a>target_framework |  Target framework moniker, one of net8.0, net9.0, net10.0. Picks the SDK, reference pack, and runtime the target builds and runs against, so its .NET version must be listed in `dotnet_versions` of `csharp.toolchain`. When unset, the target uses the framework of the target that depends on it, or the newest configured version when built directly.   | String | optional |  `""`  |
| <a id="csharp_binary-target_type"></a>target_type |  Compiler target type output flag.   | String | optional |  `"exe"`  |
| <a id="csharp_binary-warn_as_error"></a>warn_as_error |  Treat compiler warnings as errors.   | Boolean | optional |  `False`  |
| <a id="csharp_binary-warning_level"></a>warning_level |  Compiler diagnostic severity level.   | Integer | optional |  `4`  |


<a id="csharp_import"></a>

## csharp_import

<pre>
load("@rules_csharp//csharp:defs.bzl", "csharp_import")

csharp_import(<a href="#csharp_import-name">name</a>, <a href="#csharp_import-deps">deps</a>, <a href="#csharp_import-analyzers">analyzers</a>, <a href="#csharp_import-compile_refs">compile_refs</a>, <a href="#csharp_import-dlls">dlls</a>, <a href="#csharp_import-exports">exports</a>, <a href="#csharp_import-native_libs">native_libs</a>, <a href="#csharp_import-plugins">plugins</a>,
              <a href="#csharp_import-runtime_dlls">runtime_dlls</a>, <a href="#csharp_import-target_framework">target_framework</a>, <a href="#csharp_import-test_runtime_dlls">test_runtime_dlls</a>)
</pre>

Imports precompiled reference and implementation assemblies.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="csharp_import-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="csharp_import-deps"></a>deps |  Direct dependency libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_import-analyzers"></a>analyzers |  Precompiled Roslyn analyzer DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_import-compile_refs"></a>compile_refs |  Precompiled reference assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_import-dlls"></a>dlls |  Precompiled implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_import-exports"></a>exports |  Dependencies exported to downstream consumers.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_import-native_libs"></a>native_libs |  Unmanaged target platform shared libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_import-plugins"></a>plugins |  Roslyn analyzer and generator plugins.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_import-runtime_dlls"></a>runtime_dlls |  Precompiled runtime implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_import-target_framework"></a>target_framework |  Target framework moniker string.   | String | optional |  `""`  |
| <a id="csharp_import-test_runtime_dlls"></a>test_runtime_dlls |  DLL files that restore copies next to a test, such as VSTest adapters. A `csharp_test` with `target_type = "library"` stages them next to the test assembly.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |


<a id="csharp_library"></a>

## csharp_library

<pre>
load("@rules_csharp//csharp:defs.bzl", "csharp_library")

csharp_library(<a href="#csharp_library-name">name</a>, <a href="#csharp_library-deps">deps</a>, <a href="#csharp_library-srcs">srcs</a>, <a href="#csharp_library-data">data</a>, <a href="#csharp_library-resources">resources</a>, <a href="#csharp_library-additional_compiler_options">additional_compiler_options</a>, <a href="#csharp_library-allow_unsafe_blocks">allow_unsafe_blocks</a>,
               <a href="#csharp_library-analyzers">analyzers</a>, <a href="#csharp_library-compile_refs">compile_refs</a>, <a href="#csharp_library-content">content</a>, <a href="#csharp_library-copy_to_output">copy_to_output</a>, <a href="#csharp_library-defines">defines</a>, <a href="#csharp_library-dlls">dlls</a>, <a href="#csharp_library-editorconfig_files">editorconfig_files</a>,
               <a href="#csharp_library-exports">exports</a>, <a href="#csharp_library-framework_references">framework_references</a>, <a href="#csharp_library-generate_assembly_info">generate_assembly_info</a>, <a href="#csharp_library-generate_documentation_file">generate_documentation_file</a>,
               <a href="#csharp_library-implicit_usings">implicit_usings</a>, <a href="#csharp_library-internals_visible_to">internals_visible_to</a>, <a href="#csharp_library-langversion">langversion</a>, <a href="#csharp_library-native_libs">native_libs</a>, <a href="#csharp_library-nowarn">nowarn</a>,
               <a href="#csharp_library-output_assembly">output_assembly</a>, <a href="#csharp_library-plugins">plugins</a>, <a href="#csharp_library-runtime_dlls">runtime_dlls</a>, <a href="#csharp_library-sdk">sdk</a>, <a href="#csharp_library-target_framework">target_framework</a>, <a href="#csharp_library-target_type">target_type</a>,
               <a href="#csharp_library-warn_as_error">warn_as_error</a>, <a href="#csharp_library-warning_level">warning_level</a>)
</pre>

Compiles C# source files into reference and implementation assemblies.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="csharp_library-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="csharp_library-deps"></a>deps |  Direct dependency libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-srcs"></a>srcs |  C# source files to compile.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-data"></a>data |  Files and targets needed at run time. Their files and runfiles join the runfiles of this target and of every executable that depends on it, along with the `content` of libraries it depends on.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-resources"></a>resources |  Embedded resource files mapped to logical names.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_library-additional_compiler_options"></a>additional_compiler_options |  Extra `csc` tokens appended after the rule's own flags, the same as MSBuild `AdditionalOptions`. Each entry is one token such as `-checked+` or `-highentropyva-`. Prefer the dedicated attributes (`defines`, `nowarn`, `langversion`, `warning_level`, `warn_as_error`) when they cover the flag. Empty entries and response files that start with `@` fail analysis.   | List of strings | optional |  `[]`  |
| <a id="csharp_library-allow_unsafe_blocks"></a>allow_unsafe_blocks |  Allows `unsafe` code, the same as MSBuild `AllowUnsafeBlocks`. Without it the compiler rejects any `unsafe` block or member with CS0227.   | Boolean | optional |  `False`  |
| <a id="csharp_library-analyzers"></a>analyzers |  Precompiled Roslyn analyzer DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-compile_refs"></a>compile_refs |  Precompiled reference assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-content"></a>content |  Static content files copied to runtime directories.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-copy_to_output"></a>copy_to_output |  Files mapped to destination output paths.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_library-defines"></a>defines |  Preprocessor symbols to define during compilation, the same as MSBuild `DefineConstants`. Every compilation mode except `-c opt` also defines `DEBUG` and `TRACE`, like the MSBuild Debug configuration. `-c opt` defines `TRACE` and `RELEASE` and turns on optimizations, like the Release configuration. Like dotnet build, every target also gets the symbols of its target framework: `NET`, `NETCOREAPP`, `NET<major>_0`, `NET5_0_OR_GREATER` up to `NET<major>_0_OR_GREATER`, and `NETCOREAPP1_0_OR_GREATER` up to `NETCOREAPP3_1_OR_GREATER`. So a `net8.0` target defines `NET8_0` and `NET8_0_OR_GREATER` but not `NET9_0_OR_GREATER`.   | List of strings | optional |  `[]`  |
| <a id="csharp_library-dlls"></a>dlls |  Precompiled implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-editorconfig_files"></a>editorconfig_files |  `.editorconfig` and global analyzer config files passed to the compiler with `-analyzerconfig`, the same as MSBuild `EditorConfigFiles` items. Sections such as `[*.cs]` match source paths under the directory of the file, so keep a `.editorconfig` next to or above the sources it covers. Severity settings such as `dotnet_diagnostic.CS8618.severity = none` apply to compiler warnings. CA and IDE rules come from analyzers, so they take effect only when the analyzer package is in `plugins` or `deps`.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-exports"></a>exports |  Dependencies exported to downstream consumers.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-framework_references"></a>framework_references |  Shared frameworks this target uses, the same as MSBuild `FrameworkReference` items. The only supported value is `"Microsoft.AspNetCore.App"`, since `Microsoft.NETCore.App` is always referenced. A target gets the framework's reference assemblies at compile time, and everything that depends on it gets them too, so an executable lists the framework in its runtimeconfig.json and the runtime loads it. `sdk = "Microsoft.NET.Sdk.Web"` implies `"Microsoft.AspNetCore.App"`.   | List of strings | optional |  `[]`  |
| <a id="csharp_library-generate_assembly_info"></a>generate_assembly_info |  Synthesize assembly information attributes.   | Boolean | optional |  `True`  |
| <a id="csharp_library-generate_documentation_file"></a>generate_documentation_file |  Writes the `///` comments to `<assembly>.xml` next to the dll, the same as MSBuild `GenerateDocumentationFile`. IDEs read that file to show the docs for anyone who references the assembly. Like MSBuild, the compiler then warns with CS1591 for each public member that has no `///` comment, which fails the build under `warn_as_error` unless `nowarn` lists it.   | Boolean | optional |  `False`  |
| <a id="csharp_library-implicit_usings"></a>implicit_usings |  Synthesize implicit global usings namespace imports.   | Boolean | optional |  `True`  |
| <a id="csharp_library-internals_visible_to"></a>internals_visible_to |  Friend assembly names for InternalsVisibleTo.   | List of strings | optional |  `[]`  |
| <a id="csharp_library-langversion"></a>langversion |  Target C# language version specification.   | String | optional |  `"latest"`  |
| <a id="csharp_library-native_libs"></a>native_libs |  Unmanaged target platform shared libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-nowarn"></a>nowarn |  Compiler diagnostic codes to suppress.   | List of strings | optional |  `[]`  |
| <a id="csharp_library-output_assembly"></a>output_assembly |  Name of the compiled assembly, the same as MSBuild `AssemblyName`. Defaults to the target name. It names the dll, pdb and reference assembly, and for executables the runtimeconfig.json and deps.json, and it is the default prefix of embedded resource names. The executable Bazel runs keeps the target name. Two assemblies with the same name can't load into one app, so an executable fails analysis when two of its assemblies share a name and one of them is built from sources.   | String | optional |  `""`  |
| <a id="csharp_library-plugins"></a>plugins |  Roslyn analyzer and generator plugins.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-runtime_dlls"></a>runtime_dlls |  Precompiled runtime implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-sdk"></a>sdk |  Project SDK the target follows, the same as the `Sdk` of an MSBuild project. `Microsoft.NET.Sdk.Web` adds the ASP.NET Core implicit usings, references `Microsoft.AspNetCore.App` and, for an executable, turns on server garbage collection (MSBuild `ServerGarbageCollection`) in its runtimeconfig.json. Other executables use workstation garbage collection and the default roll forward, which stays on their own .NET major version, like dotnet build. `Microsoft.NET.Sdk.Worker` adds the Microsoft.Extensions hosting usings and, as in MSBuild, no reference, so the target also needs `framework_references = ["Microsoft.AspNetCore.App"]` or the Microsoft.Extensions.Hosting NuGet package.   | String | optional |  `"Microsoft.NET.Sdk"`  |
| <a id="csharp_library-target_framework"></a>target_framework |  Target framework moniker, one of net8.0, net9.0, net10.0. Picks the SDK, reference pack, and runtime the target builds and runs against, so its .NET version must be listed in `dotnet_versions` of `csharp.toolchain`. When unset, the target uses the framework of the target that depends on it, or the newest configured version when built directly.   | String | optional |  `""`  |
| <a id="csharp_library-target_type"></a>target_type |  Compiler target type output flag.   | String | optional |  `"library"`  |
| <a id="csharp_library-warn_as_error"></a>warn_as_error |  Treat compiler warnings as errors.   | Boolean | optional |  `False`  |
| <a id="csharp_library-warning_level"></a>warning_level |  Compiler diagnostic severity level.   | Integer | optional |  `4`  |


<a id="csharp_test"></a>

## csharp_test

<pre>
load("@rules_csharp//csharp:defs.bzl", "csharp_test")

csharp_test(<a href="#csharp_test-name">name</a>, <a href="#csharp_test-deps">deps</a>, <a href="#csharp_test-srcs">srcs</a>, <a href="#csharp_test-data">data</a>, <a href="#csharp_test-resources">resources</a>, <a href="#csharp_test-additional_compiler_options">additional_compiler_options</a>, <a href="#csharp_test-allow_unsafe_blocks">allow_unsafe_blocks</a>,
            <a href="#csharp_test-content">content</a>, <a href="#csharp_test-copy_to_output">copy_to_output</a>, <a href="#csharp_test-defines">defines</a>, <a href="#csharp_test-editorconfig_files">editorconfig_files</a>, <a href="#csharp_test-env">env</a>, <a href="#csharp_test-env_inherit">env_inherit</a>, <a href="#csharp_test-exports">exports</a>,
            <a href="#csharp_test-framework_references">framework_references</a>, <a href="#csharp_test-generate_assembly_info">generate_assembly_info</a>, <a href="#csharp_test-generate_documentation_file">generate_documentation_file</a>,
            <a href="#csharp_test-implicit_usings">implicit_usings</a>, <a href="#csharp_test-internals_visible_to">internals_visible_to</a>, <a href="#csharp_test-langversion">langversion</a>, <a href="#csharp_test-nowarn">nowarn</a>, <a href="#csharp_test-output_assembly">output_assembly</a>, <a href="#csharp_test-plugins">plugins</a>, <a href="#csharp_test-sdk">sdk</a>,
            <a href="#csharp_test-target_framework">target_framework</a>, <a href="#csharp_test-target_type">target_type</a>, <a href="#csharp_test-test_filter">test_filter</a>, <a href="#csharp_test-warn_as_error">warn_as_error</a>, <a href="#csharp_test-warning_level">warning_level</a>)
</pre>

Compiles and executes a C# test binary under the Bazel test harness.

A test runs in one of two ways, picked by `target_type`:

- `"exe"` (the default) builds a program and runs its `Main`. A nonzero exit code fails the test.
  The program owns everything else: it gets `test_filter` in `TESTBRIDGE_TEST_ONLY`, and with
  `shard_count` it reads `TEST_TOTAL_SHARDS` and `TEST_SHARD_INDEX` and must touch
  `TEST_SHARD_STATUS_FILE`. It may write JUnit XML to `XML_OUTPUT_FILE`.
- `"library"` builds a test assembly and runs it under VSTest, the runner behind `dotnet test`.
  Depend on `Microsoft.NET.Test.Sdk` and a test framework with its adapter from NuGet, such as
  `MSTest.TestFramework` with `MSTest.TestAdapter` or `xunit` with `xunit.runner.visualstudio`.
  The rule finds the adapter, fails when no test runs, splits the test cases across `shard_count`
  shards, and writes one `<testcase>` per test to `test.xml`.

`bazel coverage` reports line, branch, and method coverage of instrumented C# sources, collected with
[Coverlet](https://github.com/coverlet-coverage/coverlet) and merged by Bazel into LCOV. That's the code a
test depends on, in both modes. Add `--instrument_test_targets` to count the test's own sources too. CI
checks coverage on Linux, macOS and Windows. On Windows it needs Bazel 9 or later, since older Bazel can't start its
coverage wrapper there.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="csharp_test-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="csharp_test-deps"></a>deps |  Direct dependency libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_test-srcs"></a>srcs |  C# source files to compile.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_test-data"></a>data |  Files and targets needed at run time. Their files and runfiles join the runfiles of this target and of every executable that depends on it, along with the `content` of libraries it depends on.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_test-resources"></a>resources |  Embedded resource files mapped to logical names.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_test-additional_compiler_options"></a>additional_compiler_options |  Extra `csc` tokens appended after the rule's own flags, the same as MSBuild `AdditionalOptions`. Each entry is one token such as `-checked+` or `-highentropyva-`. Prefer the dedicated attributes (`defines`, `nowarn`, `langversion`, `warning_level`, `warn_as_error`) when they cover the flag. Empty entries and response files that start with `@` fail analysis.   | List of strings | optional |  `[]`  |
| <a id="csharp_test-allow_unsafe_blocks"></a>allow_unsafe_blocks |  Allows `unsafe` code, the same as MSBuild `AllowUnsafeBlocks`. Without it the compiler rejects any `unsafe` block or member with CS0227.   | Boolean | optional |  `False`  |
| <a id="csharp_test-content"></a>content |  Static content files copied to runtime directories.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_test-copy_to_output"></a>copy_to_output |  Files mapped to destination output paths.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_test-defines"></a>defines |  Preprocessor symbols to define during compilation, the same as MSBuild `DefineConstants`. Every compilation mode except `-c opt` also defines `DEBUG` and `TRACE`, like the MSBuild Debug configuration. `-c opt` defines `TRACE` and `RELEASE` and turns on optimizations, like the Release configuration. Like dotnet build, every target also gets the symbols of its target framework: `NET`, `NETCOREAPP`, `NET<major>_0`, `NET5_0_OR_GREATER` up to `NET<major>_0_OR_GREATER`, and `NETCOREAPP1_0_OR_GREATER` up to `NETCOREAPP3_1_OR_GREATER`. So a `net8.0` target defines `NET8_0` and `NET8_0_OR_GREATER` but not `NET9_0_OR_GREATER`.   | List of strings | optional |  `[]`  |
| <a id="csharp_test-editorconfig_files"></a>editorconfig_files |  `.editorconfig` and global analyzer config files passed to the compiler with `-analyzerconfig`, the same as MSBuild `EditorConfigFiles` items. Sections such as `[*.cs]` match source paths under the directory of the file, so keep a `.editorconfig` next to or above the sources it covers. Severity settings such as `dotnet_diagnostic.CS8618.severity = none` apply to compiler warnings. CA and IDE rules come from analyzers, so they take effect only when the analyzer package is in `plugins` or `deps`.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_test-env"></a>env |  Environment variables for test execution. Values expand `$(rlocationpath)` and the other location functions for labels in `data` and `deps`.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional |  `{}`  |
| <a id="csharp_test-env_inherit"></a>env_inherit |  Environment variables inherited from client environment.   | List of strings | optional |  `[]`  |
| <a id="csharp_test-exports"></a>exports |  Dependencies exported to downstream consumers.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_test-framework_references"></a>framework_references |  Shared frameworks this target uses, the same as MSBuild `FrameworkReference` items. The only supported value is `"Microsoft.AspNetCore.App"`, since `Microsoft.NETCore.App` is always referenced. A target gets the framework's reference assemblies at compile time, and everything that depends on it gets them too, so an executable lists the framework in its runtimeconfig.json and the runtime loads it. `sdk = "Microsoft.NET.Sdk.Web"` implies `"Microsoft.AspNetCore.App"`.   | List of strings | optional |  `[]`  |
| <a id="csharp_test-generate_assembly_info"></a>generate_assembly_info |  Synthesize assembly information attributes.   | Boolean | optional |  `True`  |
| <a id="csharp_test-generate_documentation_file"></a>generate_documentation_file |  Writes the `///` comments to `<assembly>.xml` next to the dll, the same as MSBuild `GenerateDocumentationFile`. IDEs read that file to show the docs for anyone who references the assembly. Like MSBuild, the compiler then warns with CS1591 for each public member that has no `///` comment, which fails the build under `warn_as_error` unless `nowarn` lists it.   | Boolean | optional |  `False`  |
| <a id="csharp_test-implicit_usings"></a>implicit_usings |  Synthesize implicit global usings namespace imports.   | Boolean | optional |  `True`  |
| <a id="csharp_test-internals_visible_to"></a>internals_visible_to |  Friend assembly names for InternalsVisibleTo.   | List of strings | optional |  `[]`  |
| <a id="csharp_test-langversion"></a>langversion |  Target C# language version specification.   | String | optional |  `"latest"`  |
| <a id="csharp_test-nowarn"></a>nowarn |  Compiler diagnostic codes to suppress.   | List of strings | optional |  `[]`  |
| <a id="csharp_test-output_assembly"></a>output_assembly |  Name of the compiled assembly, the same as MSBuild `AssemblyName`. Defaults to the target name. It names the dll, pdb and reference assembly, and for executables the runtimeconfig.json and deps.json, and it is the default prefix of embedded resource names. The executable Bazel runs keeps the target name. Two assemblies with the same name can't load into one app, so an executable fails analysis when two of its assemblies share a name and one of them is built from sources.   | String | optional |  `""`  |
| <a id="csharp_test-plugins"></a>plugins |  Roslyn analyzer and generator plugins.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_test-sdk"></a>sdk |  Project SDK the target follows, the same as the `Sdk` of an MSBuild project. `Microsoft.NET.Sdk.Web` adds the ASP.NET Core implicit usings, references `Microsoft.AspNetCore.App` and, for an executable, turns on server garbage collection (MSBuild `ServerGarbageCollection`) in its runtimeconfig.json. Other executables use workstation garbage collection and the default roll forward, which stays on their own .NET major version, like dotnet build. `Microsoft.NET.Sdk.Worker` adds the Microsoft.Extensions hosting usings and, as in MSBuild, no reference, so the target also needs `framework_references = ["Microsoft.AspNetCore.App"]` or the Microsoft.Extensions.Hosting NuGet package.   | String | optional |  `"Microsoft.NET.Sdk"`  |
| <a id="csharp_test-target_framework"></a>target_framework |  Target framework moniker, one of net8.0, net9.0, net10.0. Picks the SDK, reference pack, and runtime the target builds and runs against, so its .NET version must be listed in `dotnet_versions` of `csharp.toolchain`. When unset, the target uses the framework of the target that depends on it, or the newest configured version when built directly.   | String | optional |  `""`  |
| <a id="csharp_test-target_type"></a>target_type |  `"exe"` runs the program's `Main` as the test. `"library"` runs the assembly's tests under VSTest.   | String | optional |  `"exe"`  |
| <a id="csharp_test-test_filter"></a>test_filter |  Default test filter, overridden by `--test_filter`. In library mode it is a VSTest [filter](https://learn.microsoft.com/dotnet/core/testing/selective-unit-tests), such as `TestCategory=Fast` or `FullyQualifiedName~Parser`.   | String | optional |  `""`  |
| <a id="csharp_test-warn_as_error"></a>warn_as_error |  Treat compiler warnings as errors.   | Boolean | optional |  `False`  |
| <a id="csharp_test-warning_level"></a>warning_level |  Compiler diagnostic severity level.   | Integer | optional |  `4`  |


<a id="CSharpAnalyzerInfo"></a>

## CSharpAnalyzerInfo

<pre>
load("@rules_csharp//csharp:defs.bzl", "CSharpAnalyzerInfo")

CSharpAnalyzerInfo(<a href="#CSharpAnalyzerInfo-analyzers">analyzers</a>)
</pre>

Propagates Roslyn analyzer and source generator assembly files.

**FIELDS**

| Name  | Description |
| :------------- | :------------- |
| <a id="CSharpAnalyzerInfo-analyzers"></a>analyzers |  Depset of Roslyn analyzer and generator assembly Files.    |


<a id="CSharpInfo"></a>

## CSharpInfo

<pre>
load("@rules_csharp//csharp:defs.bzl", "CSharpInfo")

CSharpInfo(<a href="#CSharpInfo-compile_ref">compile_ref</a>, <a href="#CSharpInfo-framework_references">framework_references</a>, <a href="#CSharpInfo-pdb">pdb</a>, <a href="#CSharpInfo-runtime_dll">runtime_dll</a>, <a href="#CSharpInfo-target_framework">target_framework</a>,
           <a href="#CSharpInfo-transitive_compile_refs">transitive_compile_refs</a>, <a href="#CSharpInfo-transitive_native_libs">transitive_native_libs</a>, <a href="#CSharpInfo-transitive_runtime_dlls">transitive_runtime_dlls</a>,
           <a href="#CSharpInfo-transitive_test_runtime_dlls">transitive_test_runtime_dlls</a>, <a href="#CSharpInfo-xml_doc">xml_doc</a>)
</pre>

Propagates compilation references, runtime assemblies, and unmanaged libraries.

**FIELDS**

| Name  | Description |
| :------------- | :------------- |
| <a id="CSharpInfo-compile_ref"></a>compile_ref |  Metadata-only reference assembly File produced by -refout.    |
| <a id="CSharpInfo-framework_references"></a>framework_references |  Depset of shared framework names (for example Microsoft.AspNetCore.App) this target and its dependencies need at compile time and run time. Providers created before this field existed lack it, so read it with getattr.    |
| <a id="CSharpInfo-pdb"></a>pdb |  Portable program database symbol File.    |
| <a id="CSharpInfo-runtime_dll"></a>runtime_dll |  Implementation assembly File.    |
| <a id="CSharpInfo-target_framework"></a>target_framework |  Target framework moniker string (for example net8.0).    |
| <a id="CSharpInfo-transitive_compile_refs"></a>transitive_compile_refs |  Depset of reference assembly Files for compilation.    |
| <a id="CSharpInfo-transitive_native_libs"></a>transitive_native_libs |  Depset of target platform unmanaged shared libraries.    |
| <a id="CSharpInfo-transitive_runtime_dlls"></a>transitive_runtime_dlls |  Depset of runtime assembly Files for execution.    |
| <a id="CSharpInfo-transitive_test_runtime_dlls"></a>transitive_test_runtime_dlls |  Depset of Files that a library csharp_test stages next to the test assembly, such as VSTest adapters. Optional, treated as empty when unset.    |
| <a id="CSharpInfo-xml_doc"></a>xml_doc |  XML documentation File written with `generate_documentation_file`, or None. Providers created before this field existed lack it, so read it with getattr.    |


<a id="CSharpToolchainInfo"></a>

## CSharpToolchainInfo

<pre>
load("@rules_csharp//csharp:defs.bzl", "CSharpToolchainInfo")

CSharpToolchainInfo(<a href="#CSharpToolchainInfo-aspnetcore_ref_pack">aspnetcore_ref_pack</a>, <a href="#CSharpToolchainInfo-csc_dll">csc_dll</a>, <a href="#CSharpToolchainInfo-csc_worker">csc_worker</a>, <a href="#CSharpToolchainInfo-csc_worker_files">csc_worker_files</a>, <a href="#CSharpToolchainInfo-dotnet_env">dotnet_env</a>,
                    <a href="#CSharpToolchainInfo-dotnet_muxer">dotnet_muxer</a>, <a href="#CSharpToolchainInfo-host_pack">host_pack</a>, <a href="#CSharpToolchainInfo-host_rid">host_rid</a>, <a href="#CSharpToolchainInfo-ref_pack">ref_pack</a>, <a href="#CSharpToolchainInfo-runtime_pack">runtime_pack</a>, <a href="#CSharpToolchainInfo-target_framework">target_framework</a>,
                    <a href="#CSharpToolchainInfo-target_rid">target_rid</a>, <a href="#CSharpToolchainInfo-vstest_dll">vstest_dll</a>)
</pre>

Defines resolved C# SDK tools, packs, and target monikers.

**FIELDS**

| Name  | Description |
| :------------- | :------------- |
| <a id="CSharpToolchainInfo-aspnetcore_ref_pack"></a>aspnetcore_ref_pack |  Depset of reference assembly Files for Microsoft.AspNetCore.App.    |
| <a id="CSharpToolchainInfo-csc_dll"></a>csc_dll |  Host File for Roslyn compiler assembly.    |
| <a id="CSharpToolchainInfo-csc_worker"></a>csc_worker |  Host executable File for persistent compilation worker.    |
| <a id="CSharpToolchainInfo-csc_worker_files"></a>csc_worker_files |  Depset of files required by csc_worker.    |
| <a id="CSharpToolchainInfo-dotnet_env"></a>dotnet_env |  Dictionary of sealed environment variables for hermetic dotnet execution.    |
| <a id="CSharpToolchainInfo-dotnet_muxer"></a>dotnet_muxer |  Host executable File for dotnet driver.    |
| <a id="CSharpToolchainInfo-host_pack"></a>host_pack |  Binary template File for target platform application host.    |
| <a id="CSharpToolchainInfo-host_rid"></a>host_rid |  Host runtime identifier string.    |
| <a id="CSharpToolchainInfo-ref_pack"></a>ref_pack |  Depset of reference assembly Files for target framework.    |
| <a id="CSharpToolchainInfo-runtime_pack"></a>runtime_pack |  Depset of runtime assembly Files for target platform.    |
| <a id="CSharpToolchainInfo-target_framework"></a>target_framework |  Target framework moniker string.    |
| <a id="CSharpToolchainInfo-target_rid"></a>target_rid |  Target runtime identifier string.    |
| <a id="CSharpToolchainInfo-vstest_dll"></a>vstest_dll |  Host File for vstest.console.dll.    |


