using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;

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
    private readonly RepoMapping _repoMapping;

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
        var exe = Environment.ProcessPath;
        var manifestPath = Environment.GetEnvironmentVariable("RUNFILES_MANIFEST_FILE");
        if ((string.IsNullOrEmpty(manifestPath) || !File.Exists(manifestPath)) && !string.IsNullOrEmpty(exe))
        {
            manifestPath = exe + ".runfiles_manifest";
        }

        var dir = Environment.GetEnvironmentVariable("RUNFILES_DIR")
            ?? Environment.GetEnvironmentVariable("TEST_SRCDIR");
        if ((string.IsNullOrEmpty(dir) || !Directory.Exists(dir)) && !string.IsNullOrEmpty(exe))
        {
            dir = exe + ".runfiles";
        }
        if (!Directory.Exists(dir))
        {
            dir = null;
        }

        // The manifest lists files only, so a runfiles tree next to it still answers for
        // directories.
        if (File.Exists(manifestPath))
        {
            return new Runfiles(LoadManifest(manifestPath), dir);
        }

        if (dir == null)
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
    /// <c>_repo_mapping</c> file Bazel writes next to the runfiles. Code that may be built
    /// in another module should call <see cref="Rlocation(string, Assembly)"/> instead.
    /// </remarks>
    public string? Rlocation(string path) => Rlocation(path, sourceRepository: "");

    /// <summary>
    /// Like <see cref="Rlocation(string)"/>, but maps the first path segment the way the
    /// repository that built <paramref name="caller"/> sees it. Pass the assembly of the
    /// calling code, such as <c>typeof(MyClass).Assembly</c>, so a library in any module can
    /// name its own dependencies by their <c>repo_name</c>.
    /// </summary>
    public string? Rlocation(string path, Assembly caller) => Rlocation(path, RepositoryOf(caller));

    /// <summary>
    /// Like <see cref="Rlocation(string)"/>, but maps the first path segment the way the
    /// repository with canonical name <paramref name="sourceRepository"/> sees it. The main
    /// repository is the empty string.
    /// </summary>
    public string? Rlocation(string path, string sourceRepository)
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
        if (slash > 0 && _repoMapping.TryMap(sourceRepository, key[..slash], out var canonical))
        {
            key = canonical + key[slash..];
        }
        return Lookup(key);
    }

    private string? Lookup(string key)
    {
        if (_manifest != null && _manifest.TryGetValue(key, out var file))
        {
            return file;
        }
        if (_directory == null)
        {
            return null;
        }

        var candidate = Path.Combine(_directory, key.Replace('/', Path.DirectorySeparatorChar));
        return File.Exists(candidate) || Directory.Exists(candidate) ? candidate : null;
    }

    // Assemblies built by csharp_library, csharp_binary and csharp_test carry their canonical
    // repository. Any other assembly is treated as the main repository's.
    private static string RepositoryOf(Assembly caller) =>
        caller.GetCustomAttributes<AssemblyMetadataAttribute>()
            .FirstOrDefault(m => m.Key == "Bazel.Repository")?.Value ?? "";

    private static RepoMapping LoadRepoMapping(string? mappingPath) =>
        new(mappingPath != null && File.Exists(mappingPath) ? File.ReadLines(mappingPath) : []);

    // Lines are "source,apparent,target". A source ending in '*' stands for every repository
    // whose canonical name starts with the rest, which Bazel writes for module extension repos.
    private sealed class RepoMapping
    {
        private readonly Dictionary<(string Source, string Apparent), string> _exact = new();
        private readonly List<(string Prefix, string Apparent, string Target)> _prefixed = new();

        public RepoMapping(IEnumerable<string> lines)
        {
            foreach (var line in lines)
            {
                var parts = line.Split(',');
                if (parts.Length != 3 || parts[1].Length == 0)
                {
                    continue;
                }
                if (parts[0].EndsWith('*'))
                {
                    _prefixed.Add((parts[0][..^1], parts[1], parts[2]));
                }
                else
                {
                    _exact[(parts[0], parts[1])] = parts[2];
                }
            }
        }

        public bool TryMap(string source, string apparent, out string target)
        {
            if (_exact.TryGetValue((source, apparent), out target!))
            {
                return true;
            }
            foreach (var (prefix, name, canonical) in _prefixed)
            {
                if (name == apparent && source.StartsWith(prefix, StringComparison.Ordinal))
                {
                    target = canonical;
                    return true;
                }
            }
            target = "";
            return false;
        }
    }

    private static IReadOnlyDictionary<string, string> LoadManifest(string manifestPath)
    {
        var map = new Dictionary<string, string>(StringComparer.Ordinal);
        foreach (var line in File.ReadLines(manifestPath))
        {
            // Bazel escapes a line whose paths hold a space, newline or backslash and marks it
            // with a leading space. The link escapes all three, the target only the last two.
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
}
