using System;
using System.Diagnostics;
using Newtonsoft.Json.Bson;

public static class SecondHubTest
{
    public static int Main()
    {
        var json = typeof(BsonDataReader).BaseType!.Assembly;
        var version = FileVersionInfo.GetVersionInfo(json.Location).FileVersion ?? "";
        Console.WriteLine($"Newtonsoft.Json {version}");
        return version.StartsWith("13.0.3.") ? 0 : 1;
    }
}
