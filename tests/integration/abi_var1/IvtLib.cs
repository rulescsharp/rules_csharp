namespace Tests.Integration;

public class IvtService
{
    public static int Compute() => Hidden();

    internal static int Hidden() => 42;
}
