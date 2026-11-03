using System;
using System.Threading;
using System.Threading.Tasks;

namespace IntegrationTests;

// Builds against the Worker SDK's implicit usings and runs one background service to completion.
public sealed class Tick : BackgroundService
{
    public static int Count;

    protected override Task ExecuteAsync(CancellationToken stoppingToken)
    {
        Interlocked.Increment(ref Count);
        return Task.CompletedTask;
    }
}

public static class WorkerTest
{
    public static async Task<int> Main()
    {
        var builder = Host.CreateApplicationBuilder();
        builder.Services.AddHostedService<Tick>();
        builder.Logging.ClearProviders();
        using var host = builder.Build();
        await host.StartAsync();
        await host.StopAsync();
        if (Tick.Count != 1)
        {
            Console.Error.WriteLine($"Expected the background service to run once, ran {Tick.Count} times");
            return 1;
        }
        Console.WriteLine("Worker ran its background service.");
        return 0;
    }
}
