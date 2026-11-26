using System;
using System.Runtime.InteropServices;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Text.RegularExpressions;

namespace IntegrationTests;

public sealed record Point(int X, int Y);

[JsonSerializable(typeof(Point))]
internal partial class PointContext : JsonSerializerContext
{
}

// Uses the source generators that ship with the targeting pack, with no package or plugin.
public static partial class FrameworkGeneratorsTest
{
    [GeneratedRegex("^a+$")]
    private static partial Regex As();

    [LibraryImport("libc", EntryPoint = "getpid")]
    private static partial int GetPid();

    [LibraryImport("kernel32", EntryPoint = "GetCurrentProcessId")]
    private static partial uint GetCurrentProcessId();

    public static int Main()
    {
        if (!As().IsMatch("aaa") || As().IsMatch("ab"))
        {
            Console.Error.WriteLine("Generated regex did not match as expected");
            return 1;
        }

        var pid = OperatingSystem.IsWindows() ? (int)GetCurrentProcessId() : GetPid();
        if (pid != Environment.ProcessId)
        {
            Console.Error.WriteLine($"Expected pid {Environment.ProcessId}, got {pid}");
            return 1;
        }

        var json = JsonSerializer.Serialize(new Point(1, 2), PointContext.Default.Point);
        if (json != "{\"X\":1,\"Y\":2}")
        {
            Console.Error.WriteLine($"Unexpected JSON {json}");
            return 1;
        }

        Console.WriteLine($"regex, pid {pid} and {json} all came from generated code");
        return 0;
    }
}
