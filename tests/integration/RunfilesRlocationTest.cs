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
Console.WriteLine("PASSED: Rlocation found the data file by canonical and module name.");
return 0;
