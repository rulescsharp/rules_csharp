using RulesCsharp.Examples;

Console.WriteLine(Greeter.Greet("Bazel"));
#if DEBUG
Console.WriteLine("Debug build. Build with -c opt for Release.");
#endif
