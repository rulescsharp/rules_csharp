"""Compilation rules for rules_csharp."""

load(":common.bzl", "TARGET_FRAMEWORKS", "TARGET_FRAMEWORK_DOC", "target_framework_transition")
load(":providers.bzl", "CSharpAnalyzerInfo", "CSharpInfo", "CSharpToolchainInfo")
load(":toolchain_impl.bzl", "SEALED_DOTNET_ENV")

_ASPNETCORE_APP = "Microsoft.AspNetCore.App"

# Shared frameworks the toolchain ships reference assemblies for. Microsoft.NETCore.App is always referenced.
_SUPPORTED_FRAMEWORK_REFERENCES = [_ASPNETCORE_APP]

FRAMEWORK_REFERENCES_DOC = """Shared frameworks this target uses, the same as MSBuild `FrameworkReference` items. The only \
supported value is `"Microsoft.AspNetCore.App"`, since `Microsoft.NETCore.App` is always referenced. A target gets the framework's \
reference assemblies at compile time, and everything that depends on it gets them too, so an executable lists the \
framework in its runtimeconfig.json and the runtime loads it. `sdk = "Microsoft.NET.Sdk.Web"` implies \
`"Microsoft.AspNetCore.App"`."""

SDK_DOC = """Project SDK the target follows, the same as the `Sdk` of an MSBuild project. `Microsoft.NET.Sdk.Web` adds the \
ASP.NET Core implicit usings, references `Microsoft.AspNetCore.App` and, for an executable, turns on server garbage \
collection (MSBuild `ServerGarbageCollection`) in its runtimeconfig.json. Other executables use workstation garbage \
collection and the default roll forward, which stays on their own .NET major version, like dotnet build. `Microsoft.NET.Sdk.Worker` adds the \
Microsoft.Extensions hosting usings and, as in MSBuild, no reference, so the target also needs \
`framework_references = ["Microsoft.AspNetCore.App"]` or the Microsoft.Extensions.Hosting NuGet package."""

RESOURCES_DOC = """Files to embed in the assembly, the same as MSBuild `EmbeddedResource`, each mapped to its \
manifest resource name. An empty name defaults to `<output_assembly>.<file name>`. A `.resx` file is compiled to \
`.resources` first and its default name ends in `.resources`, so `new ResourceManager("<output_assembly>.Strings", \
assembly)` reads `Strings.resx`. Only string entries are supported in `.resx` files, and an entry with a `type` or \
`mimetype` fails the build."""

OUTPUT_ASSEMBLY_DOC = """Name of the compiled assembly, the same as MSBuild `AssemblyName`. Defaults to the target \
name. It names the dll, pdb and reference assembly, and for executables the runtimeconfig.json and deps.json, and it \
is the default prefix of embedded resource names. The executable Bazel runs keeps the target name. Two assemblies with \
the same name can't load into one app, so an executable fails analysis when two of its assemblies share a name and \
one of them is built from sources."""

EDITORCONFIG_FILES_DOC = """`.editorconfig` and global analyzer config files passed to the compiler with \
`-analyzerconfig`, the same as MSBuild `EditorConfigFiles` items. Sections such as `[*.cs]` match source paths \
under the directory of the file, so keep a `.editorconfig` next to or above the sources it covers. Severity settings \
such as `dotnet_diagnostic.CS8618.severity = none` apply to compiler warnings. CA and IDE rules come from analyzers, so \
they take effect only when the analyzer package is in `plugins` or `deps`."""

ADDITIONAL_COMPILER_OPTIONS_DOC = """Extra `csc` tokens appended after the rule's own flags, the same as MSBuild \
`AdditionalOptions`. Each entry is one token such as `-checked+` or `-highentropyva-`. Prefer the dedicated attributes \
(`defines`, `nowarn`, `langversion`, `warning_level`, `warn_as_error`) when they cover the flag. Empty entries and \
response files that start with `@` fail analysis."""

ALLOW_UNSAFE_BLOCKS_DOC = """Allows `unsafe` code, the same as MSBuild `AllowUnsafeBlocks`. Without it the compiler \
rejects any `unsafe` block or member with CS0227."""

GENERATE_DOCUMENTATION_FILE_DOC = """Writes the `///` comments to `<assembly>.xml` next to the dll, the same as MSBuild \
`GenerateDocumentationFile`. IDEs read that file to show the docs for anyone who references the assembly. Like \
MSBuild, the compiler then warns with CS1591 for each public member that has no `///` comment, which fails the build \
under `warn_as_error` unless `nowarn` lists it."""

