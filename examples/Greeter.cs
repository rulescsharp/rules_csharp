namespace RulesCsharp.Examples;

public static class Greeter
{
    public static string Greet(string name)
    {
        if (string.IsNullOrEmpty(name))
        {
            return "Hello!";
        }
        return $"Hello, {name}!";
    }
}
