using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace RulesCsharp.Examples;

[TestClass]
public class GreeterMSTest
{
    [TestMethod]
    public void GreetsByName() => Assert.AreEqual("Hello, BCR!", Greeter.Greet("BCR"));

    [TestMethod]
    public void GreetsBazel() => Assert.AreEqual("Hello, Bazel!", Greeter.Greet("Bazel"));

    [TestMethod]
    public void GreetsEmptyName() => Assert.AreEqual("Hello!", Greeter.Greet(""));
}
