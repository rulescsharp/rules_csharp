using System;
using System.Resources;

namespace IntegrationTests;

// Each .resx reads back, the first under its default name, and two with the same file name stay apart. And a source file with a space in its path compiled.
public static class ResxTest
{
    public static int Main()
    {
        var greeting = new ResourceManager("resx_test.Strings", typeof(ResxTest).Assembly).GetString("Greeting");
        var other = new ResourceManager("resx_test.Other", typeof(ResxTest).Assembly).GetString("Greeting");
        Console.WriteLine($"Greeting {greeting}, other {other}, {Spaced.Value}");
        return greeting == "hello from resx" && other == "hello from the other resx" && Spaced.Value == "spaced ok" ? 0 : 1;
    }
}
