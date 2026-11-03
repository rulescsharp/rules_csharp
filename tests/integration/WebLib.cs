using Microsoft.AspNetCore.Http;

namespace IntegrationTests;

public static class WebLib
{
    public static string Route(string name) => new PathString("/greet").Add(new PathString("/" + name)).Value!;
}
