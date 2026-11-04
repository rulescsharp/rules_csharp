using System;
using System.Reflection;

namespace IntegrationTests;

// The app and its library load under the names set with output_assembly.
public static class OutputAssemblyTest
{
    public static int Main()
    {
        var app = Assembly.GetEntryAssembly()!.GetName().Name;
        var lib = typeof(Lib).Assembly.GetName().Name;
        Console.WriteLine($"App assembly {app}, library assembly {lib}, message {Lib.GetMessage()}");
        return app == "Contoso.Renamed.Tests" && lib == "Contoso.Renamed" ? 0 : 1;
    }
}
