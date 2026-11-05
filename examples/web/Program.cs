using Microsoft.AspNetCore.Http;
using RulesCsharp.Examples.Web;
using RulesCsharp.Runfiles;

var runfiles = Runfiles.Create();
var greetingPath = runfiles.Rlocation("_main/web/greeting.txt")
    ?? throw new InvalidOperationException("missing runfile _main/web/greeting.txt");
var greeting = File.ReadAllText(greetingPath).Trim();

// Runs the endpoint on an in-memory request, so the example needs no network.
var context = new DefaultHttpContext();
await GreetingEndpoint.Create(new GreetingOptions { Message = greeting })(context);
Console.WriteLine($"{context.Response.StatusCode} {context.Response.Headers["X-Greeting"]}");
