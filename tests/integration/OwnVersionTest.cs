using System;
using System.Reflection;
using System.Runtime.Versioning;
using Tests.Integration;

// A friend of own_version_lib, which sets its own AssemblyVersion with generate_assembly_info = False.
var lib = typeof(OwnVersionLib).Assembly;
var version = lib.GetName().Version;
if (version != new Version(2, 0, 0, 0))
{
    Console.WriteLine($"FAILED: expected version 2.0.0.0, got {version}.");
    return 1;
}
if (lib.GetCustomAttribute<AssemblyTitleAttribute>() != null)
{
    Console.WriteLine("FAILED: AssemblyTitle was generated.");
    return 1;
}
if (lib.GetCustomAttribute<TargetFrameworkAttribute>() == null)
{
    Console.WriteLine("FAILED: TargetFramework is missing.");
    return 1;
}
if (OwnVersionLib.Hidden() != 42)
{
    Console.WriteLine("FAILED: the internal member returned the wrong value.");
    return 1;
}

Console.WriteLine("PASSED: a library with friends keeps its own AssemblyVersion.");
return 0;
