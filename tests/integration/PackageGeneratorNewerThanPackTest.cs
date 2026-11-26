using System;
using System.CodeDom.Compiler;
using System.Reflection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.Abstractions;

namespace IntegrationTests;

// Microsoft.Extensions.Logging.Abstractions 10.0.0 ships a newer logging generator than the net8.0 ASP.NET Core
// targeting pack, so the package copy runs. Only that newer generator takes the logger from a primary constructor.
public static partial class PackageGeneratorNewerThanPackTest
{
    [LoggerMessage(Level = LogLevel.Information, Message = "Hello {Name}")]
    private static partial void Hello(ILogger logger, string name);

    public static int Main()
    {
        var generated = typeof(PackageGeneratorNewerThanPackTest)
            .GetMethod(nameof(Hello), BindingFlags.NonPublic | BindingFlags.Static)
            ?.GetCustomAttribute<GeneratedCodeAttribute>();
        if (generated?.Version is not string version || !version.StartsWith("10."))
        {
            Console.Error.WriteLine($"Expected the logging generator from the 10.0.0 package, got {generated?.Tool} {generated?.Version}");
            return 1;
        }

        new PrimaryConstructorLog(NullLogger.Instance).Hello("primary constructor");
        Console.WriteLine($"{generated.Tool} {version} generated Hello");
        return 0;
    }
}

public partial class PrimaryConstructorLog(ILogger logger)
{
    [LoggerMessage(Level = LogLevel.Information, Message = "Hello {Name}")]
    public partial void Hello(string name);
}
