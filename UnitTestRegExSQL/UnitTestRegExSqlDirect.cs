using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace UnitTestRegExSQL
{
    [TestClass]
    public class UnitTestRegExSqlDirect
    {
        [TestMethod]
        public void TestMethodBasic()
        {
            Assert.IsTrue(RegExCompiled.RegExCompiledIsMatch("hello", "ll"));
        }
    }
}
