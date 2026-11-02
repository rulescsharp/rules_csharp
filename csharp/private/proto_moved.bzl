"""Stubs for the proto rules that moved to the rules_csharp_proto module."""

def _moved_message(rule_name):
    return """{name} moved to the rules_csharp_proto module. Add it to MODULE.bazel:

    bazel_dep(name = "rules_csharp_proto", version = "0.4.0")

Then load the rule from the new module:

    load("@rules_csharp_proto//csharp:defs.bzl", "{name}")
""".format(name = rule_name)

def _csharp_proto_library_moved_impl(_ctx):
    fail(_moved_message("csharp_proto_library"))

def _csharp_grpc_library_moved_impl(_ctx):
    fail(_moved_message("csharp_grpc_library"))

_csharp_proto_library_moved = rule(implementation = _csharp_proto_library_moved_impl)
_csharp_grpc_library_moved = rule(implementation = _csharp_grpc_library_moved_impl)

def _moved_kwargs(kwargs):
    return {k: kwargs[k] for k in ["tags", "testonly", "visibility"] if k in kwargs}

def csharp_proto_library(name, **kwargs):
    """Moved to `@rules_csharp_proto//csharp:defs.bzl`. Fails the build with migration steps.

    Args:
      name: A unique name for this target.
      **kwargs: Ignored.
    """
    _csharp_proto_library_moved(name = name, **_moved_kwargs(kwargs))

def csharp_grpc_library(name, **kwargs):
    """Moved to `@rules_csharp_proto//csharp:defs.bzl`. Fails the build with migration steps.

    Args:
      name: A unique name for this target.
      **kwargs: Ignored.
    """
    _csharp_grpc_library_moved(name = name, **_moved_kwargs(kwargs))
