using System;
using System.Runtime.InteropServices;
using Tests.Integration.Native;

// add comes from native_libs on a library dependency, muladd from native_libs on the test itself,
// and muladd loads its own dynamic dependency mul.
if (NativeLib.Add(2, 3) != 5)
{
    Console.WriteLine("FAILED: add(2, 3) did not return 5.");
    return 1;
}
if (MulAdd(2, 3, 4) != 10)
{
    Console.WriteLine("FAILED: muladd(2, 3, 4) did not return 10.");
    return 1;
}

if (Generated.MulAdd(3, 4, 5) != 17)
{
    Console.WriteLine("FAILED: muladd(3, 4, 5) through LibraryImport did not return 17.");
    return 1;
}

Console.WriteLine("PASSED: Bazel-built native libraries load through DllImport and LibraryImport.");
return 0;

[DllImport("muladd", EntryPoint = "muladd")]
static extern int MulAdd(int a, int b, int c);

static partial class Generated
{
    [LibraryImport("muladd", EntryPoint = "muladd")]
    internal static partial int MulAdd(int a, int b, int c);
}
