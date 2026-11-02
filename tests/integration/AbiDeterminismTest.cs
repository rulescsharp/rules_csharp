using System;
using System.IO;
using System.Security.Cryptography;
using RulesCsharp.Tests;

// abi_var1 and abi_var2 have the same public API and different method bodies.
string Hash(string variant, string file)
{
    var path = Runfiles.Find($"{variant}/{file}", key => key.EndsWith($"tests/integration/{variant}/{file}", StringComparison.Ordinal));
    var hash = Convert.ToHexString(SHA256.HashData(File.ReadAllBytes(path))).ToLowerInvariant();
    Console.WriteLine($"{variant}/{file} SHA-256: {hash}");
    return hash;
}

if (Hash("abi_var1", "lib.ref.dll") != Hash("abi_var2", "lib.ref.dll"))
{
    Console.WriteLine("FAILED: .ref.dll hashes differ. Expected identical refouts for identical public APIs.");
    return 1;
}

if (Hash("abi_var1", "lib.dll") == Hash("abi_var2", "lib.dll"))
{
    Console.WriteLine("FAILED: .dll hashes match. Expected different implementation dlls for different method bodies.");
    return 1;
}

Console.WriteLine("PASSED: .ref.dll outputs are identical and the .dlls differ.");
return 0;
