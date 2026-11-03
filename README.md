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

## Supported versions

- Bazel 7, 8 and 9, with Bzlmod only.
- .NET SDK 8.0.403, 9.0.200 and 10.0.100 by default, which makes `net8.0`, `net9.0` and `net10.0` available.
  A target without `target_framework` gets the framework of the target that depends on it, or the newest
  configured one.
  Set `dotnet_versions` on the `csharp.toolchain` tag to pick other SDKs.
- Linux, macOS and Windows.

`bazel coverage` on Windows needs Bazel 9 or later.

## Protobuf and gRPC

`csharp_proto_library` and `csharp_grpc_library` live in the separate `rules_csharp_proto` module,
so `rules_csharp` itself has no protobuf dependency. See [proto/README.md](proto/README.md) for setup.

## Reference

- [Rules and providers](docs/defs.md): `csharp_library`, `csharp_binary`, `csharp_test`,
  `csharp_import` and the analyzer rules.
- [Module extensions](csharp/extensions.bzl): the `csharp` toolchain extension and the `nuget`
  extension for NuGet packages.
- [examples/](examples/): a minimal module that uses the rules.
