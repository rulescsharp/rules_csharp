using System;
using System.Collections.Generic;
using System.IO;

namespace RulesCsharp.Runfiles;

/// <summary>
/// Resolves Bazel runfiles paths to real files on disk.
/// </summary>
/// <remarks>
/// Matches the Bazel runfiles contract used by the Java and Python helpers:
/// https://bazel.build/extending/rules#runfiles
/// Prefer <see cref="Create"/> then <see cref="Rlocation"/>. On Windows Bazel often
/// sets only <c>RUNFILES_MANIFEST_FILE</c>, with no runfiles tree.
/// </remarks>
public sealed class Runfiles
{
    private readonly IReadOnlyDictionary<string, string>? _manifest;
    private readonly string? _directory;
    private readonly IReadOnlyDictionary<string, string> _repoMapping;

    private Runfiles(IReadOnlyDictionary<string, string>? manifest, string? directory)
    {
        _manifest = manifest;
        _directory = directory;
        _repoMapping = LoadRepoMapping(Lookup("_repo_mapping"));
    }

    /// <summary>
    /// Builds a lookup from the process environment and, when needed, next to the executable.
    /// </summary>
    public static Runfiles Create()
    {
        var manifestPath = Environment.GetEnvironmentVariable("RUNFILES_MANIFEST_FILE");
        if (string.IsNullOrEmpty(manifestPath) || !File.Exists(manifestPath))
        {
            var exe = Environment.ProcessPath;
            if (!string.IsNullOrEmpty(exe))
            {
                var beside = exe + ".runfiles_manifest";
                if (File.Exists(beside))
                {
                    manifestPath = beside;
                }
            }
        }

        if (!string.IsNullOrEmpty(manifestPath) && File.Exists(manifestPath))
        {
            return new Runfiles(LoadManifest(manifestPath), directory: null);
        }

        var dir = Environment.GetEnvironmentVariable("RUNFILES_DIR")
            ?? Environment.GetEnvironmentVariable("TEST_SRCDIR");
        if (string.IsNullOrEmpty(dir) || !Directory.Exists(dir))
        {
            var exe = Environment.ProcessPath;
            if (!string.IsNullOrEmpty(exe))
            {
                var beside = exe + ".runfiles";
                if (Directory.Exists(beside))
                {
                    dir = beside;
                }
            }
        }

        if (string.IsNullOrEmpty(dir) || !Directory.Exists(dir))
        {
            throw new InvalidOperationException(
                "No Bazel runfiles found. Expected RUNFILES_MANIFEST_FILE, RUNFILES_DIR, TEST_SRCDIR, or a .runfiles tree next to the executable.");
        }

        return new Runfiles(manifest: null, directory: dir);
    }

    /// <summary>
    /// Returns the absolute path for a runfiles-relative path such as
    /// <c>_main/web/greeting.txt</c> or <c>my_module/web/greeting.txt</c>, or null when
    /// that path is not in the runfiles.
    /// </summary>
    /// <remarks>
    /// The first path segment may be a repository name as the main module sees it, such as
    /// a <c>bazel_dep</c> name. It is mapped to the canonical name through the
    /// <c>_repo_mapping</c> file Bazel writes next to the runfiles.
    /// </remarks>
    public string? Rlocation(string path)
    {
        if (string.IsNullOrEmpty(path))
        {
            return null;
        }

        if (Path.IsPathRooted(path))
        {
            return path;
        }

        var key = path.Replace('\\', '/');
        var slash = key.IndexOf('/');
        if (slash > 0 && _repoMapping.TryGetValue(key[..slash], out var canonical))
        {
            key = canonical + key[slash..];
        }
        return Lookup(key);
    }

    private string? Lookup(string key)
    {
        if (_manifest != null)
        {
            return _manifest.TryGetValue(key, out var file) ? file : null;
        }

        var candidate = Path.Combine(_directory!, key.Replace('/', Path.DirectorySeparatorChar));
        return File.Exists(candidate) || Directory.Exists(candidate) ? candidate : null;
    }

    // Lines are "source,apparent,target". Only mappings seen from the main repository apply.
    private static IReadOnlyDictionary<string, string> LoadRepoMapping(string? mappingPath)
    {
        var map = new Dictionary<string, string>(StringComparer.Ordinal);
        if (mappingPath == null || !File.Exists(mappingPath))
        {
            return map;
        }
        foreach (var line in File.ReadLines(mappingPath))
        {
            var parts = line.Split(',');
            if (parts.Length == 3 && parts[0].Length == 0 && parts[1].Length > 0)
            {
                map[parts[1]] = parts[2];
            }
        }
        return map;
    }

    private static IReadOnlyDictionary<string, string> LoadManifest(string manifestPath)
    {
        var map = new Dictionary<string, string>(StringComparer.Ordinal);
        foreach (var line in File.ReadLines(manifestPath))
        {
            var space = line.IndexOf(' ');
            if (space > 0 && space < line.Length - 1)
            {
                map[line[..space]] = line[(space + 1)..];
            }
        }
        return map;
    }
}
