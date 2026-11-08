# rules_csharp

Bazel rules that build, run and test C# with a hermetic .NET SDK. `csharp_library`, `csharp_binary` and
`csharp_test` targets take the place of `.csproj` files, their attributes map to familiar MSBuild items and
properties, and NuGet packages come from the `packages.lock.json` that `dotnet restore` writes. The rules
cover C# only.

## Install

Add this to `MODULE.bazel`:

```starlark
bazel_dep(name = "rules_csharp", version = "0.5.0")

csharp = use_extension("@rules_csharp//csharp:extensions.bzl", "csharp")
use_repo(csharp, "dotnet_toolchains")

register_toolchains("@dotnet_toolchains//:all")
```

The extension downloads a hermetic .NET SDK, so nothing needs to be installed on the machine.

## Example

From [examples/](examples/):

```starlark
load("@rules_csharp//csharp:defs.bzl", "csharp_binary", "csharp_library", "csharp_test")

csharp_library(
    name = "greeter",
    srcs = ["Greeter.cs"],
    generate_documentation_file = True,
    target_framework = "net8.0",
)

csharp_binary(
    name = "hello",
    srcs = ["Hello.cs"],
    deps = [":greeter"],
)

csharp_test(
    name = "greeter_test",
    srcs = ["GreeterTest.cs"],
    target_framework = "net8.0",
    deps = [":greeter"],
)
```

`bazel run //:hello` prints `Hello, Bazel!` and a note that it's a Debug build, and `bazel test //:greeter_test`
runs the test. Bazel's default and `-c dbg` builds match the MSBuild Debug configuration and define `DEBUG` and
`TRACE`. `-c opt` matches Release, with optimizations on and only `TRACE` defined, so `bazel run -c opt //:hello`
prints just the greeting. `generate_documentation_file` also writes `greeter.xml` next to `greeter.dll`, so IDEs
show the `///` docs to anything that references the library.

[examples/web](examples/web/) uses ASP.NET Core from a library through `framework_references`, checks
that library against an `.editorconfig` through `editorconfig_files`, names the app assembly with
`output_assembly` and reads a `data` file at run time. `bazel run //web` prints `200 Hello, web!`.

These attributes do the same job as the MSBuild items and properties of a `.csproj`:

| MSBuild | rules_csharp |
| --- | --- |
| `<FrameworkReference Include="Microsoft.AspNetCore.App" />` | `framework_references = ["Microsoft.AspNetCore.App"]` |
| `<AssemblyName>` | `output_assembly` |
| `<EditorConfigFiles Include=".editorconfig" />` | `editorconfig_files = [".editorconfig"]` |
| `<AllowUnsafeBlocks>true</AllowUnsafeBlocks>` | `allow_unsafe_blocks = True` |
| `<GenerateDocumentationFile>true</GenerateDocumentationFile>` | `generate_documentation_file = True` |
| `<DefineConstants>` | `defines` |
| `dotnet build -c Release` | `bazel build -c opt` |

## Testing with MSTest or xUnit

Set `target_type = "library"` and depend on `Microsoft.NET.Test.Sdk` plus a framework and its adapter
from the [`nuget` extension](csharp/extensions.bzl). The test then runs under VSTest, the same runner
as `dotnet test`. The packages come from a `packages.lock.json`, which `dotnet restore --use-lock-file`
writes. Add the extension to `MODULE.bazel` and make its `@nuget` hub visible:

```starlark
nuget = use_extension("@rules_csharp//csharp:extensions.bzl", "nuget")
nuget.from_lock(packages_lock_json = "//:packages.lock.json")
use_repo(nuget, "nuget")
```

Then the test depends on the packages. From [examples/](examples/):

```starlark
csharp_test(
    name = "greeter_mstest",
    srcs = ["GreeterMSTest.cs"],
    shard_count = 2,
    target_framework = "net8.0",
    target_type = "library",
    deps = [
        ":greeter",
        "@nuget//:MSTest.TestAdapter",
        "@nuget//:MSTest.TestFramework",
        "@nuget//:Microsoft.NET.Test.Sdk",
    ],
)
```