DEFINES_DOC = """Preprocessor symbols to define during compilation, the same as MSBuild `DefineConstants`. Every \
compilation mode except `-c opt` also defines `DEBUG` and `TRACE`, like the MSBuild Debug configuration. `-c opt` \
defines `TRACE` and `RELEASE` and turns on optimizations, like the Release configuration. Like dotnet build, every \
target also gets the symbols of its target framework: `NET`, `NETCOREAPP`, `NET<major>_0`, `NET5_0_OR_GREATER` up to \
`NET<major>_0_OR_GREATER`, and `NETCOREAPP1_0_OR_GREATER` up to `NETCOREAPP3_1_OR_GREATER`. So a `net8.0` target \
defines `NET8_0` and `NET8_0_OR_GREATER` but not `NET9_0_OR_GREATER`."""

INTERNALS_VISIBLE_TO_DOC = """Friend assembly names, the same as MSBuild `InternalsVisibleTo` items. Each friend compiles against a reference assembly that keeps internal members. Every other dependent compiles against a public reference assembly without them, so an internal edit only recompiles the friends."""

DATA_DOC = """Files and targets needed at run time. Their files and runfiles join the runfiles of this target and of \
every executable that depends on it, along with the `content` of libraries it depends on."""

def library_runfiles(ctx, deps):
    """Returns the runfiles of a target's data and of the targets it depends on.

    Args:
      ctx: The rule context.
      deps: Targets whose runfiles an executable needs alongside this target.

    Returns:
      A runfiles object.
    """
    data = getattr(ctx.attr, "data", [])
    return ctx.runfiles(files = getattr(ctx.files, "data", [])).merge_all(
        [t[DefaultInfo].default_runfiles for t in data] + [d[DefaultInfo].default_runfiles for d in deps],
    )

def output_assembly(ctx):
    """Returns the assembly name a target compiles to.

    Args:
      ctx: The rule context.

    Returns:
      The assembly name, without an extension.
    """
    name = getattr(ctx.attr, "output_assembly", "")
    if not name:
        return ctx.label.name
    if "/" in name or "\\" in name or name.lower().endswith((".dll", ".exe")):
        fail("output_assembly of {} is \"{}\". Use an assembly name without a directory or extension.".format(ctx.label, name))
    return name

def framework_references(ctx, deps):
    """Returns the shared frameworks a target and its dependencies use.

    Args:
      ctx: The rule context.
      deps: Targets whose CSharpInfo carries their own framework references.

    Returns:
      A depset of shared framework names.
    """
    own = []
    for name in getattr(ctx.attr, "framework_references", []):
        if name not in _SUPPORTED_FRAMEWORK_REFERENCES:
            fail("framework_references of {} lists \"{}\", which is not a shared framework the toolchain provides. Use one of: {}. Microsoft.NETCore.App is always referenced.".format(
                ctx.label,
                name,
                ", ".join(_SUPPORTED_FRAMEWORK_REFERENCES),
            ))
        own.append(name)
    if getattr(ctx.attr, "sdk", "") == "Microsoft.NET.Sdk.Web":
        own.append(_ASPNETCORE_APP)

    # CSharpInfo created by an older rules_csharp has no framework_references field.
    transitive = [getattr(dep[CSharpInfo], "framework_references", None) for dep in deps if CSharpInfo in dep]
    return depset(own, transitive = [d for d in transitive if d])

