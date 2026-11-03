using System.Reflection;
using System.Runtime.Versioning;
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

    // vstest picks the testhost from this attribute and runs an assembly without it as x64 on Apple silicon.
    [TestMethod]
    [TestCategory("Unit")]
    public void TargetFrameworkIsRecorded() => Assert.AreEqual(
        ".NETCoreApp,Version=v" + Environment.Version.ToString(2),
        typeof(MSTestSuite).Assembly.GetCustomAttribute<TargetFrameworkAttribute>()?.FrameworkName);

    [TestMethod]
    [TestCategory("Slow")]
    public void SkippedByFilter() => Assert.Fail("test_filter should leave this out");
}
