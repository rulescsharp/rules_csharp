using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace RulesCsharp.IntegrationTests;

[TestClass]
public class MSTestSuite
{
    [TestMethod]
    [TestCategory("Unit")]
    public void Addition() => Assert.AreEqual(4, 2 + 2);

    [TestMethod]
    [TestCategory("Slow")]
    public void SkippedByFilter() => Assert.Fail("test_filter should leave this out");
}
