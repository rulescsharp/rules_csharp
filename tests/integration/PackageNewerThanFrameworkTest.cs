extern alias SCI;

using System;
using System.Collections.Immutable;
using System.IO;
using System.Text.Json;

namespace IntegrationTests;

// System.Collections.Immutable 11.0.0 is newer than the copy in the net10.0 shared framework, and
// System.Text.Json 10.0.0 is not. Like dotnet build, only the newer package replaces the framework copy.
public static class PackageNewerThanFrameworkTest
{
    public static int Main()
    {
        var items = ImmutableArray.Create(1, 2, 3);
        var aliased = SCI::System.Collections.Immutable.ImmutableArray.Create(1, 2);
        var immutable = typeof(ImmutableArray).Assembly.GetName().Version;
        var json = typeof(JsonSerializer).Assembly.Location;
        var fromFramework = Path.GetDirectoryName(json)!.Contains(Path.Combine("shared", "Microsoft.NETCore.App"));
        Console.WriteLine($"System.Collections.Immutable {immutable} has {items.Length} items. System.Text.Json loads from {json}.");
        return immutable?.Major == 11 && items.Length == 3 && aliased.Length == 2 && fromFramework ? 0 : 1;
    }
}
