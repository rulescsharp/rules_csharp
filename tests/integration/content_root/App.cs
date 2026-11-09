var builder = WebApplication.CreateBuilder(args);
Console.WriteLine($"{builder.Configuration["Greeting"]}, {builder.Configuration["Suffix"]}");
