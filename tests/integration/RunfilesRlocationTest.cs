using System;
using System.IO;
using RulesCsharp.Runfiles;

var runfiles = Runfiles.Create();
// The second path names the main repository by its module name, which only resolves
// through the repo mapping.
foreach (var rlocation in new[]
{
    "_main/tests/integration/runfiles_payload.txt",
    "rules_csharp/tests/integration/runfiles_payload.txt",
})
{
    var path = runfiles.Rlocation(rlocation);
    if (path == null || !File.Exists(path))
    {
        Console.WriteLine($"FAILED: Rlocation returned nothing for {rlocation}");
        return 1;
    }
    var text = File.ReadAllText(path).Trim();
    if (text != "runfiles-ok")
    {
        Console.WriteLine($"FAILED: unexpected payload for {rlocation}: {text}");
        return 1;
    }
}

// Bazel escapes manifest lines whose paths hold a space, newline or backslash: the line starts
// with a space, the link escapes those as \s \n \b and the target escapes \n \b.
var manifest = Path.Combine(Environment.GetEnvironmentVariable("TEST_TMPDIR") ?? Path.GetTempPath(), "escaped_manifest");
File.WriteAllLines(manifest, new[]
{
    @"_main/plain.txt /data/plain.txt",
    @" _main/a\sb.txt /data/a b.txt",
    @" _main/new\nline.txt /data/new\nline.txt",
    @" _main/c\sd.txt C:\bdata\bs\bn\bc d.txt",
});
// The manifest lists files only, so a directory resolves through the runfiles tree.
var tree = Path.Combine(Path.GetDirectoryName(manifest)!, "tree");
Directory.CreateDirectory(Path.Combine(tree, "_main", "assets"));
Environment.SetEnvironmentVariable("RUNFILES_MANIFEST_FILE", manifest);
Environment.SetEnvironmentVariable("RUNFILES_DIR", tree);
var escaped = Runfiles.Create();
var assets = escaped.Rlocation("_main/assets");
if (assets != Path.Combine(tree, "_main", "assets"))
{
    Console.WriteLine($"FAILED: Rlocation(_main/assets) returned {assets ?? "null"}, expected the directory in the runfiles tree");
    return 1;
}
foreach (var (rlocation, expected) in new[]
{
    ("_main/plain.txt", "/data/plain.txt"),
    ("_main/a b.txt", "/data/a b.txt"),
    ("_main/new\nline.txt", "/data/new\nline.txt"),
    ("_main/c d.txt", @"C:\data\s\n\c d.txt"),
})
{
    var path = escaped.Rlocation(rlocation);
    if (path != expected)
    {
        Console.WriteLine($"FAILED: Rlocation({rlocation}) from an escaped manifest returned {path ?? "null"}, expected {expected}");
        return 1;
    }
}

// Apparent repo names map the way the source repository sees them, and a source ending in *
// covers every repository with that prefix.
var mapping = Path.Combine(Path.GetDirectoryName(manifest)!, "repo_mapping");
File.WriteAllLines(mapping, new[]
{
    ",mydata,main_data+",
    "lib+,mydata,data+",
    "+ext+*,tool,+ext+tool",
});
File.WriteAllLines(manifest, new[]
{
    $"_repo_mapping {mapping}",
    "main_data+/d.txt /data/main.txt",
    "data+/d.txt /data/lib.txt",
    "+ext+tool/t.txt /data/tool.txt",
});
var mapped = Runfiles.Create();
foreach (var (rlocation, source, expected) in new (string, string, string?)[]
{
    ("mydata/d.txt", "", "/data/main.txt"),
    ("mydata/d.txt", "lib+", "/data/lib.txt"),
    ("tool/t.txt", "+ext+gen", "/data/tool.txt"),
    ("tool/t.txt", "", null),
})
{
    var path = mapped.Rlocation(rlocation, source);
    if (path != expected)
    {
        Console.WriteLine($"FAILED: Rlocation({rlocation}) from repository '{source}' returned {path ?? "null"}, expected {expected ?? "null"}");
        return 1;
    }
}
// This assembly is built in the main repository, so it maps like the main repository.
if (mapped.Rlocation("mydata/d.txt", typeof(Runfiles).Assembly) != "/data/main.txt")
{
    Console.WriteLine("FAILED: Rlocation with an assembly from the main repository did not use the main repository mapping");
    return 1;
}

Console.WriteLine("PASSED: Rlocation found the data file by canonical and module name and read escaped manifest lines and directories.");
return 0;
