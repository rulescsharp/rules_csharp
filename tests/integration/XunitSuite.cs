using Xunit;

namespace RulesCsharp.IntegrationTests;

public class XunitSuite
{
    [Fact]
    [Trait("Category", "Unit")]
    public void Addition() => Assert.Equal(4, 2 + 2);

    // Both rows share one fully qualified name, so they always run in the same shard.
    [Theory]
    [Trait("Category", "Unit")]
    [InlineData(1, 2)]
    [InlineData(2, 4)]
    public void Doubles(int value, int doubled) => Assert.Equal(doubled, value * 2);

    [Fact]
    [Trait("Category", "Slow")]
    public void SkippedByFilter() => Assert.Fail("test_filter should leave this out");
}
