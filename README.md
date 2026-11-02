# rules_csharp

Bazel rules that build, run and test C# with a hermetic .NET SDK.

## Install

Add this to `MODULE.bazel`:

```starlark
bazel_dep(name = "rules_csharp", version = "0.3.0")

csharp = use_extension("@rules_csharp//csharp:extensions.bzl", "csharp")
use_repo(csharp, "dotnet_toolchains")

register_toolchains("@dotnet_toolchains//:all")
```

The extension downloads the .NET SDK. 0.3.0 is the latest release. This README describes `main`.
The Windows `bazel run` and coverage fixes and the separate proto module are not in a release yet.

## Example

From [examples/BUILD.bazel](examples/BUILD.bazel), minus its `package()` line:

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

`bazel run //:hello` prints `Hello, Bazel!`. `bazel test //:greeter_test` runs the test program and
fails when it exits nonzero.

## Supported versions

- Bazel 7, 8 and 9, with Bzlmod only.
- .NET SDK 8.0.403, 9.0.200 and 10.0.100 by default, which makes `net8.0`, `net9.0` and `net10.0` available.
  A target without `target_framework` gets the framework of the target that depends on it, or the newest
  configured one.
  Set `dotnet_versions` on the `csharp.toolchain` tag to pick other SDKs.
- Linux, macOS and Windows.

On every pull request, CI runs the rule tests, the proto module tests and the [examples/](examples/)
tests, runs `bazel run //:hello` and checks `bazel coverage` on Linux, macOS and Windows. These jobs
pin no Bazel version, so Bazelisk runs the latest Bazel release (9.3.1 as of November 2026). A
second job tests the examples with the latest Bazel 7.x and 8.x on Linux. Coverage on Windows needs
Bazel 9 or later. See [.github/workflows/ci.yml](.github/workflows/ci.yml).

## Protobuf and gRPC

`csharp_proto_library` and `csharp_grpc_library` live in the separate `rules_csharp_proto` module on
`main`, so `rules_csharp` itself has no protobuf dependency. See [proto/README.md](proto/README.md) for setup.
`rules_csharp_proto` is not on the Bazel Central Registry yet.

## Reference

- [Rules and providers](docs/defs.md): `csharp_library`, `csharp_binary`, `csharp_test`,
  `csharp_import` and the analyzer rules.
- [Module extensions](csharp/extensions.bzl): the `csharp` toolchain extension and the `nuget`
  extension for NuGet packages.
- [examples/](examples/): a minimal module that uses the rules.
