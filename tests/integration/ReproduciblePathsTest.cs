using System;
using System.IO;
using System.Text;
using RulesCsharp.Tests;

// Absolute build paths in a dll or pdb make outputs differ per machine, output base and sandbox.
byte[] Read(string file) =>
    File.ReadAllBytes(Runfiles.Find(file, key => key.EndsWith("tests/integration/" + file, StringComparison.Ordinal)));

bool Contains(byte[] haystack, string needle) =>
    haystack.AsSpan().IndexOf(Encoding.ASCII.GetBytes(needle)) >= 0
    || haystack.AsSpan().IndexOf(Encoding.Unicode.GetBytes(needle)) >= 0;

var dll = Read("lib.dll");
foreach (var (name, bytes) in new[] { ("lib.dll", dll), ("lib.pdb", Read("lib.pdb")) })
{
    foreach (var marker in new[] { "execroot", "sandbox" })
    {
        if (Contains(bytes, marker))
        {
            Console.WriteLine($"FAILED: {name} embeds an absolute build path containing '{marker}'.");
            return 1;
        }
    }
}

if (!Contains(dll, "/_/"))
{
    Console.WriteLine("FAILED: lib.dll has no /_/ mapped pdb path.");
    return 1;
}

Console.WriteLine("PASSED: lib.dll and lib.pdb carry only mapped paths.");
return 0;
