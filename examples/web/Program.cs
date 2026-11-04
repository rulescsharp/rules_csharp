using Microsoft.AspNetCore.Http;
using RulesCsharp.Examples.Web;

var greeting = File.ReadAllText(Runfile("_main/web/greeting.txt")).Trim();

// Runs the endpoint on an in-memory request, so the example needs no network.
var context = new DefaultHttpContext();
await GreetingEndpoint.Create(new GreetingOptions { Message = greeting })(context);
Console.WriteLine($"{context.Response.StatusCode} {context.Response.Headers["X-Greeting"]}");

// Finds a file from data through the runfiles manifest, or the runfiles tree where there is one.
static string Runfile(string path)
{
    var exe = Environment.ProcessPath!;
    var manifest = Environment.GetEnvironmentVariable("RUNFILES_MANIFEST_FILE") ?? exe + ".runfiles_manifest";
    if (File.Exists(manifest))
    {
        foreach (var line in File.ReadLines(manifest))
        {
            if (line.StartsWith(path + " ", StringComparison.Ordinal))
            {
                return line[(path.Length + 1)..];
            }
        }
    }
    var dir = Environment.GetEnvironmentVariable("RUNFILES_DIR") ?? exe + ".runfiles";
    return Path.Combine(dir, path);
}