def _compile_impl(ctx, is_analyzer = False, extra_srcs = [], out_dir = ""):
    toolchain = ctx.toolchains["@rules_csharp//csharp:toolchain_type"].csharp_info

    assembly = output_assembly(ctx)
    if assembly != ctx.label.name and not out_dir:
        # Keeps two libraries in one package from writing the same file.
        out_dir = ctx.label.name + "_/"
    out_dll = ctx.actions.declare_file(out_dir + assembly + ".dll")
    refout_dll = ctx.actions.declare_file(out_dir + assembly + ".ref.dll")
    pdb = ctx.actions.declare_file(out_dir + assembly + ".pdb")
    xml_doc = ctx.actions.declare_file(out_dir + assembly + ".xml") if getattr(ctx.attr, "generate_documentation_file", False) else None

    direct_deps_and_exports = list(ctx.attr.deps) + list(getattr(ctx.attr, "exports", []))

    # Transitive compile references from deps and exports (preorder)
    transitive_compile_depsets = []
    for dep in direct_deps_and_exports:
        if CSharpInfo in dep:
            transitive_compile_depsets.append(dep[CSharpInfo].transitive_compile_refs)

    # Analyzers from plugins and deps
    analyzer_depsets = []
    for plugin in getattr(ctx.attr, "plugins", []):
        if CSharpAnalyzerInfo in plugin:
            analyzer_depsets.append(plugin[CSharpAnalyzerInfo].analyzers)
    for dep in ctx.attr.deps:
        if CSharpAnalyzerInfo in dep:
            analyzer_depsets.append(dep[CSharpAnalyzerInfo].analyzers)

    analyzers_depset = depset(transitive = analyzer_depsets)

    # Flags shared by the compile and the public reference assembly actions
    args = []
    target_type = getattr(ctx.attr, "target_type", "library")
    args.append("-target:" + target_type)

    # Unconditional architectural invariant flags
    args.append("-noconfig")
    args.append("-nostdlib+")
    args.append("-deterministic+")
    args.append("-utf8output")
    args.append("-nologo")
    args.append("-debug:portable")
    args.append("-highentropyva+")
    args.append("-nullable:enable")
    # Language and diagnostic invariant flags
    langversion = getattr(ctx.attr, "langversion", "latest")
    args.append("-langversion:" + langversion)
    warning_level = getattr(ctx.attr, "warning_level", 4)
    args.append("-warn:" + str(warning_level))
    # MSBuild always turns off these assembly version unification warnings.
    args.append("-nowarn:1701,1702")
    if getattr(ctx.attr, "warn_as_error", False):
        args.append("-warnaserror+")
    if getattr(ctx.attr, "allow_unsafe_blocks", False):
        args.append("-unsafe+")

    # -c opt is the MSBuild Release configuration, every other mode is Debug.
    if ctx.var["COMPILATION_MODE"] == "opt":
        args.append("-optimize+")
        args.append("-define:TRACE;RELEASE")
    else:
        args.append("-define:DEBUG;TRACE")

    # The implicit target framework symbols dotnet build defines, such as NET8_0 and NET8_0_OR_GREATER.
    target_framework = getattr(ctx.attr, "target_framework", "") or toolchain.target_framework
    framework_version = target_framework.removeprefix("net")
    major = int(framework_version.split(".")[0])
    args.append("-define:" + ";".join(
        ["NET", "NET%d_0" % major, "NETCOREAPP"] +
        ["NET%d_0_OR_GREATER" % v for v in range(5, major + 1)] +
        ["NETCOREAPP%s_OR_GREATER" % v for v in ["1_0", "1_1", "2_0", "2_1", "2_2", "3_0", "3_1"]],
    ))

    for d in getattr(ctx.attr, "defines", []):
        args.append("-define:" + d)
    for nw in getattr(ctx.attr, "nowarn", []):
        args.append("-nowarn:" + nw)
    for opt in getattr(ctx.attr, "additional_compiler_options", []):
        if not opt:
            fail("additional_compiler_options of {} has an empty entry. Pass one csc token per entry.".format(ctx.label))
        if opt.startswith("@"):
            fail("additional_compiler_options of {} lists \"{}\". Response files are not allowed. Pass one csc token per entry.".format(ctx.label, opt))
        args.append(opt)

    # Toolchain reference assemblies
    for ref in toolchain.ref_pack.to_list():
        args.append("-reference:" + ref.path.replace("\\", "/"))

    sdk_flavor = getattr(ctx.attr, "sdk", "Microsoft.NET.Sdk")
    frameworks = framework_references(ctx, direct_deps_and_exports)
    uses_aspnetcore = _ASPNETCORE_APP in frameworks.to_list()
    aspnet_depsets = []
    if uses_aspnetcore and hasattr(toolchain, "aspnetcore_ref_pack") and toolchain.aspnetcore_ref_pack:
        aspnet_depsets.append(toolchain.aspnetcore_ref_pack)
        for ref in toolchain.aspnetcore_ref_pack.to_list():
            args.append("-reference:" + ref.path.replace("\\", "/"))

    # Dependency compile references. A library that names this assembly in internals_visible_to gives it the
    # reference assembly with internals in place of the public one every other dependent compiles against.
    friend_refs = depset(transitive = [
        getattr(dep[CSharpInfo], "friend_refs", None) or depset()
        for dep in direct_deps_and_exports
        if CSharpInfo in dep
    ])
    internal_refs = {
        f.public: f.internal
        for f in friend_refs.to_list()
        if assembly.lower() in f.friends
    }
    all_compile_refs = [
        internal_refs.get(ref, ref)
        for ref in depset(transitive = transitive_compile_depsets, order = "preorder").to_list()
    ]
    for ref in all_compile_refs:
        args.append("-reference:" + ref.path.replace("\\", "/"))

    # Analyzers
    for analyzer in analyzers_depset.to_list():
        args.append("-analyzer:" + analyzer.path.replace("\\", "/"))

    editorconfig_files = getattr(ctx.files, "editorconfig_files", [])
    for f in editorconfig_files:
        args.append("-analyzerconfig:" + f.path.replace("\\", "/"))

    # Synthesized GlobalUsings
    synthesized_srcs = []
    if getattr(ctx.attr, "implicit_usings", True):
        global_usings_file = ctx.actions.declare_file(ctx.label.name + ".GlobalUsings.g.cs")
        namespaces = [
            "System",
            "System.Collections.Generic",
            "System.IO",
            "System.Linq",
            "System.Net.Http",
            "System.Threading",
            "System.Threading.Tasks",
        ]
        # The same usings the Web and Worker SDKs add in MSBuild
        if sdk_flavor == "Microsoft.NET.Sdk.Web":
            namespaces.extend([
                "System.Net.Http.Json",
                "Microsoft.AspNetCore.Builder",
                "Microsoft.AspNetCore.Hosting",
                "Microsoft.AspNetCore.Http",
                "Microsoft.AspNetCore.Routing",
            ])
        if sdk_flavor in ("Microsoft.NET.Sdk.Web", "Microsoft.NET.Sdk.Worker"):
            namespaces.extend([
                "Microsoft.Extensions.Configuration",
                "Microsoft.Extensions.DependencyInjection",
                "Microsoft.Extensions.Hosting",
                "Microsoft.Extensions.Logging",
            ])
        if sdk_flavor == "Microsoft.NET.Sdk.Worker" and not uses_aspnetcore and not [
            ref
            for ref in all_compile_refs
            if ref.basename.startswith("Microsoft.Extensions.Hosting.Abstractions.")
        ]:
            # The Worker SDK adds no reference for these usings. MSBuild projects get one from a package.
            fail("""{} uses sdk = "Microsoft.NET.Sdk.Worker", whose implicit usings need the Microsoft.Extensions \
hosting assemblies. Add framework_references = ["{}"], depend on the Microsoft.Extensions.Hosting NuGet package, or set \
implicit_usings = False.""".format(ctx.label, _ASPNETCORE_APP))
        usings_content = "// <auto-generated/>\n" + "\n".join(["global using global::" + ns + ";" for ns in namespaces]) + "\n"
        ctx.actions.write(
            output = global_usings_file,
            content = usings_content,
        )
        synthesized_srcs.append(global_usings_file)

    # Synthesized AssemblyInfo. Like MSBuild, the TargetFramework attribute is always there, since vstest
    # reads it to pick the testhost and takes an assembly without it for netcoreapp1.0, which runs as x64 on Apple silicon.
    info_lines = [
        "// <auto-generated/>",
        "[assembly: global::System.Runtime.Versioning.TargetFramework(\".NETCoreApp,Version=v%s\", FrameworkDisplayName = \".NET %s\")]" % (framework_version, framework_version),
    ]
    generate_assembly_info = getattr(ctx.attr, "generate_assembly_info", True)
    internals_visible_to = getattr(ctx.attr, "internals_visible_to", [])
    if generate_assembly_info or internals_visible_to:
        info_lines += [
            "[assembly: global::System.Reflection.AssemblyTitle(\"%s\")]" % assembly,
            "[assembly: global::System.Reflection.AssemblyProduct(\"%s\")]" % assembly,
            "[assembly: global::System.Reflection.AssemblyVersion(\"1.0.0.0\")]",
            "[assembly: global::System.Reflection.AssemblyFileVersion(\"1.0.0.0\")]",
        ]
    public_info_lines = list(info_lines)
    for friend in internals_visible_to:
        info_lines.append("[assembly: global::System.Runtime.CompilerServices.InternalsVisibleTo(\"%s\")]" % friend)
    assembly_info_file = ctx.actions.declare_file(ctx.label.name + ".AssemblyInfo.g.cs")
    ctx.actions.write(
        output = assembly_info_file,
        content = "\n".join(info_lines) + "\n",
    )

    # Resources
    resource_files = []
    if hasattr(ctx.attr, "resources"):
        if type(ctx.attr.resources) == "dict":
            for res_target, logical_name in ctx.attr.resources.items():
                for f in res_target.files.to_list():
                    resource_files.append(f)
                    # A .resx compiles to .resources, which ResourceManager("<assembly>.<name>") looks up.
                    default_name = f.basename[:-len(".resx")] + ".resources" if f.extension == "resx" else f.basename
                    log_name = logical_name if logical_name else (assembly + "." + default_name)
                    args.append("-resource:" + f.path.replace("\\", "/") + "," + log_name)
        else:
            for f in ctx.files.resources:
                resource_files.append(f)
                args.append("-resource:" + f.path.replace("\\", "/"))

    # Sources
    shared_srcs = ctx.files.srcs + synthesized_srcs + extra_srcs
    for s in shared_srcs:
        args.append(s.path.replace("\\", "/"))

    # Inputs strictly limited to srcs, resources, toolchain ref_pack, analyzers, and transitive_compile_refs
    direct_inputs = [toolchain.csc_dll] + shared_srcs + resource_files + editorconfig_files + internal_refs.values()
    worker_depsets = []
    if toolchain.csc_worker:
        direct_inputs.append(toolchain.csc_worker)
        if hasattr(toolchain, "csc_worker_files") and toolchain.csc_worker_files:
            worker_depsets.append(toolchain.csc_worker_files)

    transitive_inputs = [toolchain.ref_pack, analyzers_depset] + transitive_compile_depsets + aspnet_depsets + worker_depsets

    compile_args = ctx.actions.args()
    compile_args.use_param_file("@%s", use_always = True)
    compile_args.set_param_file_format("multiline")
    compile_args.add("-out:" + out_dll.path.replace("\\", "/"))
    compile_args.add("-refout:" + refout_dll.path.replace("\\", "/"))
    compile_args.add("-pdb:" + pdb.path.replace("\\", "/"))
    if xml_doc:
        compile_args.add("-doc:" + xml_doc.path.replace("\\", "/"))
    compile_args.add_all(args)
    compile_args.add(assembly_info_file.path.replace("\\", "/"))

    if toolchain.csc_worker:
        compiler_executable = toolchain.csc_worker
        compiler_prefix = ["--persistent_worker"]
        execution_requirements = {
            "requires-worker-protocol": "proto",
            "supports-multiplex-workers": "1",
        }
    else:
        compiler_executable = toolchain.dotnet_muxer
        compiler_prefix = [toolchain.csc_dll.path.replace("\\", "/")]
        execution_requirements = {}
    compile_env = dict(toolchain.dotnet_env) if hasattr(toolchain, "dotnet_env") and toolchain.dotnet_env else dict(SEALED_DOTNET_ENV)
    compile_env["DOTNET_ROOT"] = toolchain.dotnet_muxer.dirname
    is_win = "win" in toolchain.host_rid
    compile_env["PATH"] = "C:\\Windows\\System32;C:\\Windows" if is_win else "/usr/bin:/bin"

    ctx.actions.run(
        outputs = [out_dll, refout_dll, pdb] + ([xml_doc] if xml_doc else []),
        inputs = depset(direct = direct_inputs + [assembly_info_file], transitive = transitive_inputs),
        executable = compiler_executable,
        arguments = compiler_prefix + [compile_args],
        mnemonic = "CSharpCompile",
        progress_message = "Compiling C# %{label}",
        use_default_shell_env = False,
        execution_requirements = execution_requirements,
        env = compile_env,
    )

    # InternalsVisibleTo keeps internal members in the -refout assembly, so every dependent would recompile on an
    # internal edit. Non-friends get a public reference assembly built without it instead.
    # https://github.com/dotnet/roslyn/blob/main/docs/features/refout.md
    public_ref = refout_dll
    own_friend_refs = []
    if internals_visible_to:
        # csc names the assembly after the -out file, so the public reference assembly keeps the plain name in its
        # own directory.
        public_ref = ctx.actions.declare_file(out_dir + ctx.label.name + "_public_ref/" + assembly + ".dll")
        public_info_file = ctx.actions.declare_file(ctx.label.name + ".PublicAssemblyInfo.g.cs")
        ctx.actions.write(
            output = public_info_file,
            content = "\n".join(public_info_lines) + "\n",
        )
        public_args = ctx.actions.args()
        public_args.use_param_file("@%s", use_always = True)
        public_args.set_param_file_format("multiline")
        public_args.add("-out:" + public_ref.path.replace("\\", "/"))
        public_args.add("-refonly")
        public_args.add_all(args)

        # The compile action already reports every warning.
        public_args.add_all(["-warn:0", "-warnaserror-"])
        public_args.add(public_info_file.path.replace("\\", "/"))
        ctx.actions.run(
            outputs = [public_ref],
            inputs = depset(direct = direct_inputs + [public_info_file], transitive = transitive_inputs),
            executable = compiler_executable,
            arguments = compiler_prefix + [public_args],
            mnemonic = "CSharpPublicRef",
            progress_message = "Compiling C# public reference assembly %{label}",
            use_default_shell_env = False,
            execution_requirements = execution_requirements,
            env = compile_env,
        )
        own_friend_refs.append(struct(
            public = public_ref,
            internal = refout_dll,
            # csc matches friend names ignoring case.
            friends = tuple([f.split(",")[0].strip().lower() for f in internals_visible_to]),
        ))

    transitive_compile_refs = depset(
        direct = [public_ref],
        transitive = transitive_compile_depsets,
        order = "preorder",
    )

    transitive_runtime_dlls = depset(
        direct = [out_dll],
        transitive = [dep[CSharpInfo].transitive_runtime_dlls for dep in direct_deps_and_exports if CSharpInfo in dep],
        order = "preorder",
    )

    transitive_native_libs = depset(
        transitive = [dep[CSharpInfo].transitive_native_libs for dep in direct_deps_and_exports if CSharpInfo in dep],
        order = "preorder",
    )

    transitive_test_runtime_dlls = depset(
        # CSharpInfo from rules written against 0.4.0 lacks this field.
        transitive = [getattr(dep[CSharpInfo], "transitive_test_runtime_dlls", None) or depset() for dep in direct_deps_and_exports if CSharpInfo in dep],
    )

    csharp_info = CSharpInfo(
        target_framework = target_framework,
        compile_ref = refout_dll,
        runtime_dll = out_dll,
        pdb = pdb,
        xml_doc = xml_doc,
        transitive_compile_refs = transitive_compile_refs,
        transitive_runtime_dlls = transitive_runtime_dlls,
        transitive_native_libs = transitive_native_libs,
        transitive_test_runtime_dlls = transitive_test_runtime_dlls,
        framework_references = frameworks,
        friend_refs = depset(own_friend_refs, transitive = [friend_refs]),
    )

    default_info = DefaultInfo(
        files = depset([out_dll, refout_dll, pdb] + ([public_ref] if internals_visible_to else []) + ([xml_doc] if xml_doc else [])),
        runfiles = ctx.runfiles(
            files = [out_dll, pdb] + ([xml_doc] if xml_doc else []) + resource_files + getattr(ctx.files, "content", []),
            transitive_files = depset(transitive_runtime_dlls.to_list()),
        ).merge(library_runfiles(ctx, direct_deps_and_exports)),
    )

    providers = [csharp_info, default_info]

    if not is_analyzer:
        providers.append(coverage_common.instrumented_files_info(
            ctx,
            source_attributes = ["srcs"],
            dependency_attributes = ["deps", "exports"],
            extensions = ["cs"],
            metadata_files = [pdb],
        ))

    if is_analyzer:
        analyzer_info = CSharpAnalyzerInfo(
            analyzers = depset([out_dll]),
        )
        providers.append(analyzer_info)

    return providers

