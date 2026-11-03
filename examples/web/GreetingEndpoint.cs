using Microsoft.AspNetCore.Http;

namespace RulesCsharp.Examples.Web;

public sealed class GreetingOptions
{
    public string Message { get; set; }
}

public static class GreetingEndpoint
{
    public static RequestDelegate Create(GreetingOptions options) => context =>
    {
        context.Response.StatusCode = StatusCodes.Status200OK;
        context.Response.Headers["X-Greeting"] = options.Message;
        return Task.CompletedTask;
    };
}
