using System.Runtime.InteropServices;

namespace Tests.Integration.Native;

public static class NativeLib
{
    [DllImport("add", EntryPoint = "add")]
    public static extern int Add(int a, int b);
}
