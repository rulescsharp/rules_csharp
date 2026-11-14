using System.Globalization;
using System.Resources;

// Strings.fr.resx builds into fr/localized.resources.dll, which ResourceManager loads for French.
var strings = new ResourceManager("localized.Strings", typeof(Program).Assembly);
Console.WriteLine(strings.GetString("Greeting", CultureInfo.InvariantCulture));
Console.WriteLine(strings.GetString("Greeting", new CultureInfo("fr")));
