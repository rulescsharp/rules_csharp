using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace RulesCsharp.Tools
{
    public static class CsprojSync
    {
        public static int Main(string[] args)
        {
            string? workspace = null;
            bool checkMode = false;
            bool roundTrip = false;
            bool bootstrapLock = false;

            foreach (var arg in args)
            {
                if (arg.StartsWith("--workspace="))
                    workspace = arg.Substring("--workspace=".Length);
                else if (arg == "--check")
                    checkMode = true;
                else if (arg == "--round-trip")
                    roundTrip = true;
                else if (arg == "--bootstrap-lock")
                    bootstrapLock = true;
            }

            if (string.IsNullOrEmpty(workspace))
            {
                workspace = Environment.GetEnvironmentVariable("BUILD_WORKSPACE_DIRECTORY");
            }
            if (string.IsNullOrEmpty(workspace))
            {
                workspace = Directory.GetCurrentDirectory();
            }

            workspace = Path.GetFullPath(workspace);
            Console.WriteLine($"CsprojSync running in workspace: {workspace}");

            if (bootstrapLock && BootstrapLock(workspace) != 0)
            {
                return 1;
            }

            var csDirs = FindCsDirectories(workspace);
            Console.WriteLine($"Found {csDirs.Count} directories containing C# files.");

            int errorCount = 0;

            foreach (var dir in csDirs)
            {
                string dirName = Path.GetFileName(dir);
                if (string.IsNullOrEmpty(dirName)) dirName = "root";

                var csFiles = Directory.GetFiles(dir, "*.cs")
                    .Select(Path.GetFileName)
                    .Where(f => !string.IsNullOrEmpty(f) && !f.StartsWith(".#"))
                    .OrderBy(f => f)
                    .ToList();

                if (csFiles.Count == 0) continue;

                string buildFile = Path.Combine(dir, "BUILD.bazel");
                if (!File.Exists(buildFile))
                {
                    buildFile = Path.Combine(dir, "BUILD");
                }

                var targets = new List<string>();
                if (File.Exists(buildFile))
                {
                    string buildContent = File.ReadAllText(buildFile);
                    var matches = Regex.Matches(buildContent, @"(?:csharp_library|csharp_binary|csharp_test)\s*\(\s*name\s*=\s*""([^""]+)""");
                    foreach (Match m in matches)
                    {
                        targets.Add(m.Groups[1].Value);
                    }
                }

                if (targets.Count == 0)
                {
                    targets.Add(dirName);
                }

                foreach (var target in targets)
                {
                    string csprojFile = Path.Combine(dir, $"{target}.bazel.csproj");
                    string csprojContent = GenerateCsproj(workspace, dir, target, csFiles);

                    if (checkMode || roundTrip)
                    {
                        if (!File.Exists(csprojFile))
                        {
                            Console.Error.WriteLine($"Missing synthetic csproj: {csprojFile}");
                            errorCount++;
                        }
                        else
                        {
                            string existing = File.ReadAllText(csprojFile);
                            if (Normalize(existing) != Normalize(csprojContent))
                            {
                                Console.Error.WriteLine($"Out-of-sync csproj: {csprojFile}");
                                errorCount++;
                            }
                        }
                    }

                    if (!checkMode)
                    {
                        File.WriteAllText(csprojFile, csprojContent, Encoding.UTF8);
                        Console.WriteLine($"Synchronized: {csprojFile}");
                    }
                }
            }

            if (checkMode && errorCount > 0)
            {
                Console.Error.WriteLine($"Check failed: {errorCount} files out of sync.");
                return 1;
            }

            Console.WriteLine("CsprojSync completed successfully.");
            return 0;
        }

        private static List<string> FindCsDirectories(string root)
        {
            var results = new List<string>();
            var ignoredDirs = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                ".git", "bazel-bin", "bazel-out", "bazel-testlogs", "bin", "obj", ".idea", ".vscode"
            };

            void Walk(string current)
            {
                string name = Path.GetFileName(current);
                if (name.StartsWith("bazel-") || ignoredDirs.Contains(name))
                {
                    return;
                }

                bool hasCs = false;
                try
                {
                    hasCs = Directory.EnumerateFiles(current, "*.cs").Any();
                }
                catch { }

                if (hasCs)
                {
                    results.Add(current);
                }

                try
                {
                    foreach (var sub in Directory.EnumerateDirectories(current))
                    {
                        Walk(sub);
                    }
                }
                catch { }
            }

            Walk(root);
            return results;
        }

        private static string GenerateCsproj(string workspace, string dir, string targetName, List<string?> csFiles)
        {
            string relDir = Path.GetRelativePath(workspace, dir).Replace("\\", "/");
            int depth = relDir.Split(new[] { '/' }, StringSplitOptions.RemoveEmptyEntries).Length;
            string upPrefix = string.Join("/", Enumerable.Repeat("..", depth));
            string bazelBinRel = string.IsNullOrEmpty(upPrefix) ? "bazel-bin" : $"{upPrefix}/bazel-bin";

            var sb = new StringBuilder();
            // The SDK is imported by hand so obj/<target>/ can be set before Sdk.props reads it. Restore then
            // keeps its assets per project, and NuGetLockFilePath keeps it from adopting the packages.lock.json
            // that sits next to the BUILD file for the nuget extension.
            // https://learn.microsoft.com/en-us/nuget/consume-packages/package-references-in-project-files#locking-dependencies
            sb.AppendLine("<Project>");
            sb.AppendLine("  <PropertyGroup>");
            sb.AppendLine($"    <BaseIntermediateOutputPath>obj/{targetName}/</BaseIntermediateOutputPath>");
            sb.AppendLine($"    <NuGetLockFilePath>obj/{targetName}/packages.lock.json</NuGetLockFilePath>");
            sb.AppendLine("  </PropertyGroup>");
            sb.AppendLine();
            sb.AppendLine("  <Import Project=\"Sdk.props\" Sdk=\"Microsoft.NET.Sdk\" />");
            sb.AppendLine();
            sb.AppendLine("  <PropertyGroup>");
            sb.AppendLine("    <TargetFramework>net8.0</TargetFramework>");
            sb.AppendLine("    <EnableDefaultItems>false</EnableDefaultItems>");
            sb.AppendLine("    <Nullable>enable</Nullable>");
            sb.AppendLine("    <LangVersion>latest</LangVersion>");
            sb.AppendLine("  </PropertyGroup>");
            sb.AppendLine();
            sb.AppendLine("  <ItemGroup>");
            foreach (var f in csFiles)
            {
                sb.AppendLine($"    <Compile Include=\"{f}\" />");
            }
            sb.AppendLine("  </ItemGroup>");
            sb.AppendLine();
            sb.AppendLine("  <ItemGroup>");
            sb.AppendLine($"    <Reference Include=\"{targetName}\">");
            sb.AppendLine($"      <HintPath>{bazelBinRel}/{relDir}/{targetName}.ref.dll</HintPath>");
            sb.AppendLine("    </Reference>");
            sb.AppendLine("  </ItemGroup>");
            sb.AppendLine();
            sb.AppendLine("  <Import Project=\"Sdk.targets\" Sdk=\"Microsoft.NET.Sdk\" />");
            sb.AppendLine("</Project>");
            return sb.ToString();
        }

        private static int BootstrapLock(string workspace)
        {
            var packages = new SortedDictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            var frameworks = new SortedSet<string>(StringComparer.OrdinalIgnoreCase);
            string propsFile = Path.Combine(workspace, "Directory.Packages.props");
            if (File.Exists(propsFile))
            {
                // Central versions fill in PackageReferences that carry no Version.
                foreach (Match m in Regex.Matches(File.ReadAllText(propsFile), @"<PackageVersion\s+Include=""([^""]+)""\s+Version=""([^""]+)""", RegexOptions.IgnoreCase))
                    packages[m.Groups[1].Value] = m.Groups[2].Value;
            }
            var csprojFiles = Directory.GetFiles(workspace, "*.csproj", SearchOption.AllDirectories)
                .Where(p => !p.EndsWith(".bazel.csproj") && !Path.GetRelativePath(workspace, p).Split('/', '\\').Any(d => d.StartsWith(".")) && !p.Contains("bazel-") && !p.Contains("/bin/") && !p.Contains("/obj/") && !p.Contains("\\bin\\") && !p.Contains("\\obj\\"));

            foreach (var file in csprojFiles)
            {
                string content = File.ReadAllText(file);
                foreach (Match m in Regex.Matches(content, @"<PackageReference\s+[^>]+>", RegexOptions.IgnoreCase))
                {
                    var idMatch = Regex.Match(m.Value, @"Include=""([^""]+)""", RegexOptions.IgnoreCase);
                    var verMatch = Regex.Match(m.Value, @"Version=""([^""]+)""", RegexOptions.IgnoreCase);
                    if (idMatch.Success && verMatch.Success)
                        packages[idMatch.Groups[1].Value] = verMatch.Groups[1].Value;
                }
                foreach (Match m in Regex.Matches(content, @"<TargetFrameworks?>([^<]+)<", RegexOptions.IgnoreCase))
                    frameworks.UnionWith(m.Groups[1].Value.Split(';', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries));
            }

            string lockFile = Path.Combine(workspace, "packages.lock.json");
            if (!File.Exists(lockFile))
            {
                // Restore one project that references every package, so the workspace gets a single lock
                // file with real content hashes. It sits in the workspace so its NuGet.Config applies.
                string scratch = Path.Combine(workspace, ".bootstrap-lock");
                Directory.CreateDirectory(scratch);
                try
                {
                    var sb = new StringBuilder();
                    sb.AppendLine("<Project Sdk=\"Microsoft.NET.Sdk\">");
                    if (frameworks.Count > 0)
                    {
                        sb.AppendLine("  <PropertyGroup>");
                        sb.AppendLine($"    <TargetFrameworks>{string.Join(';', frameworks)}</TargetFrameworks>");
                        sb.AppendLine("  </PropertyGroup>");
                    }
                    sb.AppendLine("  <ItemGroup>");
                    foreach (var kvp in packages)
                        sb.AppendLine($"    <PackageReference Include=\"{kvp.Key}\" Version=\"{kvp.Value}\" />");
                    sb.AppendLine("  </ItemGroup>");
                    sb.AppendLine("</Project>");
                    string project = Path.Combine(scratch, "BootstrapLock.csproj");
                    File.WriteAllText(project, sb.ToString(), Encoding.UTF8);

                    string? root = Environment.GetEnvironmentVariable("DOTNET_ROOT");
                    string dotnet = !string.IsNullOrEmpty(root) && File.Exists(Path.Combine(root, OperatingSystem.IsWindows() ? "dotnet.exe" : "dotnet"))
                        ? Path.Combine(root, OperatingSystem.IsWindows() ? "dotnet.exe" : "dotnet")
                        : "dotnet";
                    var psi = new System.Diagnostics.ProcessStartInfo(dotnet) { WorkingDirectory = scratch, UseShellExecute = false };
                    foreach (var arg in new[] { "restore", project, "--use-lock-file", "-p:NuGetLockFilePath=" + lockFile, "-p:ManagePackageVersionsCentrally=false" })
                        psi.ArgumentList.Add(arg);
                    System.Diagnostics.Process proc;
                    try
                    {
                        proc = System.Diagnostics.Process.Start(psi)!;
                    }
                    catch (System.ComponentModel.Win32Exception e)
                    {
                        Console.Error.WriteLine($"--bootstrap-lock needs a .NET SDK to run dotnet restore. Set DOTNET_ROOT or put dotnet on PATH. ({e.Message})");
                        return 1;
                    }
                    using (proc)
                    {
                        proc.WaitForExit();
                        if (proc.ExitCode != 0 || !File.Exists(lockFile))
                        {
                            Console.Error.WriteLine($"dotnet restore failed, so no packages.lock.json was written. Fix the errors above and run --bootstrap-lock again.");
                            if (File.Exists(lockFile)) File.Delete(lockFile);
                            return 1;
                        }
                    }
                    Console.WriteLine($"Restored lockfile via dotnet restore: {lockFile}");
                }
                finally
                {
                    Directory.Delete(scratch, true);
                }
            }

            if (!File.Exists(propsFile))
            {
                var sb = new StringBuilder();
                sb.AppendLine("<Project>");
                sb.AppendLine("  <PropertyGroup>");
                sb.AppendLine("    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>");
                sb.AppendLine("  </PropertyGroup>");
                sb.AppendLine("  <ItemGroup>");
                foreach (var kvp in packages)
                {
                    sb.AppendLine($"    <PackageVersion Include=\"{kvp.Key}\" Version=\"{kvp.Value}\" />");
                }
                sb.AppendLine("  </ItemGroup>");
                sb.AppendLine("</Project>");
                File.WriteAllText(propsFile, sb.ToString(), Encoding.UTF8);
                Console.WriteLine($"Bootstrapped: {propsFile}");
            }
            return 0;
        }

        private static string Normalize(string s) => s.Replace("\r\n", "\n").Trim();
    }
}
