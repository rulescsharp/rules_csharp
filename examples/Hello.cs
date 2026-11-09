using RulesCsharp.Examples;

Console.WriteLine(Greeter.Greet("Bazel"));
#if DEBUG
Console.WriteLine("Debug build. Build with -c opt for Release.");
#elif RELEASE
Console.WriteLine("Release build.");
#endif
#if NET8_0_OR_GREATER
Console.WriteLine("Built for .NET 8 or newer.");
#endif
