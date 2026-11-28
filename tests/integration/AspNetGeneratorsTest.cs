using System;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace IntegrationTests;

// Uses the source generators that ship with the ASP.NET Core targeting pack.
public static partial class AspNetGeneratorsTest
{
    [LoggerMessage(Level = LogLevel.Information, Message = "Hello {Name}")]
    private static partial void Hello(ILogger logger, string name);

    private sealed class LastMessageLogger : ILogger
    {
        public string? Last { get; private set; }

        public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;

        public bool IsEnabled(LogLevel logLevel) => true;

        public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter)
        {
            Last = formatter(state, exception);
        }
    }

    public static int Main()
    {
        var logger = new LastMessageLogger();
        Hello(logger, "bazel");
        if (logger.Last != "Hello bazel")
        {
            Console.Error.WriteLine($"Expected Hello bazel, got {logger.Last}");
            return 1;
        }

        var services = new ServiceCollection();
#if NET10_0_OR_GREATER
        // The validations generator intercepts this call.
        services.AddValidation();
#endif
        Console.WriteLine($"Logged {logger.Last} with {services.Count} services");
        return 0;
    }
}