def _csharp_import_impl(ctx):
    compile_refs = list(ctx.files.compile_refs) if hasattr(ctx.files, "compile_refs") else []
    runtime_dlls = list(ctx.files.runtime_dlls) if hasattr(ctx.files, "runtime_dlls") else []
    dlls = list(ctx.files.dlls) if hasattr(ctx.files, "dlls") else []
    native_libs = list(ctx.files.native_libs) if hasattr(ctx.files, "native_libs") else []
    analyzers = list(ctx.files.analyzers) if hasattr(ctx.files, "analyzers") else []
    test_runtime_dlls = list(ctx.files.test_runtime_dlls) if hasattr(ctx.files, "test_runtime_dlls") else []

    if not compile_refs and dlls:
        compile_refs = dlls
    if not runtime_dlls and dlls:
        runtime_dlls = dlls
    if not compile_refs and runtime_dlls:
        compile_refs = runtime_dlls
    if not runtime_dlls and compile_refs:
        runtime_dlls = compile_refs

    direct_deps = list(ctx.attr.deps) + list(getattr(ctx.attr, "exports", []))

    transitive_compile_depsets = []
    if compile_refs:
        transitive_compile_depsets.append(depset(compile_refs, order = "preorder"))

    transitive_runtime_depsets = []
    if runtime_dlls:
        transitive_runtime_depsets.append(depset(runtime_dlls, order = "preorder"))

    transitive_native_depsets = []
    if native_libs:
        transitive_native_depsets.append(depset(native_libs, order = "preorder"))

    transitive_test_runtime_depsets = [depset(test_runtime_dlls)]

    analyzer_depsets = []
    if analyzers:
        analyzer_depsets.append(depset(analyzers))

    for plugin in getattr(ctx.attr, "plugins", []):
        if CSharpAnalyzerInfo in plugin:
            analyzer_depsets.append(plugin[CSharpAnalyzerInfo].analyzers)

    for dep in direct_deps:
        if CSharpInfo in dep:
            transitive_compile_depsets.append(dep[CSharpInfo].transitive_compile_refs)
            transitive_runtime_depsets.append(dep[CSharpInfo].transitive_runtime_dlls)
            transitive_native_depsets.append(dep[CSharpInfo].transitive_native_libs)
            transitive_test_runtime_depsets.append(getattr(dep[CSharpInfo], "transitive_test_runtime_dlls", None) or depset())
        if CSharpAnalyzerInfo in dep:
            analyzer_depsets.append(dep[CSharpAnalyzerInfo].analyzers)

    transitive_compile_refs = depset(transitive = transitive_compile_depsets, order = "preorder")
    transitive_runtime_dlls = depset(transitive = transitive_runtime_depsets, order = "preorder")
    transitive_native_libs = depset(transitive = transitive_native_depsets, order = "preorder")
    analyzers_depset = depset(transitive = analyzer_depsets)

    primary_compile_ref = compile_refs[0] if compile_refs else None
    primary_runtime_dll = runtime_dlls[0] if runtime_dlls else None

    csharp_info = CSharpInfo(
        target_framework = getattr(ctx.attr, "target_framework", ""),
        compile_ref = primary_compile_ref,
        runtime_dll = primary_runtime_dll,
        pdb = None,
        xml_doc = None,
        transitive_compile_refs = transitive_compile_refs,
        transitive_runtime_dlls = transitive_runtime_dlls,
        transitive_native_libs = transitive_native_libs,
        transitive_test_runtime_dlls = depset(transitive = transitive_test_runtime_depsets),
        framework_references = framework_references(ctx, direct_deps),
        friend_refs = depset(transitive = [
            getattr(dep[CSharpInfo], "friend_refs", None) or depset()
            for dep in direct_deps
            if CSharpInfo in dep
        ]),
    )

    all_files = list(compile_refs) + list(runtime_dlls) + list(native_libs) + list(analyzers)
    default_info = DefaultInfo(
        files = depset(all_files),
        runfiles = ctx.runfiles(
            files = runtime_dlls + native_libs,
            transitive_files = depset(transitive = [transitive_runtime_dlls, transitive_native_libs]),
        ).merge(library_runfiles(ctx, direct_deps)),
    )

    providers = [csharp_info, default_info]
    if analyzers or getattr(ctx.attr, "plugins", []):
        providers.append(CSharpAnalyzerInfo(analyzers = analyzers_depset))

    return providers

