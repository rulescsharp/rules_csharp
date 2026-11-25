namespace RunfilesLib;

public static class DataReader
{
    public static string? PayloadPath() =>
        RulesCsharp.Runfiles.Runfiles.Create().Rlocation("mydata/payload.txt", typeof(DataReader).Assembly);
}
