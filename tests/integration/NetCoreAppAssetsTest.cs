using System;
using System.Reflection;
using System.Runtime.Versioning;
using Microsoft.Build.Locator;

namespace IntegrationTests;

// Checks that a package with only netcoreappX.Y and .NET Framework folders loads its netcoreapp assembly.
public static class NetCoreAppAssetsTest
{
    public static int Main()
    {
        var built = typeof(MSBuildLocator).Assembly.GetCustomAttribute<TargetFrameworkAttribute>()?.FrameworkName;
        Console.WriteLine($"Microsoft.Build.Locator is built for {built}, registered {MSBuildLocator.IsRegistered}.");
        return built == ".NETCoreApp,Version=v2.0" ? 0 : 1;
    }
}
