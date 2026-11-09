using System;
using System.Diagnostics;
using System.IO;
using System.Text;

namespace RulesCsharp.Tools
{
    public static class AppHostPatcher
    {
        private static readonly byte[] Placeholder = Encoding.ASCII.GetBytes(
            "c3ab8ff13720e8ad9047dd39466b3c8974e592c2fa383d4a3960714caef0c4f2"
        );

        // .NET 9 and later apphosts also carry the .NET search options, laid out as
        // <search_location> 0 <app_relative_dotnet_root> 0 in a 512 byte array. See HostWriter.cs in
        // https://github.com/dotnet/runtime/tree/main/src/installer/managed/Microsoft.NET.HostModel/AppHost
        private static readonly byte[] SearchPlaceholder = Encoding.ASCII.GetBytes(
            "\0\019ff3e9c3602ae8e841925bb461a0adb064a1f1903667a5e0d87e8f608f425ac"
        );
        private const int MaxSearchBytes = 512;

        // App relative first, then DOTNET_ROOT, then the global install.
        private const byte SearchAppRelativeThenEnvThenGlobal = (1 << 1) | (1 << 2) | (1 << 3);

        public static int Main(string[] args)
        {
            string? templatePath = null;
            string? outputPath = null;
            string? dllName = null;
            string? appRelativeDotnet = null;

            for (int i = 0; i < args.Length; i++)
            {
                if (args[i].StartsWith("--apphost-template="))
                    templatePath = args[i].Substring("--apphost-template=".Length);
                else if (args[i].StartsWith("--template="))
                    templatePath = args[i].Substring("--template=".Length);
                else if (args[i].StartsWith("--output="))
                    outputPath = args[i].Substring("--output=".Length);
                else if (args[i].StartsWith("--assembly-name="))
                    dllName = args[i].Substring("--assembly-name=".Length);
                else if (args[i].StartsWith("--app-relative-dotnet="))
                    appRelativeDotnet = args[i].Substring("--app-relative-dotnet=".Length);
                else if (args[i].StartsWith("--dll-name="))
                    dllName = args[i].Substring("--dll-name=".Length);
                else if (args[i] == "-t" && i + 1 < args.Length)
                    templatePath = args[++i];
                else if (args[i] == "-o" && i + 1 < args.Length)
                    outputPath = args[++i];
                else if (args[i] == "-a" && i + 1 < args.Length)
                    dllName = args[++i];
            }

            if (string.IsNullOrEmpty(templatePath) || string.IsNullOrEmpty(outputPath) || string.IsNullOrEmpty(dllName))
            {
                Console.Error.WriteLine("Usage: AppHostPatcher --apphost-template=<path> --output=<path> --assembly-name=<name>");
                return 1;
            }

            string resolvedTemplate = ResolveRunfile(templatePath);
            if (!File.Exists(resolvedTemplate))
            {
                Console.Error.WriteLine($"AppHost template not found at '{templatePath}' (resolved: '{resolvedTemplate}')");
                return 1;
            }

            byte[] data = File.ReadAllBytes(resolvedTemplate);
            int index = IndexOf(data, Placeholder);
            if (index == -1)
            {
                Console.Error.WriteLine($"Placeholder not found in '{resolvedTemplate}'");
                return 1;
            }

            byte[] dllBytes = Encoding.UTF8.GetBytes(dllName);
            Array.Clear(data, index, Placeholder.Length);
            Array.Copy(dllBytes, 0, data, index, dllBytes.Length);
            data[index + dllBytes.Length] = 0; // null terminator

            // Older apphosts have no search options and keep finding .NET through DOTNET_ROOT.
            int searchIndex = appRelativeDotnet == null ? -1 : IndexOf(data, SearchPlaceholder);
            if (searchIndex != -1)
            {
                byte[] pathBytes = Encoding.UTF8.GetBytes(appRelativeDotnet!);
                if (pathBytes.Length > MaxSearchBytes - 3)
                {
                    Console.Error.WriteLine($"App relative .NET path is longer than {MaxSearchBytes - 3} bytes: '{appRelativeDotnet}'");
                    return 1;
                }
                Array.Clear(data, searchIndex, SearchPlaceholder.Length);
                data[searchIndex] = SearchAppRelativeThenEnvThenGlobal;
                data[searchIndex + 1] = 0;
                Array.Copy(pathBytes, 0, data, searchIndex + 2, pathBytes.Length);
                data[searchIndex + 2 + pathBytes.Length] = 0;
            }

            string? dir = Path.GetDirectoryName(outputPath);
            if (!string.IsNullOrEmpty(dir))
            {
                Directory.CreateDirectory(dir);
            }

            File.WriteAllBytes(outputPath, data);

            if (!OperatingSystem.IsWindows())
            {
                try
                {
                    File.SetUnixFileMode(
                        outputPath,
                        UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute |
                        UnixFileMode.GroupRead | UnixFileMode.GroupExecute |
                        UnixFileMode.OtherRead | UnixFileMode.OtherExecute
                    );
                }
                catch (Exception ex)
                {
                    Console.Error.WriteLine($"Warning: Failed to set unix file mode: {ex.Message}");
                }

                if (OperatingSystem.IsMacOS())
                {
                    try
                    {
                        var psi = new ProcessStartInfo("codesign", $"-s - -f \"{outputPath}\"")
                        {
                            RedirectStandardOutput = true,
                            RedirectStandardError = true,
                            UseShellExecute = false,
                        };
                        using var proc = Process.Start(psi);
                        proc?.WaitForExit();
                    }
                    catch
                    {
                        // Ignore if codesign is unavailable in foreign or cross environments
                    }
                }
            }

            return 0;
        }

        private static string ResolveRunfile(string path)
        {
            if (File.Exists(path)) return path;

            string? runfilesDir = Environment.GetEnvironmentVariable("RUNFILES_DIR");
            if (!string.IsNullOrEmpty(runfilesDir))
            {
                string combined = Path.Combine(runfilesDir, path.Replace('\\', '/').TrimStart('/'));
                if (File.Exists(combined)) return combined;
            }

            string? manifest = Environment.GetEnvironmentVariable("RUNFILES_MANIFEST_FILE");
            if (!string.IsNullOrEmpty(manifest) && File.Exists(manifest))
            {
                string normPath = path.Replace('\\', '/').TrimStart('.', '/');
                foreach (var line in File.ReadLines(manifest))
                {
                    int spaceIdx = line.IndexOf(' ');
                    if (spaceIdx > 0)
                    {
                        string rpath = line.Substring(0, spaceIdx);
                        if (rpath == normPath || rpath.EndsWith("/" + normPath) || normPath.EndsWith("/" + rpath))
                        {
                            string target = line.Substring(spaceIdx + 1).Trim();
                            if (File.Exists(target)) return target;
                        }
                    }
                }
            }

            return path;
        }

        private static int IndexOf(byte[] source, byte[] pattern)
        {
            if (pattern.Length == 0 || source.Length < pattern.Length) return -1;
            for (int i = 0; i <= source.Length - pattern.Length; i++)
            {
                bool match = true;
                for (int j = 0; j < pattern.Length; j++)
                {
                    if (source[i + j] != pattern[j])
                    {
                        match = false;
                        break;
                    }
                }
                if (match) return i;
            }
            return -1;
        }
    }
}