def _csharp_library_impl(ctx):
    if not ctx.files.srcs and (getattr(ctx.files, "compile_refs", []) or getattr(ctx.files, "runtime_dlls", []) or getattr(ctx.files, "dlls", [])):
        return _csharp_import_impl(ctx)
    return _compile_impl(ctx, is_analyzer = False)

def _csharp_analyzer_library_impl(ctx):
    if not ctx.files.srcs:
        dlls = getattr(ctx.files, "dlls", []) or getattr(ctx.files, "analyzers", [])
        return [
            CSharpAnalyzerInfo(analyzers = depset(dlls)),
            DefaultInfo(files = depset(dlls)),
        ]
    return _compile_impl(ctx, is_analyzer = True)

def _csharp_analyzer_import_impl(ctx):
    dlls = list(ctx.files.dlls) + list(ctx.files.analyzers)
    return [
        CSharpAnalyzerInfo(analyzers = depset(dlls)),
        DefaultInfo(files = depset(dlls)),
    ]

_COMMON_ATTRS = {
    "additional_compiler_options": attr.string_list(
        default = [],
        doc = ADDITIONAL_COMPILER_OPTIONS_DOC,
    ),
    "allow_unsafe_blocks": attr.bool(
        default = False,
        doc = ALLOW_UNSAFE_BLOCKS_DOC,
    ),
    "analyzers": attr.label_list(
        allow_files = [".dll"],
        default = [],
        doc = "Precompiled Roslyn analyzer DLL files.",
    ),
    "compile_refs": attr.label_list(
        allow_files = [".dll"],
        default = [],
        doc = "Precompiled reference assembly DLL files.",
    ),
    "data": attr.label_list(
        allow_files = True,
        default = [],
        doc = DATA_DOC,
    ),
    "defines": attr.string_list(
        default = [],
        doc = DEFINES_DOC,
    ),
    "deps": attr.label_list(
        default = [],
        doc = "Direct dependency libraries.",
        providers = [[CSharpInfo]],
    ),
    "dlls": attr.label_list(
        allow_files = [".dll"],
        default = [],
        doc = "Precompiled implementation assembly DLL files.",
    ),
    "editorconfig_files": attr.label_list(
        allow_files = True,
        default = [],
        doc = EDITORCONFIG_FILES_DOC,
    ),
    "exports": attr.label_list(
        default = [],
        doc = "Dependencies exported to downstream consumers.",
        providers = [[CSharpInfo]],
    ),
    "native_libs": attr.label_list(
        allow_files = True,
        default = [],
        doc = "Unmanaged target platform shared libraries.",
    ),
    "nowarn": attr.string_list(
        default = [],
        doc = "Compiler diagnostic codes to suppress, the same as MSBuild `NoWarn`. CS1701 and CS1702 are always " +
              "suppressed like in MSBuild, so a target on a newer framework than its dependencies builds quietly.",
    ),
    "content": attr.label_list(
        allow_files = True,
        default = [],
        doc = "Static content files copied to runtime directories.",
    ),
    "copy_to_output": attr.label_keyed_string_dict(
        allow_files = True,
        default = {},
        doc = "Files mapped to destination output paths.",
    ),
    "framework_references": attr.string_list(
        default = [],
        doc = FRAMEWORK_REFERENCES_DOC,
    ),
    "generate_assembly_info": attr.bool(
        default = True,
        doc = "Synthesize assembly information attributes.",
    ),
    "generate_documentation_file": attr.bool(
        default = False,
        doc = GENERATE_DOCUMENTATION_FILE_DOC,
    ),
    "implicit_usings": attr.bool(
        default = True,
        doc = "Synthesize implicit global usings namespace imports.",
    ),
    "internals_visible_to": attr.string_list(
        default = [],
        doc = INTERNALS_VISIBLE_TO_DOC,
    ),
    "langversion": attr.string(
        default = "latest",
        doc = "Target C# language version specification.",
    ),
    "output_assembly": attr.string(
        default = "",
        doc = OUTPUT_ASSEMBLY_DOC,
    ),
    "plugins": attr.label_list(
        default = [],
        doc = "Roslyn analyzer and generator plugins.",
        providers = [[CSharpAnalyzerInfo]],
    ),
    "resources": attr.label_keyed_string_dict(
        allow_files = True,
        default = {},
        doc = RESOURCES_DOC,
    ),
    "runtime_dlls": attr.label_list(
        allow_files = [".dll"],
        default = [],
        doc = "Precompiled runtime implementation assembly DLL files.",
    ),
    "warn_as_error": attr.bool(
        default = False,
        doc = "Treat compiler warnings as errors, the same as MSBuild `TreatWarningsAsErrors`. Warnings that " +
              "`nowarn` suppresses, and CS1701 and CS1702, never fail the build.",
    ),
    "warning_level": attr.int(
        default = 4,
        doc = "Compiler diagnostic severity level.",
    ),
    "sdk": attr.string(
        default = "Microsoft.NET.Sdk",
        doc = SDK_DOC,
        values = [
            "Microsoft.NET.Sdk",
            "Microsoft.NET.Sdk.Web",
            "Microsoft.NET.Sdk.Worker",
        ],
    ),
    "srcs": attr.label_list(
        allow_files = [".cs"],
        default = [],
        doc = "C# source files to compile.",
    ),
    "target_framework": attr.string(
        default = "",
        doc = TARGET_FRAMEWORK_DOC,
        values = [""] + TARGET_FRAMEWORKS,
    ),
    "target_type": attr.string(
        default = "library",
        doc = "Compiler target type output flag.",
    ),
}

