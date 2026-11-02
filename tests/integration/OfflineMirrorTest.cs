using System;
using System.Collections.Generic;
using System.Formats.Tar;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net.Http;
using System.Security.Cryptography;
using System.Xml.Linq;

var testDir = Path.Combine(Environment.GetEnvironmentVariable("TEST_TMPDIR") ?? Path.GetTempPath(), "offline_mirror");
var mirror = Path.Combine(testDir, "local_mirror");
Directory.CreateDirectory(mirror);

// 1. Populate a local mirror with a nupkg and an SDK archive
const string PkgId = "CommandLineParser";
const string Version = "2.9.1";
var nupkg = Path.Combine(mirror, $"{PkgId}.{Version}.nupkg");
using (var zip = ZipFile.Open(nupkg, ZipArchiveMode.Create))
{
    using (var dll = new StreamWriter(zip.CreateEntry("lib/net8.0/CommandLine.dll").Open()))
    {
        dll.WriteLine("DUMMY_DLL_BYTES_FOR_OFFLINE_MIRROR_TEST");
    }
    using var nuspec = new StreamWriter(zip.CreateEntry($"{PkgId}.nuspec").Open());
    nuspec.Write($"""
        <?xml version="1.0" encoding="utf-8"?>
        <package xmlns="http://schemas.microsoft.com/packaging/2012/06/nuspec.xsd">
          <metadata>
            <id>{PkgId}</id>
            <version>{Version}</version>
            <authors>CommandLine</authors>
            <description>Command Line Parser Library</description>
          </metadata>
        </package>
        """);
}
var flat = Path.Combine(mirror, PkgId.ToLowerInvariant(), Version);
Directory.CreateDirectory(flat);
File.Copy(nupkg, Path.Combine(flat, $"{PkgId.ToLowerInvariant()}.{Version}.nupkg"));

var sdk = Path.Combine(testDir, "sdk_tmp");
Directory.CreateDirectory(Path.Combine(sdk, "sdk", "8.0.403", "Roslyn", "bincore"));
File.WriteAllText(Path.Combine(sdk, "dotnet"), "");
File.WriteAllText(Path.Combine(sdk, "sdk", "8.0.403", "Roslyn", "bincore", "csc.dll"), "");
using (var archive = new GZipStream(File.Create(Path.Combine(mirror, "dotnet-sdk-8.0.403-osx-arm64.tar.gz")), CompressionLevel.Optimal))
{
    TarFile.CreateFromDirectory(sdk, archive, includeBaseDirectory: false);
}
Console.WriteLine($"Local mirror populated at {mirror}");

var expectedIntegrity = "sha512-" + Convert.ToBase64String(SHA512.HashData(File.ReadAllBytes(nupkg)));

// 2. A bogus primary URL falls back to the file mirror, and the payload matches its SRI digest
const string BogusPrimary = "http://127.0.0.1:59999/artifactory/nuget-remote";
var mirrorUri = new Uri(mirror + Path.DirectorySeparatorChar).AbsoluteUri;
var candidates = new[]
{
    $"{BogusPrimary}/{PkgId.ToLowerInvariant()}/{Version}/{PkgId.ToLowerInvariant()}.{Version}.nupkg",
    $"{BogusPrimary}/{PkgId}/{Version}/{PkgId}.{Version}.nupkg",
    $"{mirrorUri}{PkgId}.{Version}.nupkg",
    $"{mirrorUri}{PkgId.ToLowerInvariant()}.{Version}.nupkg",
    $"{mirrorUri}{PkgId.ToLowerInvariant()}/{Version}/{PkgId.ToLowerInvariant()}.{Version}.nupkg",
};

Console.WriteLine("Simulating Bazel multi-URL download_and_extract with bogus primary URL...");
using var http = new HttpClient { Timeout = TimeSpan.FromSeconds(1) };
byte[]? payload = null;
foreach (var url in candidates)
{
    Console.WriteLine($"Trying candidate URL: {url}");
    try
    {
        var uri = new Uri(url);
        payload = uri.IsFile ? File.ReadAllBytes(uri.LocalPath) : http.GetByteArrayAsync(uri).GetAwaiter().GetResult();
        Console.WriteLine($"Successfully retrieved payload from fallback: {url}");
        break;
    }
    catch (Exception e)
    {
        Console.WriteLine($"Candidate URL failed as expected ({e.GetType().Name}): {url}");
    }
}

if (payload == null)
{
    Console.WriteLine("FAILED: Could not download payload from any candidate URL.");
    return 1;
}

var actual = Convert.ToBase64String(SHA512.HashData(payload));
var expected = expectedIntegrity.Split('-', 2)[1];
if (actual != expected)
{
    Console.WriteLine($"FAILED: Integrity mismatch. Expected {expected}, got {actual}");
    return 1;
}
Console.WriteLine("SRI integrity verification verified successfully on payload from local mirror fallback.");

// 3. NuGet.Config packageSources honor <clear />
var config = XDocument.Parse("""
    <?xml version="1.0" encoding="utf-8"?>
    <configuration>
      <packageSources>
        <clear />
        <add key="internal-artifactory" value="https://artifactory.corp.internal/artifactory/api/nuget/v3/index.json" />
        <add key="local-backup" value="file:///opt/packages" />
      </packageSources>
      <packageSourceCredentials>
        <internal-artifactory>
          <add key="Username" value="builder" />
          <add key="ClearTextPassword" value="secret-token-xyz" />
        </internal-artifactory>
      </packageSourceCredentials>
    </configuration>
    """);
var sources = new List<string>();
foreach (var element in config.Root!.Element("packageSources")!.Elements())
{
    if (element.Name == "clear")
    {
        sources.Clear();
    }
    else if (element.Name == "add" && element.Attribute("value") is { } value)
    {
        sources.Add(value.Value);
    }
}

var expectedSources = new[] { "https://artifactory.corp.internal/artifactory/api/nuget/v3/index.json", "file:///opt/packages" };
if (!sources.SequenceEqual(expectedSources))
{
    Console.WriteLine($"FAILED: Expected sources {string.Join(", ", expectedSources)}, got {string.Join(", ", sources)}");
    return 1;
}
Console.WriteLine("NuGet.Config XML parsing verified successfully.");

Console.WriteLine("All offline air-gapped mirror resolution assertions passed successfully.");
return 0;
