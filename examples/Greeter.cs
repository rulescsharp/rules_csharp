namespace RulesCsharp.Examples;

/// <summary>Builds greetings.</summary>
public static class Greeter
{
    /// <summary>Greets <paramref name="name"/>, or anyone when it is empty.</summary>
    public static string Greet(string name)
    {
        if (string.IsNullOrEmpty(name))
        {
            return "Hello!";
        }
        return $"Hello, {name}!";
    }
}
