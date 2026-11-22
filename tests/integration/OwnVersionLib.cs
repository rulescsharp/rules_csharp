// generate_assembly_info = False, so this version is the only one even though the library has friends.
[assembly: System.Reflection.AssemblyVersion("2.0.0.0")]

namespace Tests.Integration;

public static class OwnVersionLib
{
    internal static int Hidden() => 42;
}
