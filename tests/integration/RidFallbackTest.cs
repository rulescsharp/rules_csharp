using System;
using System.IO.Ports;

namespace IntegrationTests;

// System.IO.Ports ships its real code in runtimes/unix/lib and runtimes/win/lib. Its lib/ copy is a
// stub that throws PlatformNotSupportedException from every member, so this only passes when the
// package's runtime files come from the RID fallback chain.
public static class RidFallbackTest
{
    public static int Main()
    {
        string[] ports;
        try
        {
            ports = SerialPort.GetPortNames();
        }
        catch (PlatformNotSupportedException e)
        {
            Console.WriteLine($"Loaded the lib/ stub of System.IO.Ports: {e.Message}");
            return 1;
        }
        var serialStream = typeof(SerialPort).Assembly.GetType("System.IO.Ports.SerialStream");
        Console.WriteLine($"GetPortNames found {ports.Length} ports. SerialStream is {(serialStream == null ? "missing" : "present")}.");
        return serialStream == null ? 1 : 0;
    }
}
