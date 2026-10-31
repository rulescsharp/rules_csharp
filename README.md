<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API for rules_csharp.

Compiled assemblies and pdbs record source paths under `/_/` instead of the absolute build path, so
outputs are identical across machines and sandboxes. Map `/_/` to the workspace root in a debugger to
step into sources.

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

csharp_analyzer_library(<a href="#csharp_analyzer_library-name">name</a>, <a href="#csharp_analyzer_library-deps">deps</a>, <a href="#csharp_analyzer_library-srcs">srcs</a>, <a href="#csharp_analyzer_library-resources">resources</a>, <a href="#csharp_analyzer_library-analyzers">analyzers</a>, <a href="#csharp_analyzer_library-compile_refs">compile_refs</a>, <a href="#csharp_analyzer_library-content">content</a>,
                        <a href="#csharp_analyzer_library-copy_to_output">copy_to_output</a>, <a href="#csharp_analyzer_library-defines">defines</a>, <a href="#csharp_analyzer_library-dlls">dlls</a>, <a href="#csharp_analyzer_library-exports">exports</a>, <a href="#csharp_analyzer_library-generate_assembly_info">generate_assembly_info</a>,
                        <a href="#csharp_analyzer_library-implicit_usings">implicit_usings</a>, <a href="#csharp_analyzer_library-internals_visible_to">internals_visible_to</a>, <a href="#csharp_analyzer_library-langversion">langversion</a>, <a href="#csharp_analyzer_library-native_libs">native_libs</a>, <a href="#csharp_analyzer_library-nowarn">nowarn</a>,
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
| <a id="csharp_analyzer_library-resources"></a>resources |  Embedded resource files mapped to logical names.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_analyzer_library-analyzers"></a>analyzers |  Precompiled Roslyn analyzer DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-compile_refs"></a>compile_refs |  Precompiled reference assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-content"></a>content |  Static content files copied to runtime directories.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-copy_to_output"></a>copy_to_output |  Files mapped to destination output paths.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_analyzer_library-defines"></a>defines |  Preprocessor symbols to define during compilation.   | List of strings | optional |  `[]`  |
| <a id="csharp_analyzer_library-dlls"></a>dlls |  Precompiled implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-exports"></a>exports |  Dependencies exported to downstream consumers.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-generate_assembly_info"></a>generate_assembly_info |  Synthesize assembly information attributes.   | Boolean | optional |  `True`  |
| <a id="csharp_analyzer_library-implicit_usings"></a>implicit_usings |  Synthesize implicit global usings namespace imports.   | Boolean | optional |  `True`  |
| <a id="csharp_analyzer_library-internals_visible_to"></a>internals_visible_to |  Friend assembly names for InternalsVisibleTo.   | List of strings | optional |  `[]`  |
| <a id="csharp_analyzer_library-langversion"></a>langversion |  Target C# language version specification.   | String | optional |  `"latest"`  |
| <a id="csharp_analyzer_library-native_libs"></a>native_libs |  Unmanaged target platform shared libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-nowarn"></a>nowarn |  Compiler diagnostic codes to suppress.   | List of strings | optional |  `[]`  |
| <a id="csharp_analyzer_library-plugins"></a>plugins |  Roslyn analyzer and generator plugins.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-runtime_dlls"></a>runtime_dlls |  Precompiled runtime implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_analyzer_library-sdk"></a>sdk |  Target .NET SDK project flavor.   | String | optional |  `"Microsoft.NET.Sdk"`  |
| <a id="csharp_analyzer_library-target_framework"></a>target_framework |  Target framework moniker string.   | String | optional |  `""`  |
| <a id="csharp_analyzer_library-target_type"></a>target_type |  Compiler target type output flag.   | String | optional |  `"library"`  |
| <a id="csharp_analyzer_library-warn_as_error"></a>warn_as_error |  Treat compiler warnings as errors.   | Boolean | optional |  `False`  |
| <a id="csharp_analyzer_library-warning_level"></a>warning_level |  Compiler diagnostic severity level.   | Integer | optional |  `4`  |


<a id="csharp_binary"></a>

## csharp_binary

<pre>
load("@rules_csharp//csharp:defs.bzl", "csharp_binary")

csharp_binary(<a href="#csharp_binary-name">name</a>, <a href="#csharp_binary-deps">deps</a>, <a href="#csharp_binary-srcs">srcs</a>, <a href="#csharp_binary-resources">resources</a>, <a href="#csharp_binary-content">content</a>, <a href="#csharp_binary-copy_to_output">copy_to_output</a>, <a href="#csharp_binary-defines">defines</a>, <a href="#csharp_binary-exports">exports</a>,
              <a href="#csharp_binary-generate_assembly_info">generate_assembly_info</a>, <a href="#csharp_binary-implicit_usings">implicit_usings</a>, <a href="#csharp_binary-internals_visible_to">internals_visible_to</a>, <a href="#csharp_binary-langversion">langversion</a>, <a href="#csharp_binary-nowarn">nowarn</a>,
              <a href="#csharp_binary-plugins">plugins</a>, <a href="#csharp_binary-sdk">sdk</a>, <a href="#csharp_binary-target_framework">target_framework</a>, <a href="#csharp_binary-target_type">target_type</a>, <a href="#csharp_binary-warn_as_error">warn_as_error</a>, <a href="#csharp_binary-warning_level">warning_level</a>)
</pre>

Compiles a C# executable and stamps the native application host binary.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="csharp_binary-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="csharp_binary-deps"></a>deps |  Direct dependency libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_binary-srcs"></a>srcs |  C# source files to compile.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_binary-resources"></a>resources |  Embedded resource files mapped to logical names.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_binary-content"></a>content |  Static content files copied to runtime directories.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_binary-copy_to_output"></a>copy_to_output |  Files mapped to destination output paths.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_binary-defines"></a>defines |  Preprocessor symbols to define during compilation.   | List of strings | optional |  `[]`  |
| <a id="csharp_binary-exports"></a>exports |  Dependencies exported to downstream consumers.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_binary-generate_assembly_info"></a>generate_assembly_info |  Synthesize assembly information attributes.   | Boolean | optional |  `True`  |
| <a id="csharp_binary-implicit_usings"></a>implicit_usings |  Synthesize implicit global usings namespace imports.   | Boolean | optional |  `True`  |
| <a id="csharp_binary-internals_visible_to"></a>internals_visible_to |  Friend assembly names for InternalsVisibleTo.   | List of strings | optional |  `[]`  |
| <a id="csharp_binary-langversion"></a>langversion |  Target C# language version specification.   | String | optional |  `"latest"`  |
| <a id="csharp_binary-nowarn"></a>nowarn |  Compiler diagnostic codes to suppress.   | List of strings | optional |  `[]`  |
| <a id="csharp_binary-plugins"></a>plugins |  Roslyn analyzer and generator plugins.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_binary-sdk"></a>sdk |  Target .NET SDK project flavor.   | String | optional |  `"Microsoft.NET.Sdk"`  |
| <a id="csharp_binary-target_framework"></a>target_framework |  Target framework moniker string.   | String | optional |  `""`  |
| <a id="csharp_binary-target_type"></a>target_type |  Compiler target type output flag.   | String | optional |  `"exe"`  |
| <a id="csharp_binary-warn_as_error"></a>warn_as_error |  Treat compiler warnings as errors.   | Boolean | optional |  `False`  |
| <a id="csharp_binary-warning_level"></a>warning_level |  Compiler diagnostic severity level.   | Integer | optional |  `4`  |


<a id="csharp_grpc_library"></a>

## csharp_grpc_library

<pre>
load("@rules_csharp//csharp:defs.bzl", "csharp_grpc_library")

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
| <a id="csharp_grpc_library-target_framework"></a>target_framework |  Target framework moniker string.   | String | optional |  `""`  |
| <a id="csharp_grpc_library-target_type"></a>target_type |  Compiler target type output flag.   | String | optional |  `"library"`  |
| <a id="csharp_grpc_library-warn_as_error"></a>warn_as_error |  Treat compiler warnings as errors.   | Boolean | optional |  `False`  |
| <a id="csharp_grpc_library-warning_level"></a>warning_level |  Compiler diagnostic severity level.   | Integer | optional |  `4`  |


<a id="csharp_import"></a>

## csharp_import

<pre>
load("@rules_csharp//csharp:defs.bzl", "csharp_import")

csharp_import(<a href="#csharp_import-name">name</a>, <a href="#csharp_import-deps">deps</a>, <a href="#csharp_import-analyzers">analyzers</a>, <a href="#csharp_import-compile_refs">compile_refs</a>, <a href="#csharp_import-dlls">dlls</a>, <a href="#csharp_import-exports">exports</a>, <a href="#csharp_import-native_libs">native_libs</a>, <a href="#csharp_import-plugins">plugins</a>,
              <a href="#csharp_import-runtime_dlls">runtime_dlls</a>, <a href="#csharp_import-target_framework">target_framework</a>)
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


<a id="csharp_library"></a>

## csharp_library

<pre>
load("@rules_csharp//csharp:defs.bzl", "csharp_library")

csharp_library(<a href="#csharp_library-name">name</a>, <a href="#csharp_library-deps">deps</a>, <a href="#csharp_library-srcs">srcs</a>, <a href="#csharp_library-resources">resources</a>, <a href="#csharp_library-analyzers">analyzers</a>, <a href="#csharp_library-compile_refs">compile_refs</a>, <a href="#csharp_library-content">content</a>, <a href="#csharp_library-copy_to_output">copy_to_output</a>,
               <a href="#csharp_library-defines">defines</a>, <a href="#csharp_library-dlls">dlls</a>, <a href="#csharp_library-exports">exports</a>, <a href="#csharp_library-generate_assembly_info">generate_assembly_info</a>, <a href="#csharp_library-implicit_usings">implicit_usings</a>, <a href="#csharp_library-internals_visible_to">internals_visible_to</a>,
               <a href="#csharp_library-langversion">langversion</a>, <a href="#csharp_library-native_libs">native_libs</a>, <a href="#csharp_library-nowarn">nowarn</a>, <a href="#csharp_library-plugins">plugins</a>, <a href="#csharp_library-runtime_dlls">runtime_dlls</a>, <a href="#csharp_library-sdk">sdk</a>, <a href="#csharp_library-target_framework">target_framework</a>,
               <a href="#csharp_library-target_type">target_type</a>, <a href="#csharp_library-warn_as_error">warn_as_error</a>, <a href="#csharp_library-warning_level">warning_level</a>)
</pre>

Compiles C# source files into reference and implementation assemblies.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="csharp_library-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="csharp_library-deps"></a>deps |  Direct dependency libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-srcs"></a>srcs |  C# source files to compile.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-resources"></a>resources |  Embedded resource files mapped to logical names.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_library-analyzers"></a>analyzers |  Precompiled Roslyn analyzer DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-compile_refs"></a>compile_refs |  Precompiled reference assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-content"></a>content |  Static content files copied to runtime directories.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-copy_to_output"></a>copy_to_output |  Files mapped to destination output paths.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_library-defines"></a>defines |  Preprocessor symbols to define during compilation.   | List of strings | optional |  `[]`  |
| <a id="csharp_library-dlls"></a>dlls |  Precompiled implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-exports"></a>exports |  Dependencies exported to downstream consumers.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-generate_assembly_info"></a>generate_assembly_info |  Synthesize assembly information attributes.   | Boolean | optional |  `True`  |
| <a id="csharp_library-implicit_usings"></a>implicit_usings |  Synthesize implicit global usings namespace imports.   | Boolean | optional |  `True`  |
| <a id="csharp_library-internals_visible_to"></a>internals_visible_to |  Friend assembly names for InternalsVisibleTo.   | List of strings | optional |  `[]`  |
| <a id="csharp_library-langversion"></a>langversion |  Target C# language version specification.   | String | optional |  `"latest"`  |
| <a id="csharp_library-native_libs"></a>native_libs |  Unmanaged target platform shared libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-nowarn"></a>nowarn |  Compiler diagnostic codes to suppress.   | List of strings | optional |  `[]`  |
| <a id="csharp_library-plugins"></a>plugins |  Roslyn analyzer and generator plugins.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-runtime_dlls"></a>runtime_dlls |  Precompiled runtime implementation assembly DLL files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_library-sdk"></a>sdk |  Target .NET SDK project flavor.   | String | optional |  `"Microsoft.NET.Sdk"`  |
| <a id="csharp_library-target_framework"></a>target_framework |  Target framework moniker string.   | String | optional |  `""`  |
| <a id="csharp_library-target_type"></a>target_type |  Compiler target type output flag.   | String | optional |  `"library"`  |
| <a id="csharp_library-warn_as_error"></a>warn_as_error |  Treat compiler warnings as errors.   | Boolean | optional |  `False`  |
| <a id="csharp_library-warning_level"></a>warning_level |  Compiler diagnostic severity level.   | Integer | optional |  `4`  |


<a id="csharp_proto_library"></a>

## csharp_proto_library

<pre>
load("@rules_csharp//csharp:defs.bzl", "csharp_proto_library")

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
| <a id="csharp_proto_library-target_framework"></a>target_framework |  Target framework moniker string.   | String | optional |  `""`  |
| <a id="csharp_proto_library-target_type"></a>target_type |  Compiler target type output flag.   | String | optional |  `"library"`  |
| <a id="csharp_proto_library-warn_as_error"></a>warn_as_error |  Treat compiler warnings as errors.   | Boolean | optional |  `False`  |
| <a id="csharp_proto_library-warning_level"></a>warning_level |  Compiler diagnostic severity level.   | Integer | optional |  `4`  |


<a id="csharp_test"></a>

## csharp_test

<pre>
load("@rules_csharp//csharp:defs.bzl", "csharp_test")

csharp_test(<a href="#csharp_test-name">name</a>, <a href="#csharp_test-deps">deps</a>, <a href="#csharp_test-srcs">srcs</a>, <a href="#csharp_test-data">data</a>, <a href="#csharp_test-resources">resources</a>, <a href="#csharp_test-content">content</a>, <a href="#csharp_test-copy_to_output">copy_to_output</a>, <a href="#csharp_test-defines">defines</a>, <a href="#csharp_test-env">env</a>, <a href="#csharp_test-env_inherit">env_inherit</a>,
            <a href="#csharp_test-exports">exports</a>, <a href="#csharp_test-generate_assembly_info">generate_assembly_info</a>, <a href="#csharp_test-implicit_usings">implicit_usings</a>, <a href="#csharp_test-internals_visible_to">internals_visible_to</a>, <a href="#csharp_test-langversion">langversion</a>,
            <a href="#csharp_test-nowarn">nowarn</a>, <a href="#csharp_test-plugins">plugins</a>, <a href="#csharp_test-sdk">sdk</a>, <a href="#csharp_test-target_framework">target_framework</a>, <a href="#csharp_test-target_type">target_type</a>, <a href="#csharp_test-test_filter">test_filter</a>, <a href="#csharp_test-warn_as_error">warn_as_error</a>,
            <a href="#csharp_test-warning_level">warning_level</a>)
</pre>

Compiles and executes a C# test binary under the Bazel test harness.

`bazel coverage` reports line, branch, and method coverage of instrumented C# sources, collected with
[Coverlet](https://github.com/coverlet-coverage/coverlet) and merged by Bazel into LCOV. Coverage runs on
Linux (macOS is not verified yet). Windows test runners report none.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="csharp_test-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="csharp_test-deps"></a>deps |  Direct dependency libraries.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_test-srcs"></a>srcs |  C# source files to compile.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_test-data"></a>data |  Runtime data files for test execution.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_test-resources"></a>resources |  Embedded resource files mapped to logical names.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_test-content"></a>content |  Static content files copied to runtime directories.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_test-copy_to_output"></a>copy_to_output |  Files mapped to destination output paths.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional |  `{}`  |
| <a id="csharp_test-defines"></a>defines |  Preprocessor symbols to define during compilation.   | List of strings | optional |  `[]`  |
| <a id="csharp_test-env"></a>env |  Environment variables for test execution.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional |  `{}`  |
| <a id="csharp_test-env_inherit"></a>env_inherit |  Environment variables inherited from client environment.   | List of strings | optional |  `[]`  |
| <a id="csharp_test-exports"></a>exports |  Dependencies exported to downstream consumers.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_test-generate_assembly_info"></a>generate_assembly_info |  Synthesize assembly information attributes.   | Boolean | optional |  `True`  |
| <a id="csharp_test-implicit_usings"></a>implicit_usings |  Synthesize implicit global usings namespace imports.   | Boolean | optional |  `True`  |
| <a id="csharp_test-internals_visible_to"></a>internals_visible_to |  Friend assembly names for InternalsVisibleTo.   | List of strings | optional |  `[]`  |
| <a id="csharp_test-langversion"></a>langversion |  Target C# language version specification.   | String | optional |  `"latest"`  |
| <a id="csharp_test-nowarn"></a>nowarn |  Compiler diagnostic codes to suppress.   | List of strings | optional |  `[]`  |
| <a id="csharp_test-plugins"></a>plugins |  Roslyn analyzer and generator plugins.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="csharp_test-sdk"></a>sdk |  Target .NET SDK project flavor.   | String | optional |  `"Microsoft.NET.Sdk"`  |
| <a id="csharp_test-target_framework"></a>target_framework |  Target framework moniker string.   | String | optional |  `""`  |
| <a id="csharp_test-target_type"></a>target_type |  Compiler target type output flag.   | String | optional |  `"exe"`  |
| <a id="csharp_test-test_filter"></a>test_filter |  Default test filter expression.   | String | optional |  `""`  |
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

CSharpInfo(<a href="#CSharpInfo-compile_ref">compile_ref</a>, <a href="#CSharpInfo-pdb">pdb</a>, <a href="#CSharpInfo-runtime_dll">runtime_dll</a>, <a href="#CSharpInfo-target_framework">target_framework</a>, <a href="#CSharpInfo-transitive_compile_refs">transitive_compile_refs</a>,
           <a href="#CSharpInfo-transitive_native_libs">transitive_native_libs</a>, <a href="#CSharpInfo-transitive_runtime_dlls">transitive_runtime_dlls</a>)
</pre>

Propagates compilation references, runtime assemblies, and unmanaged libraries.

**FIELDS**

| Name  | Description |
| :------------- | :------------- |
| <a id="CSharpInfo-compile_ref"></a>compile_ref |  Metadata-only reference assembly File produced by -refout.    |
| <a id="CSharpInfo-pdb"></a>pdb |  Portable program database symbol File.    |
| <a id="CSharpInfo-runtime_dll"></a>runtime_dll |  Implementation assembly File.    |
| <a id="CSharpInfo-target_framework"></a>target_framework |  Target framework moniker string (for example net8.0).    |
| <a id="CSharpInfo-transitive_compile_refs"></a>transitive_compile_refs |  Depset of reference assembly Files for compilation.    |
| <a id="CSharpInfo-transitive_native_libs"></a>transitive_native_libs |  Depset of target platform unmanaged shared libraries.    |
| <a id="CSharpInfo-transitive_runtime_dlls"></a>transitive_runtime_dlls |  Depset of runtime assembly Files for execution.    |


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


