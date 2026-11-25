namespace Usings;

// StringBuilder and Console resolve only through the usings attribute.
public static class Greeting
{
    public static string Build() => new StringBuilder("Hello").Append(Console.Out.NewLine).ToString();
}
