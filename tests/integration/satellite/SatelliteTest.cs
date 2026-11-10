using System;
using System.Globalization;
using System.Resources;

namespace IntegrationTests.Satellite;

// French strings come from the satellite assemblies fr/SatelliteApp.resources.dll and fr/SatelliteLib.resources.dll.
public static class SatelliteTest
{
    public static int Main()
    {
        var fr = new CultureInfo("fr");
        var app = new ResourceManager("SatelliteApp.Strings", typeof(SatelliteTest).Assembly);
        var lib = new ResourceManager("SatelliteLib.Strings", typeof(LibStrings).Assembly);
        var neutral = app.GetString("Hello", CultureInfo.InvariantCulture);
        var appFr = app.GetString("Hello", fr);
        var libFr = lib.GetString("Hello", fr);
        // Strings.dev.resx is not culture specific, so it stays in the main assembly.
        var dev = new ResourceManager("SatelliteApp.Strings.dev", typeof(SatelliteTest).Assembly).GetString("Hello");
        Console.WriteLine($"neutral={neutral} fr={appFr} lib_fr={libFr} dev={dev}");
        return neutral == "Hello" && appFr == "Bonjour" && libFr == "Bonjour de lib" && dev == "Hello dev" ? 0 : 1;
    }
}