_IMPORT_ATTRS = {
    "analyzers": attr.label_list(
        allow_files = [".dll"],
        default = [],
        doc = "Precompiled Roslyn analyzer DLL files.",
    ),
    "compile_refs": attr.label_list(
        allow_files = [".dll"],
        default = [],
        doc = "Precompiled reference assembly DLL files.",
    ),
    "deps": attr.label_list(
        default = [],
        doc = "Direct dependency libraries.",
        providers = [[CSharpInfo]],
    ),
    "dlls": attr.label_list(
        allow_files = [".dll"],
        default = [],
        doc = "Precompiled implementation assembly DLL files.",
    ),
    "exports": attr.label_list(
        default = [],
        doc = "Dependencies exported to downstream consumers.",
        providers = [[CSharpInfo]],
    ),
    "native_libs": attr.label_list(
        allow_files = True,
        default = [],
        doc = "Unmanaged target platform shared libraries.",
    ),
    "plugins": attr.label_list(
        default = [],
        doc = "Roslyn analyzer and generator plugins.",
        providers = [[CSharpAnalyzerInfo]],
    ),
    "runtime_dlls": attr.label_list(
        allow_files = [".dll"],
        default = [],
        doc = "Precompiled runtime implementation assembly DLL files.",
    ),
    "test_runtime_dlls": attr.label_list(
        allow_files = [".dll"],
        default = [],
        doc = "DLL files that restore copies next to a test, such as VSTest adapters. A `csharp_test` with `target_type = \"library\"` stages them next to the test assembly.",
    ),
    "target_framework": attr.string(
        default = "",
        doc = "Target framework moniker string.",
    ),
}

