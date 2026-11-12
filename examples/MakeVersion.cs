using System.IO;

// A build tool: writes a C# source file with the version given on the command line.
File.WriteAllText(args[1], $"static class BuildInfo {{ public const string Version = \"{args[0]}\"; }}\n");
