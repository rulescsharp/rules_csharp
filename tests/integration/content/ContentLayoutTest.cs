using System;
using System.IO;

namespace IntegrationTests;

public static class ContentLayoutTest
{
    static readonly (string Path, string Text)[] Expected =
    {
        ("dir_a/config.json", "{\"from\": \"dir_a\"}"),
        ("dir_b/config.json", "{\"from\": \"dir_b\"}"),
        ("top.txt", "top"),
        ("wwwroot/css/app.css", "body { color: green; }"),
    };

    public static int Main()
    {
        var failed = 0;
        foreach (var (path, text) in Expected)
        {
            var full = Path.Combine(AppContext.BaseDirectory, path);
            var actual = File.Exists(full) ? File.ReadAllText(full).Trim() : null;
            Console.WriteLine($"{path}: {actual ?? "missing"}");
            if (actual != text)
            {
                failed++;
            }
        }
        return failed == 0 ? 0 : 1;
    }
}
