using System;
using System.Diagnostics;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Text;
using System.Text.Json.Nodes;

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

        // Only the app relative path. The apphost never looks at DOTNET_ROOT or the global install,
        // so the runtime it runs on is the one that ships with the binary.
        private const byte SearchAppRelative = 1 << 1;

        public static int Main(string[] args)
        {
            string? templatePath = null;
            string? outputPath = null;
            string? dllName = null;
            string? appRelativeDotnet = null;
            string? linkTree = null;
            string? linkList = null;
            string? depsJson = null;
            var dlls = new List<string>();

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
                else if (args[i].StartsWith("--link-tree="))
                    linkTree = args[i].Substring("--link-tree=".Length);
                else if (args[i].StartsWith("--link-list="))
                    linkList = args[i].Substring("--link-list=".Length);
                else if (args[i].StartsWith("--deps-json="))
                    depsJson = args[i].Substring("--deps-json=".Length);
                else if (args[i].StartsWith("--dll="))
                    dlls.Add(args[i].Substring("--dll=".Length));
                else if (args[i].StartsWith("--dll-name="))
                    dllName = args[i].Substring("--dll-name=".Length);
                else if (args[i] == "-t" && i + 1 < args.Length)
                    templatePath = args[++i];
                else if (args[i] == "-o" && i + 1 < args.Length)
                    outputPath = args[++i];
                else if (args[i] == "-a" && i + 1 < args.Length)
                    dllName = args[++i];
            }

            if (linkTree != null)
            {
                if (string.IsNullOrEmpty(linkList))
                {
                    Console.Error.WriteLine("Usage: AppHostPatcher --link-tree=<dir> --link-list=<file of path and target lines>");
                    return 1;
                }
                return LinkTree(linkTree, linkList!);
            }

            if (depsJson != null)
            {
                if (string.IsNullOrEmpty(outputPath))
                {
                    Console.Error.WriteLine("Usage: AppHostPatcher --deps-json=<template> --output=<path> [--dll=<path>]...");
                    return 1;
                }
                AddAssemblyVersions(depsJson, outputPath!, dlls);
                return 0;
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

            if (appRelativeDotnet != null)
            {
                int searchIndex = IndexOf(data, SearchPlaceholder);
                if (searchIndex == -1)
                {
                    Console.Error.WriteLine($"App host template '{resolvedTemplate}' has no .NET search options. Use the apphost of .NET 9 or later.");
                    return 1;
                }
                byte[] pathBytes = Encoding.UTF8.GetBytes(appRelativeDotnet!);
                if (pathBytes.Length > MaxSearchBytes - 3)
                {
                    Console.Error.WriteLine($"App relative .NET path is longer than {MaxSearchBytes - 3} bytes: '{appRelativeDotnet}'");
                    return 1;
                }
                Array.Clear(data, searchIndex, SearchPlaceholder.Length);
                data[searchIndex] = SearchAppRelative;
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

        // Fills a directory with links. The list alternates a path inside the directory and the
        // file it points to. A link holds the real path of its file, because the execroot
        // paths Bazel stages inputs under are replanted by later builds. When the real path is
        // inside the action's own directory, as in the hermetic sandbox or on a remote executor,
        // nothing outside it lasts, so the file is copied. It's also copied where links aren't
        // allowed, as on Windows without developer mode.
        private static int LinkTree(string root, string listPath)
        {
            string[] lines = File.ReadAllLines(listPath);
            if (lines.Length % 2 != 0)
            {
                Console.Error.WriteLine($"'{listPath}' must hold pairs of lines");
                return 1;
            }
            Directory.CreateDirectory(root);
            for (int i = 0; i < lines.Length; i += 2)
            {
                string link = Path.Combine(root, lines[i]);
                string target = lines[i + 1];
                Directory.CreateDirectory(Path.GetDirectoryName(link)!);
                if (!File.Exists(target))
                {
                    Console.Error.WriteLine($"Link target not found: '{target}'");
                    return 1;
                }
                string real = RealPath(target);
                if (!File.Exists(real) || IsUnder(real, Directory.GetCurrentDirectory()))
                {
                    File.Copy(target, link, true);
                    continue;
                }
                try
                {
                    File.CreateSymbolicLink(link, real);
                }
                catch (Exception ex) when (ex is IOException || ex is UnauthorizedAccessException)
                {
                    File.Copy(target, link, true);
                }
            }
            return 0;
        }

        private static bool IsUnder(string path, string dir) =>
            path.StartsWith(dir.TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar, StringComparison.Ordinal);

        private static string RealPath(string path)
        {
            string current = Path.GetPathRoot(Path.GetFullPath(path))!;
            foreach (string part in Path.GetFullPath(path).Substring(current.Length).Split(Path.DirectorySeparatorChar, StringSplitOptions.RemoveEmptyEntries))
            {
                current = Path.Combine(current, part);
                FileSystemInfo info = Directory.Exists(current) ? new DirectoryInfo(current) : new FileInfo(current);
                FileSystemInfo? resolved = info.ResolveLinkTarget(true);
                if (resolved != null) current = RealPath(resolved.FullName);
            }
            return current;
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

        // The host keeps a framework assembly over an app one unless the app's deps.json entry has a higher
        // assemblyVersion, or the same one and a higher fileVersion. So record both, read from each dll.
        private static void AddAssemblyVersions(string templatePath, string outputPath, List<string> dlls)
        {
            var versions = new Dictionary<string, JsonObject>(StringComparer.OrdinalIgnoreCase);
            foreach (var dll in dlls)
            {
                Version? assemblyVersion;
                try
                {
                    assemblyVersion = AssemblyName.GetAssemblyName(dll).Version;
                }
                catch (BadImageFormatException)
                {
                    continue;
                }
                var entry = new JsonObject();
                if (assemblyVersion != null)
                    entry["assemblyVersion"] = assemblyVersion.ToString();
                string? fileVersion = FileVersionInfo.GetVersionInfo(dll).FileVersion;
                if (!string.IsNullOrEmpty(fileVersion))
                    entry["fileVersion"] = fileVersion;
                versions[Path.GetFileName(dll)] = entry;
            }

            var doc = JsonNode.Parse(File.ReadAllText(templatePath))!;
            foreach (var framework in doc["targets"]!.AsObject())
            {
                foreach (var library in framework.Value!.AsObject())
                {
                    if (library.Value?["runtime"] is not JsonObject runtime)
                        continue;
                    var names = new List<string>();
                    foreach (var pair in runtime)
                        names.Add(pair.Key);
                    foreach (var name in names)
                    {
                        if (versions.TryGetValue(name, out var entry))
                            runtime[name] = entry.DeepClone();
                    }
                }
            }
            File.WriteAllText(outputPath, doc.ToJsonString(new System.Text.Json.JsonSerializerOptions { WriteIndented = true }) + "\n");
        }
    }
}
