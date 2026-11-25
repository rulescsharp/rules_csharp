using System;
using System.Reflection;
using System.Runtime.Versioning;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.Abstractions;

namespace IntegrationTests;

// Microsoft.Extensions.Logging.Abstractions ships lib/net8.0 and lib/net10.0, and its [LoggerMessage]
// generator in analyzers/dotnet/roslynX.Y/cs. This compiles only when the generator runs, and checks
// that the assembly it loads is the one restore picks for the test's target framework.
public static partial class PackageAssetsTest
{
    [LoggerMessage(Level = LogLevel.Information, Message = "Hello {Name}")]
    private static partial void SayHello(ILogger logger, string name);

    public static int Main()
    {
        SayHello(NullLogger.Instance, "world");
        var built = typeof(ILogger).Assembly.GetCustomAttribute<TargetFrameworkAttribute>()?.FrameworkName;
        var expected = Environment.GetEnvironmentVariable("EXPECTED_FRAMEWORK");
        Console.WriteLine($"Microsoft.Extensions.Logging.Abstractions is built for {built}, expected {expected}.");
        return built == expected ? 0 : 1;
    }
}
