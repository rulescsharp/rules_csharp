using System;
using System.IO;
using System.Text;
using RulesCsharp.Tests;

var bin = Runfiles.Find("linux_arm64_app", key => key.EndsWith("tests/integration/linux_arm64_app_linux_arm64", StringComparison.Ordinal));
Console.WriteLine($"Examining cross-compiled binary: {bin}");
var bytes = File.ReadAllBytes(bin);

// 1. ELF magic bytes 7f 45 4c 46
var magic = Convert.ToHexString(bytes.AsSpan(0, Math.Min(4, bytes.Length))).ToLowerInvariant();
Console.WriteLine($"Magic bytes: {magic}");
if (magic != "7f454c46")
{
    Console.WriteLine($"FAILED: Expected ELF magic bytes '7f454c46', got '{magic}'");
    return 1;
}

// 2. The apphost carries the patched app path
if (bytes.AsSpan().IndexOf(Encoding.UTF8.GetBytes("app.dll")) < 0)
{
    Console.WriteLine("FAILED: Patched assembly name 'app.dll' not found in binary");
    return 1;
}

Console.WriteLine("PASSED: ELF header and patched assembly name 'app.dll' found.");
return 0;
