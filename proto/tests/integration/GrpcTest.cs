using System;

namespace RulesCsharp.IntegrationTests;

public static class GrpcTest
{
    public static int Main()
    {
        var req = new Integration.EchoRequest { Message = "Hello, gRPC!" };
        if (req.Message != "Hello, gRPC!")
        {
            Console.Error.WriteLine($"Assertion failed: {req.Message}");
            return 1;
        }
        Console.WriteLine($"EchoRequest message: {req.Message}");
        return 0;
    }
}
