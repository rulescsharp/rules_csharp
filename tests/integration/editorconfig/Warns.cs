namespace IntegrationTests.EditorConfig;

public static class Warns
{
    public static int Parse(string text)
    {
        try
        {
            return int.Parse(text);
        }
        catch (System.FormatException unused)
        {
            return 0;
        }
    }
}