compile_impl = _compile_impl

csharp_library = rule(
    doc = "Compiles C# source files into reference and implementation assemblies.",
    implementation = _csharp_library_impl,
    attrs = _COMMON_ATTRS,
    cfg = target_framework_transition,
    toolchains = ["@rules_csharp//csharp:toolchain_type"],
)

csharp_analyzer_library = rule(
    doc = "Compiles Roslyn analyzer or source generator assemblies.",
    implementation = _csharp_analyzer_library_impl,
    attrs = _COMMON_ATTRS,
    cfg = target_framework_transition,
    toolchains = ["@rules_csharp//csharp:toolchain_type"],
)

csharp_import = rule(
    doc = "Imports precompiled reference and implementation assemblies.",
    implementation = _csharp_import_impl,
    attrs = _IMPORT_ATTRS,
)

csharp_analyzer_import = rule(
    doc = "Imports precompiled Roslyn analyzer and source generator assemblies.",
    implementation = _csharp_analyzer_import_impl,
    attrs = {
        "analyzers": attr.label_list(
            allow_files = [".dll"],
            default = [],
            doc = "Precompiled Roslyn analyzer DLL files.",
        ),
        "dlls": attr.label_list(
            allow_files = [".dll"],
            default = [],
            doc = "Precompiled implementation assembly DLL files.",
        ),
    },
)

COMMON_ATTRS = _COMMON_ATTRS


