load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

def _proto_action_test_impl(ctx):
    env = analysistest.begin(ctx)

    actions = analysistest.target_actions(env)
    proto_actions = [a for a in actions if a.mnemonic == "ProtocGenCSharp"]
    asserts.equals(env, 1, len(proto_actions))
    proto_action = proto_actions[0]

    # .bazelrc prefers the prebuilt protoc, so the action must not run one built from source
    protoc = proto_action.argv[0]
    asserts.true(
        env,
        "prebuilt_protoc" in protoc,
        "Expected protoc from the prebuilt proto toolchain, got: %s" % protoc,
    )

    output_basenames = [f.basename for f in proto_action.outputs.to_list()]
    asserts.true(
        env,
        "Greeter.cs" in output_basenames,
        "Expected Greeter.cs in protoc outputs, got: %s" % output_basenames,
    )

    compile_actions = [a for a in actions if a.mnemonic == "CSharpCompile"]
    asserts.equals(env, 1, len(compile_actions))
    compile_inputs = [f.basename for f in compile_actions[0].inputs.to_list()]
    asserts.true(
        env,
        "Greeter.cs" in compile_inputs,
        "Expected generated Greeter.cs in CSharpCompile inputs, got: %s" % compile_inputs,
    )

    return analysistest.end(env)

proto_action_test = analysistest.make(_proto_action_test_impl)

def _missing_import_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "no csharp_proto_library in deps or exports compiles:\n  //tests/analysis:greeter.proto\n")
    return analysistest.end(env)

missing_import_test = analysistest.make(_missing_import_test_impl, expect_failure = True)
