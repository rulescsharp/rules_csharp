# rules_csharp

Bazel rules that build, run and test C# with a hermetic .NET SDK.

## Install

Add this to `MODULE.bazel`:

```starlark
bazel_dep(name = "rules_csharp", version = "0.4.0")

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

`bazel run //:hello` prints `Hello, Bazel!`, and `bazel test //:greeter_test` runs the test.

## Testing with MSTest or xUnit

Set `target_type = "library"` and depend on `Microsoft.NET.Test.Sdk` plus a framework and its adapter
from the [`nuget` extension](csharp/extensions.bzl). The test then runs under VSTest, the same runner
as `dotnet test`. From [examples/](examples/):

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

## Protobuf and gRPC

`csharp_proto_library` and `csharp_grpc_library` live in the separate `rules_csharp_proto` module,
so `rules_csharp` itself has no protobuf dependency. See [proto/README.md](proto/README.md) for setup.

## Reference

- [Rules and providers](docs/defs.md): `csharp_library`, `csharp_binary`, `csharp_test`,
  `csharp_import` and the analyzer rules.
- [Module extensions](csharp/extensions.bzl): the `csharp` toolchain extension and the `nuget`
  extension for NuGet packages.
- [examples/](examples/): a minimal module that uses the rules.
