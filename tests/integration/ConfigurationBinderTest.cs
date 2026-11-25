using System;
using System.Collections.Generic;
using Microsoft.Extensions.Configuration;

namespace IntegrationTests;

// Microsoft.Extensions.Configuration.Binder ships an opt-in source generator that its targets remove unless
// EnableConfigurationBindingGenerator is true. Passed anyway, its Get<T>() interceptor fails to compile with CS9137.
public static class ConfigurationBinderTest
{
    public sealed class Settings
    {
        public int Port { get; set; }
    }

    public static int Main()
    {
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?> { ["Port"] = "8080" })
            .Build();
        var port = config.Get<Settings>()?.Port;
        Console.WriteLine($"port={port}");
        return port == 8080 ? 0 : 1;
    }
}
