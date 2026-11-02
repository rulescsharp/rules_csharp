using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using RulesCsharp.Tests;

// DOCS_REFERENCE is the checked-in doc and DOCS_GENERATED the Stardoc output, both as paths in the
// main repository.
var workspace = Environment.GetEnvironmentVariable("TEST_WORKSPACE") ?? "_main";
string Doc(string variable)
{
    var path = Environment.GetEnvironmentVariable(variable)
        ?? throw new InvalidOperationException($"{variable} is not set.");
    return Runfiles.Find(path, key => key == workspace + "/" + path);
}

var reference = Doc("DOCS_REFERENCE");
var generated = Doc("DOCS_GENERATED");
Console.WriteLine($"Reference docs: {reference}");
Console.WriteLine($"Generated Stardoc docs: {generated}");

// Git may check text out with CRLF on Windows. Stardoc writes LF.
string[] Lines(string path) => File.ReadAllText(path).Replace("\r\n", "\n").Split('\n');

var referenceLines = Lines(reference);
var generatedLines = Lines(generated);
var firstDiff = Enumerable.Range(0, Math.Max(referenceLines.Length, generatedLines.Length))
    .FirstOrDefault(i => i >= referenceLines.Length || i >= generatedLines.Length || referenceLines[i] != generatedLines[i], -1);
if (firstDiff >= 0)
{
    Console.WriteLine($"FAILED: {Environment.GetEnvironmentVariable("DOCS_REFERENCE")} differs from the Stardoc output at line {firstDiff + 1}:");
    Console.WriteLine($"- {(firstDiff < referenceLines.Length ? referenceLines[firstDiff] : "<end of file>")}");
    Console.WriteLine($"+ {(firstDiff < generatedLines.Length ? generatedLines[firstDiff] : "<end of file>")}");
    return 1;
}
Console.WriteLine("Documentation parity check passed: 0 diff between the checked-in docs and Stardoc output.");

var forbidden = new (Regex Pattern, string Category)[]
{
    (new Regex(@"\b(you|your|You|Your)\b"), "second-person pronoun"),
    (new Regex(@"(This rule allows|In order to|It is important to note)", RegexOptions.IgnoreCase), "conversational preamble"),
    (new Regex(@"\b(seamlessly|easily|powerful|modern|robust|effortlessly)\b", RegexOptions.IgnoreCase), "qualitative filler"),
    (new Regex(@"\b(furthermore|additionally|moreover)\b", RegexOptions.IgnoreCase), "transitional filler"),
    (new Regex("\u2014"), "em-dash"),
};

var scanned = new List<string> { reference };
scanned.AddRange(Runfiles.All
    .Where(e => e.Key.StartsWith(workspace + "/csharp/", StringComparison.Ordinal) && e.Key.EndsWith(".bzl", StringComparison.Ordinal))
    .Select(e => e.Value));

var violations = new List<string>();
foreach (var path in scanned.Distinct().OrderBy(p => p, StringComparer.Ordinal))
{
    var lines = Lines(path);
    for (var i = 0; i < lines.Length; i++)
    {
        foreach (var (pattern, category) in forbidden)
        {
            var match = pattern.Match(lines[i]);
            if (match.Success)
            {
                violations.Add($"  {path}:{i + 1}: [{category}] '{match.Value}' in: {lines[i].Trim()}");
            }
        }
    }
}

if (violations.Count > 0)
{
    Console.WriteLine($"FAILED: Found {violations.Count} anti-slop violations:");
    violations.ForEach(Console.WriteLine);
    return 1;
}

Console.WriteLine($"Anti-slop compliance verified: zero forbidden tokens or em-dashes found across {scanned.Distinct().Count()} files.");
return 0;
