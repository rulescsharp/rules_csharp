using System;
using System.IO;
using RulesCsharp.Tests;

// generate_documentation_file writes the /// comments next to the dll.
var xml = File.ReadAllText(Runfiles.Find("doc_lib.xml", key => key.EndsWith("tests/integration/doc_lib.xml", StringComparison.Ordinal)));
foreach (var expected in new[] { "M:IntegrationTests.DocLib.Answer", "Returns the answer to everything." })
{
    if (!xml.Contains(expected, StringComparison.Ordinal))
    {
        Console.Error.WriteLine($"doc_lib.xml has no {expected}:\n{xml}");
        return 1;
    }
}
return 0;
