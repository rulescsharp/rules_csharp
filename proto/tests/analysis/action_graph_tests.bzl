load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

def _proto_action_test_impl(ctx):
    env = analysistest.begin(ctx)

    actions = analysistest.target_actions(env)
    proto_actions = [a for a in actions if a.mnemonic == "ProtocGenCSharp"]
    asserts.equals(env, 1, len(proto_actions))
    proto_action = proto_actions[0]

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
