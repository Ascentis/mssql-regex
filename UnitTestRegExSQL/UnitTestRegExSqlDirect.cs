using System.Threading;
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

#if DEBUG
        [TestMethod]
#endif
        public void TestMethodBasicForceExpire()
        {
            RegExCompiled.RegExClearCache();
            Assert.IsTrue(RegExCompiled.RegExCompiledIsMatch("hello", "ll"));
            Assert.AreNotEqual(0, RegExCompiled.RegExCachedCount());
            Thread.Sleep(1000);
            Assert.AreNotEqual(0, RegExCompiled.RegExCachedCount());
            Thread.Sleep(2000);
            Assert.AreEqual(0, RegExCompiled.RegExCachedCount());
            Thread.Sleep(2000);

            // Let's ensure now that cleaner process started again
            Assert.IsTrue(RegExCompiled.RegExCompiledIsMatch("hello", "ll"));
            Assert.AreNotEqual(0, RegExCompiled.RegExCachedCount());
            Thread.Sleep(1000);
            Assert.AreNotEqual(0, RegExCompiled.RegExCachedCount());
            Thread.Sleep(2000);
            Assert.AreEqual(0, RegExCompiled.RegExCachedCount());
        }
    }
}
