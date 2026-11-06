using System;
using System.Diagnostics;
using System.Reflection;

namespace IntegrationTests;

// -c opt builds like the MSBuild Release configuration and every other mode like Debug.
public static class CompilationModeTest
{
    public static unsafe int Main()
    {
        var debuggable = Assembly.GetEntryAssembly()!.GetCustomAttribute<DebuggableAttribute>();
        bool optimized = debuggable is null || !debuggable.IsJITOptimizerDisabled;
#if DEBUG
        bool debug = true;
#else
        bool debug = false;
#endif
#if TRACE
        bool trace = true;
#else
        bool trace = false;
#endif
        int value = 41;
        int* pointer = &value;
        *pointer += 1;
        Console.WriteLine($"optimized {optimized}, DEBUG {debug}, TRACE {trace}, unsafe {value}");
        return optimized != debug && trace && value == 42 ? 0 : 1;
    }
}
