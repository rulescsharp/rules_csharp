using System;

namespace IntegrationTests;

// Loads Microsoft.AspNetCore.Http.Abstractions through a Web library. The test itself uses the plain SDK.
public static class FrameworkReferenceTest
{
    public static int Main()
    {
        var route = WebLib.Route("bazel");
        if (route != "/greet/bazel")
        {
            Console.Error.WriteLine($"Expected /greet/bazel, got {route}");
            return 1;
        }
        Console.WriteLine($"Routed to {route}");
        return 0;
    }
}
