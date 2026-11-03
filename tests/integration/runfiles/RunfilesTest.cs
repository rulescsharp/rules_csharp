using System;
using System.IO;
using System.Linq;
using IntegrationTests.RunfilesLib;
using RulesCsharp.Tests;

var workspace = Environment.GetEnvironmentVariable("TEST_WORKSPACE") ?? "_main";
var expected = new[]
{
    "tests/integration/runfiles/greeting.txt",
    "tests/integration/runfiles/tool.sh",
    "tests/integration/runfiles/tool_helper.txt",
    "tests/integration/runfiles/lib/libdata.txt",
    "tests/integration/runfiles/lib/libextra.txt",
    "tests/integration/runfiles/lib/base.txt",
};
var missing = expected.Where(path => !Runfiles.All.ContainsKey(workspace + "/" + path)).ToList();
foreach (var path in missing)
{
    Console.Error.WriteLine($"Missing from runfiles: {path}");
}

var greetingPath = Environment.GetEnvironmentVariable("GREETING") ?? "";
var greeting = File.ReadAllText(Runfiles.Find(greetingPath, key => key == greetingPath)).Trim();
Console.WriteLine($"{greetingPath}: {greeting}");
if (greeting != "Hello from greeting.txt")
{
    Console.Error.WriteLine($"Expected GREETING to name greeting.txt, got {greetingPath}");
    return 1;
}

Console.WriteLine($"{Lib.Name} found {expected.Length - missing.Count} of {expected.Length} runfiles.");
return missing.Count == 0 ? 0 : 1;
