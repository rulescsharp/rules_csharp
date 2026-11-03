using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace RulesCsharp.IntegrationTests;

[TestClass]
public class MSTestSuite
{
    // TestContext comes from TestFramework.Extensions, which MSTest.TestFramework references from build/.
    public TestContext TestContext { get; set; } = null!;

    [TestMethod]
    [TestCategory("Unit")]
    public void Addition() => Assert.AreEqual(4, 2 + 2);

    [TestMethod]
    [TestCategory("Unit")]
    public void TestContextIsSet() => Assert.AreEqual(nameof(TestContextIsSet), TestContext.TestName);

    [TestMethod]
    [TestCategory("Slow")]
    public void SkippedByFilter() => Assert.Fail("test_filter should leave this out");
}