A test that runs no tests fails, so a missing adapter or a filter that matches nothing can't pass by
accident. `test_filter` and `--test_filter` take a VSTest
[filter](https://learn.microsoft.com/dotnet/core/testing/selective-unit-tests) such as
`TestCategory=Fast`.

With `shard_count`, each shard runs its own share of the test cases. Cases that share a name, like the
rows of a data driven test, stay together in one shard. xUnit v2 only applies trait filters while
running, not while listing, so a sharded xUnit test whose filter matches nothing passes instead of
failing.

### Per-test results in test.xml

Each library test writes one `<testcase>` per test, with the failure message and stack trace, to the
`test.xml` Bazel collects, so CI and result viewers that read JUnit XML show every case. The TRX report
VSTest writes is in the test's undeclared outputs (`test.outputs/`). A test that sets
`target_framework` builds in a configuration for it, so its files are under
`bazel-out/<config>-ST-<hash>/testlogs/` instead of behind the `bazel-testlogs` link. Tools that read
Bazel's build event protocol find them either way.

An exe test (the default `target_type`) runs its own `Main`. It owns sharding and `test.xml` itself
through Bazel's [test environment](https://bazel.build/reference/test-encyclopedia).

## Supported versions

- Bazel 7, 8 and 9, with Bzlmod only.
- .NET SDK 8.0.403, 9.0.200 and 10.0.100 by default, which makes `net8.0`, `net9.0` and `net10.0` available.
  A target without `target_framework` gets the framework of the target that depends on it, or the newest
  configured one.
  Set `dotnet_versions` on the `csharp.toolchain` tag to pick other SDKs.
- Linux, macOS and Windows.
- NuGet packages get their `runtimes/` files for `linux-x64`, `linux-arm64`, `osx-arm64`, `osx-x64`
  and `win-x64`. Like `dotnet restore`, each RID falls back along the
  [RID graph](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog) to the first match:
  `linux-x64` and `linux-arm64` to `linux` and then `unix`, `osx-arm64` and `osx-x64` to `osx`
  and then `unix`, and `win-x64` to `win`. A package with none of them uses its `lib/` files.

`bazel coverage` on Windows needs Bazel 9 or later.

## Running fully offline

By default the SDK comes from `mirror_urls` first and then from Microsoft's download CDN, and NuGet
packages come from `local_package_dirs` and `feeds` first and then from nuget.org. To download only
from private sources, turn the public ones off on both extensions:

```starlark
csharp = use_extension("@rules_csharp//csharp:extensions.bzl", "csharp")
csharp.toolchain(
    dotnet_versions = ["8.0.404"],
    mirror_urls = ["https://artifacts.example.com/dotnet"],
    sdk_checksums = {
        "dotnet-sdk-8.0.404-linux-x64.tar.gz": "<sha512 from releases.json>",
    },
    use_public_sources = False,
)

nuget = use_extension("@rules_csharp//csharp:extensions.bzl", "nuget")
nuget.from_lock(
    feeds = ["https://artifacts.example.com/nuget/v3/flatcontainer"],
    packages_lock_json = "//:packages.lock.json",
    use_public_sources = False,
)
use_repo(nuget, "nuget")
```

- `use_public_sources = False` works like `<clear />` at the top of `<packageSources>` in a
  NuGet.Config. A `nuget_config` that has `<clear />` turns public sources off by itself.
- A feed in `feeds` or `nuget_config` can be its v3 `index.json`, as in a NuGet.Config. Packages
  come from the `PackageBaseAddress/3.0.0` that `index.json` lists, the same place `dotnet restore`
  gets them.
- `sdk_checksums` pins any SDK version by archive file name. Copy the `hash` for each file from
  the version's [releases.json](https://builds.dotnet.microsoft.com/dotnet/release-metadata/8.0/releases.json).
  The defaults in `dotnet_versions` are already pinned.
- A mirror or feed can also be a local directory as a `file://` URL, so a machine with no network
  can build from a copy on disk.
- The mirror holds the archives at `{mirror}/dotnet/Sdk/{version}/{archive}` (see `url_templates`)
  and `coverlet.console.10.1.0.nupkg` at `{mirror}/` for `bazel coverage`.
- With public sources off, a package whose `contentHash` is empty in `packages.lock.json` fails
  instead of downloading unverified.

## NuGet packages in a library module

Each `nuget.from_lock` name is its own hub. A module that others depend on should pick a name of its
own, so its packages never mix with the root's `@nuget`:

```starlark
nuget = use_extension("@rules_csharp//csharp:extensions.bzl", "nuget")
nuget.from_lock(
    name = "mylib_nuget",
    packages_lock_json = "//:packages.lock.json",
)
use_repo(nuget, "mylib_nuget")
```

Its targets then depend on `@mylib_nuget//:Newtonsoft.Json`. Each hub has its own sources and
versions, so two hubs can pin different versions of one package. Tags with the same name share a hub.

## Protobuf and gRPC

`csharp_proto_library` and `csharp_grpc_library` live in the separate `rules_csharp_proto` module,
so `rules_csharp` itself has no protobuf dependency. See [proto/README.md](proto/README.md) for setup.

## Reference

- [Rules and providers](docs/defs.md): `csharp_library`, `csharp_binary`, `csharp_test`,
  `csharp_import` and the analyzer rules.
- [Module extensions](csharp/extensions.bzl): the `csharp` toolchain extension and the `nuget`
  extension for NuGet packages.
- [examples/](examples/): a minimal module that uses the rules.
