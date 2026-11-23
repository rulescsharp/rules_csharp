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
                // Same escaping as csharp/runfiles/Runfiles.cs.
                var escaped = line.StartsWith(' ');
                var entry = escaped ? line[1..] : line;
                var space = entry.IndexOf(' ');
                if (space > 0 && space < entry.Length - 1)
                {
                    var link = entry[..space];
                    var target = entry[(space + 1)..];
                    if (escaped)
                    {
                        link = link.Replace(@"\s", " ").Replace(@"\n", "\n").Replace(@"\b", @"\");
                        target = target.Replace(@"\n", "\n").Replace(@"\b", @"\");
                    }
                    map[link] = target;
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
