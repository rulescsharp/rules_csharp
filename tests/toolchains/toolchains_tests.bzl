"""Unit tests for the SDK version merge of the csharp extension."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//csharp:toolchains.bzl", "merge_dotnet_versions")

_DEFAULTS = ["8.0.403", "9.0.200", "10.0.100"]

def _dependency_keeps_root_sdks_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, _DEFAULTS, merge_dotnet_versions(_DEFAULTS, ["8.0.403", "9.0.200"]))
    asserts.equals(env, _DEFAULTS, merge_dotnet_versions(_DEFAULTS, ["9.0.100", "10.0.101"]))
    return unittest.end(env)

dependency_keeps_root_sdks_test = unittest.make(_dependency_keeps_root_sdks_impl)

def _dependency_adds_missing_framework_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, ["10.0.100", "8.0.403"], merge_dotnet_versions(["10.0.100"], ["8.0.403"]))
    asserts.equals(env, _DEFAULTS + ["11.0.100"], merge_dotnet_versions(_DEFAULTS, ["11.0.100"]))
    return unittest.end(env)

dependency_adds_missing_framework_test = unittest.make(_dependency_adds_missing_framework_impl)

def _newest_dependency_version_wins_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, ["10.0.100", "9.0.200"], merge_dotnet_versions(["10.0.100"], ["9.0.200", "9.0.100"]))
    asserts.equals(env, ["10.0.100", "8.0.416", "9.0.300"], merge_dotnet_versions(["10.0.100"], ["9.0.300", "8.0.403", "8.0.416"]))
    return unittest.end(env)

newest_dependency_version_wins_test = unittest.make(_newest_dependency_version_wins_impl)

def toolchains_test_suite(name):
    unittest.suite(
        name,
        dependency_keeps_root_sdks_test,
        dependency_adds_missing_framework_test,
        newest_dependency_version_wins_test,
    )
