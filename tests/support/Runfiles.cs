using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace RulesCsharp.Tests;

/// <summary>Maps runfiles paths to files on disk.</summary>
/// <remarks>
/// Windows runs tests without a runfiles tree by default, so this reads RUNFILES_MANIFEST_FILE when
/// Bazel sets it and walks the runfiles directory otherwise.
/// </remarks>
public static class Runfiles
{
    private static readonly Lazy<IReadOnlyDictionary<string, string>> Entries = new(Load);

    public static IReadOnlyDictionary<string, string> All => Entries.Value;

    /// <summary>Returns the one file whose runfiles path matches, and fails on zero or several.</summary>
    public static string Find(string description, Func<string, bool> match)
    {
        var hits = All.Where(e => match(e.Key)).Select(e => e.Value).Distinct().ToList();
        if (hits.Count != 1)
        {
            throw new InvalidOperationException(
                $"Expected one runfile for {description}, found {hits.Count}: {string.Join(", ", hits)}");
        }
        return hits[0];
    }

    private static IReadOnlyDictionary<string, string> Load()
    {
        var map = new Dictionary<string, string>(StringComparer.Ordinal);
        var manifest = Environment.GetEnvironmentVariable("RUNFILES_MANIFEST_FILE");
        if (!string.IsNullOrEmpty(manifest) && File.Exists(manifest))
        {
            foreach (var line in File.ReadLines(manifest))
            {
                var space = line.IndexOf(' ');
                if (space > 0 && space < line.Length - 1)
                {
                    map[line[..space]] = line[(space + 1)..];
                }
            }
            return map;
        }

        var dir = Environment.GetEnvironmentVariable("RUNFILES_DIR")
            ?? Environment.GetEnvironmentVariable("TEST_SRCDIR")
            ?? throw new InvalidOperationException("Neither RUNFILES_MANIFEST_FILE nor RUNFILES_DIR is set.");
        var options = new EnumerationOptions { RecurseSubdirectories = true, AttributesToSkip = 0 };
        foreach (var file in Directory.EnumerateFiles(dir, "*", options))
        {
            map[Path.GetRelativePath(dir, file).Replace('\\', '/')] = file;
        }
        return map;
    }
}
