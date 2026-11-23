// The dotnet new worker template (SDK 10) with host.Run() replaced by running until the worker logs once.
using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

var logged = new TaskCompletionSource<string>(TaskCreationOptions.RunContinuationsAsynchronously);

var builder = Host.CreateApplicationBuilder(args);
builder.Services.AddHostedService<Worker>();
builder.Logging.AddProvider(new FirstMessageProvider(logged));

var host = builder.Build();
await host.StartAsync();
var message = await logged.Task.WaitAsync(TimeSpan.FromSeconds(30));
await host.StopAsync();
Console.WriteLine(message);
if (!message.StartsWith("Worker running at: "))
{
    Console.Error.WriteLine("unexpected log message: " + message);
    return 1;
}
return 0;

public class Worker(ILogger<Worker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            if (logger.IsEnabled(LogLevel.Information))
            {
                logger.LogInformation("Worker running at: {time}", DateTimeOffset.Now);
            }
            await Task.Delay(1000, stoppingToken);
        }
    }
}

// Hands the first message the Worker logs to the program.
sealed class FirstMessageProvider(TaskCompletionSource<string> logged) : ILoggerProvider, ILogger
{
    public ILogger CreateLogger(string categoryName) => categoryName == typeof(Worker).FullName ? this : Microsoft.Extensions.Logging.Abstractions.NullLogger.Instance;

    public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;

    public bool IsEnabled(LogLevel logLevel) => true;

    public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter) =>
        logged.TrySetResult(formatter(state, exception));

    public void Dispose()
    {
    }
}
