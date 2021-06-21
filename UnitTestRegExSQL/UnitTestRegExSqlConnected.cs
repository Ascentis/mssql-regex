using System;
using System.Data.SqlClient;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using UnitTestRegExSQL.Properties;

namespace UnitTestRegExSQL
{
    [TestClass]
    public class UnitTestRegExSqlConnected
    {
        private static readonly SqlConnection Conn;

        static UnitTestRegExSqlConnected()
        {
            Conn = new SqlConnection(Settings.Default.ConnectionString);
            Conn.Open();
#if DEBUG
#if UPLOCK
            var suffix = "Debug_UpgradableLock";
#else
            var suffix = "Debug";
#endif
#else 
#if UPLOCK
            var suffix = "Release_UpgradableLock";
#else
            var suffix = "Release";
#endif
#endif
            var regAssemblyCommands = File.ReadAllText($@"..\..\Published\CreateRegExAssembly_{suffix}.sql").Split(new [] {"GO\r\n"}, StringSplitOptions.RemoveEmptyEntries);
            foreach (var cmdText in regAssemblyCommands)
            {
                using var cmd = new SqlCommand(cmdText, Conn);
                cmd.ExecuteNonQuery();
            }
        }

        [TestMethod]
        public void TestRegExIsMatch()
        {
            using var cmd = new SqlCommand("SELECT dbo.RegExIsMatch('hello', 'hello')", Conn);
            Assert.IsTrue((bool)cmd.ExecuteScalar());
        }

        [TestMethod]
        public void TestRegExExceptionCount()
        {
            using var cmd = new SqlCommand("SELECT dbo.RegExResetExceptionCount()", Conn);
            cmd.ExecuteScalar();
            using var cmd2 = new SqlCommand("SELECT dbo.RegExIsMatch('hello', 'he(llo')", Conn);
            // ReSharper disable once AccessToDisposedClosure
            Assert.ThrowsException<SqlException>(() => cmd2.ExecuteScalar());
            using var cmd3 = new SqlCommand("SELECT dbo.RegExExceptionCount()", Conn);
            Assert.AreEqual(1, (long)cmd3.ExecuteScalar());
        }

        [TestMethod]
        public void TestRegExIsMatchWithOptions()
        {
            using var cmd = new SqlCommand("SELECT dbo.RegExIsMatchWithOptions('hello', 'hello', 1)", Conn);
            Assert.IsTrue((bool)cmd.ExecuteScalar());
        }

        [TestMethod]
        public void TestRegExReplace()
        {
            using var cmd = new SqlCommand("SELECT dbo.RegExReplace('hello my world', 'my', 'your')", Conn);
            Assert.AreEqual("hello your world", (string)cmd.ExecuteScalar());
        }

        [TestMethod]
        public void TestRegExReplaceWithOptions()
        {
            using var cmd = new SqlCommand("SELECT dbo.RegExReplaceWithOptions('hello MY world', 'my', 'your', 1)", Conn);
            Assert.AreEqual("hello your world", (string)cmd.ExecuteScalar());
        }

        [TestMethod]
        public void TestRegExReplaceCount()
        {
            using var cmd = new SqlCommand("SELECT dbo.RegExReplaceCount('hello my my world', 'my', 'your', 1)", Conn);
            Assert.AreEqual("hello your my world", (string)cmd.ExecuteScalar());
            using var cmd2 = new SqlCommand("SELECT dbo.RegExReplaceCount('hello my my world', 'my', 'your', 2)", Conn);
            Assert.AreEqual("hello your your world", (string)cmd2.ExecuteScalar());
        }

        [TestMethod]
        public void TestRegExReplaceCountWithOptions()
        {
            using var cmd = new SqlCommand("SELECT dbo.RegExReplaceCountWithOptions('hello MY my world', 'my', 'your', 1, 1)", Conn);
            Assert.AreEqual("hello your my world", (string)cmd.ExecuteScalar());
            using var cmd2 = new SqlCommand("SELECT dbo.RegExReplaceCountWithOptions('hello MY MY world', 'my', 'your', 2, 1)", Conn);
            Assert.AreEqual("hello your your world", (string)cmd2.ExecuteScalar());
        }

        [TestMethod]
        public void TestRegExSplit()
        {
            using var cmd = new SqlCommand("SELECT * FROM dbo.RegExSplit('hellomyworld', 'my')", Conn);
            using var reader = cmd.ExecuteReader();
            Assert.IsTrue(reader.Read());
            var val = reader.GetSqlString(0);
            Assert.AreEqual("hello", val);
            Assert.IsTrue(reader.Read());
            val = reader.GetSqlString(0);
            Assert.AreEqual("world", val);
            Assert.IsFalse(reader.Read());
        }

        [TestMethod]
        public void TestRegExSplitWithOptions()
        {
            using var cmd = new SqlCommand("SELECT * FROM dbo.RegExSplitWithOptions('helloMYworld', 'my', 1)", Conn);
            using var reader = cmd.ExecuteReader();
            Assert.IsTrue(reader.Read());
            var val = reader.GetSqlString(0);
            Assert.AreEqual("hello", val);
            Assert.IsTrue(reader.Read());
            val = reader.GetSqlString(0);
            Assert.AreEqual("world", val);
            Assert.IsFalse(reader.Read());
        }

        [TestMethod]
        public void TestRegExEscape()
        {
            using var cmd = new SqlCommand("SELECT dbo.RegExEscape('hello\n')", Conn);
            Assert.AreEqual(@"hello\n", (string)cmd.ExecuteScalar());
        }

        [TestMethod]
        public void TestRegExUnescape()
        {
            using var cmd = new SqlCommand(@"SELECT dbo.RegExUnescape('hello\n')", Conn);
            Assert.AreEqual("hello\n", (string)cmd.ExecuteScalar());
        }

        [TestMethod]
        public void TestRegExMatch()
        {
            using var cmd = new SqlCommand("SELECT dbo.RegExMatch('hello', 'hel+o')", Conn);
            Assert.AreEqual("hello", (string)cmd.ExecuteScalar());
        }

        [TestMethod]
        public void TestRegExMatchWithOptions()
        {
            using var cmd = new SqlCommand("SELECT dbo.RegExMatchWithOptions('HELLO', 'hel+o', 1)", Conn);
            Assert.AreEqual("HELLO", (string)cmd.ExecuteScalar());
        }

        [TestMethod]
        public void TestRegExMatchIndexed()
        {
            using var cmd = new SqlCommand("SELECT dbo.RegExMatchIndexed('hello helllo', 'hel+o', 1)", Conn);
            Assert.AreEqual("helllo", (string)cmd.ExecuteScalar());
        }

        [TestMethod]
        public void TestRegExMatchIndexedWithOptions()
        {
            using var cmd = new SqlCommand("SELECT dbo.RegExMatchIndexedWithOptions('HELLO HELLLO', 'hel+o', 1, 1)", Conn);
            Assert.AreEqual("HELLLO", (string)cmd.ExecuteScalar());
        }

        [TestMethod]
        public void TestRegExMatchGroup()
        {
            using var cmd = new SqlCommand("SELECT dbo.RegExMatchGroup('hello', 'he(ll)o', 1)", Conn);
            Assert.AreEqual("ll", (string)cmd.ExecuteScalar());
        }

        [TestMethod]
        public void TestRegExMatchGroupWithOptions()
        {
            using var cmd = new SqlCommand("SELECT dbo.RegExMatchGroupWithOptions('heLLo', 'he(ll)o', 1, 1)", Conn);
            Assert.AreEqual("LL", (string)cmd.ExecuteScalar());
        }

        [TestMethod]
        public void TestRegExMatchGroupIndexed()
        {
            using var cmd = new SqlCommand("SELECT dbo.RegExMatchGroupIndexed('hello helllo', 'he(l*)o', 1, 1)", Conn);
            Assert.AreEqual("lll", (string)cmd.ExecuteScalar());
        }

        [TestMethod]
        public void TestRegExMatchGroupIndexedWithOptions()
        {
            using var cmd = new SqlCommand("SELECT dbo.RegExMatchGroupIndexedWithOptions('hello heLLLo', 'he(l*)o', 1, 1, 1)", Conn);
            Assert.AreEqual("LLL", (string)cmd.ExecuteScalar());
        }

        [TestMethod]
        public void TestRegExMatches()
        {
            using var cmd = new SqlCommand("SELECT * FROM dbo.RegExMatches('hellomyworld', 'l+')", Conn);
            using var reader = cmd.ExecuteReader();
            Assert.IsTrue(reader.Read());
            var val = reader.GetSqlString(0);
            Assert.AreEqual("ll", val);
            Assert.IsTrue(reader.Read());
            val = reader.GetSqlString(0);
            Assert.AreEqual("l", val);
            Assert.IsFalse(reader.Read());
        }

        [TestMethod]
        public void TestRegExMatchesWithOptions()
        {
            using var cmd = new SqlCommand("SELECT * FROM dbo.RegExMatchesWithOptions('heLLomyworld', 'l+', 1)", Conn);
            using var reader = cmd.ExecuteReader();
            Assert.IsTrue(reader.Read());
            var val = reader.GetSqlString(0);
            Assert.AreEqual("LL", val);
            Assert.IsTrue(reader.Read());
            val = reader.GetSqlString(0);
            Assert.AreEqual("l", val);
            Assert.IsFalse(reader.Read());
        }

        [TestMethod]
        public void TestRegExMatchesGroup()
        {
            using var cmd = new SqlCommand("SELECT * FROM dbo.RegExMatchesGroup('hellomyworld', '(l+)', 1)", Conn);
            using var reader = cmd.ExecuteReader();
            Assert.IsTrue(reader.Read());
            var val = reader.GetSqlString(0);
            Assert.AreEqual("ll", val);
            Assert.IsTrue(reader.Read());
            val = reader.GetSqlString(0);
            Assert.AreEqual("l", val);
            Assert.IsFalse(reader.Read());
        }

        [TestMethod]
        public void TestRegExMatchesGroupsWithOptions()
        {
            using var cmd = new SqlCommand("SELECT * FROM dbo.RegExMatchesGroupsWithOptions('hellomyworld', '(l+)', 1)", Conn);
            using var reader = cmd.ExecuteReader();
            Assert.IsTrue(reader.Read());
            var val = reader.GetSqlString(3);
            Assert.AreEqual("ll", val);
            Assert.IsTrue(reader.Read());
            Assert.IsTrue(reader.Read());
            val = reader.GetSqlString(3);
            Assert.AreEqual("l", val);
            Assert.IsTrue(reader.Read());
            Assert.IsFalse(reader.Read());
        }

        [TestMethod]
        public void TestRegExMatchesGroups()
        {
            using var cmd = new SqlCommand("SELECT * FROM dbo.RegExMatchesGroups('hellomyworld', '(l+)')", Conn);
            using var reader = cmd.ExecuteReader();
            Assert.IsTrue(reader.Read());
            var val = reader.GetSqlString(3);
            Assert.AreEqual("ll", val);
            Assert.IsTrue(reader.Read());
            Assert.IsTrue(reader.Read());
            val = reader.GetSqlString(3);
            Assert.AreEqual("l", val);
            Assert.IsTrue(reader.Read());
            Assert.IsFalse(reader.Read());
        }

        [TestMethod]
        public void TestRegExMatchesGroupWithOptions()
        {
            using var cmd = new SqlCommand("SELECT * FROM dbo.RegExMatchesGroupWithOptions('heLLomyworLd', '(l+)', 1, 1)", Conn);
            using var reader = cmd.ExecuteReader();
            Assert.IsTrue(reader.Read());
            var val = reader.GetSqlString(0);
            Assert.AreEqual("LL", val);
            Assert.IsTrue(reader.Read());
            val = reader.GetSqlString(0);
            Assert.AreEqual("L", val);
            Assert.IsFalse(reader.Read());
        }

        [TestMethod]
        public void TestRegExParallelStressMatch()
        {
            const int parallelLevel = 8;
            const int loopCount = 10000;

            var loopRegExAction = new Action(() =>
            {
                using var conn = new SqlConnection(Settings.Default.ConnectionString);
                conn.Open();
                using var cmd = new SqlCommand("SELECT dbo.RegExMatch('hello', 'hel+o')", conn);
                using var cmd2 = new SqlCommand("SELECT dbo.RegExMatch('hello', 'world')", conn);
                for (var i = 0; i < loopCount; i++)
                {
                    Assert.AreEqual("hello", (string)cmd.ExecuteScalar());
                    Assert.AreEqual("", (string)cmd2.ExecuteScalar());
                }
            });

            var stopWatch = Stopwatch.StartNew();
            Parallel.Invoke(Enumerable.Repeat(loopRegExAction, parallelLevel).ToArray());
            stopWatch.Stop();

            Assert.IsTrue(stopWatch.ElapsedMilliseconds < loopCount + 6000, $"Elapsed time should be lesser than {loopCount + 6000}ms");
            using var cmd3 = new SqlCommand("SELECT dbo.RegExCachedCount()", Conn);
            Assert.IsTrue((int)cmd3.ExecuteScalar() > 1, "(int)cmd2.ExecuteScalar() > 1");
            using var cmd4 = new SqlCommand("SELECT dbo.RegExExecCount()", Conn);
            Assert.IsTrue((long)cmd4.ExecuteScalar() >= parallelLevel * loopCount * 2, $"(int)cmd2.ExecuteScalar() > {parallelLevel * loopCount * 2}");
        }

        [TestMethod]
        public void TestRegExStatsAndCaching()
        {
            using var cmd3 = new SqlCommand("SELECT dbo.RegExClearCache()", Conn);
            using var cmd7 = new SqlCommand("SELECT dbo.RegExResetCacheHitCount()", Conn);
            cmd3.ExecuteScalar();
            cmd7.ExecuteScalar();
            using var cmd = new SqlCommand("SELECT dbo.RegExIsMatch('hello', 'hello')", Conn);
            Assert.IsTrue((bool)cmd.ExecuteScalar());
            using var cmd6 = new SqlCommand("SELECT dbo.RegExCacheHitCount()", Conn);
            Assert.AreEqual(0, (long)cmd6.ExecuteScalar());
            Assert.IsTrue((bool)cmd.ExecuteScalar());
            Assert.AreNotEqual(0, (long)cmd6.ExecuteScalar());
            using var cmd2 = new SqlCommand("SELECT dbo.RegExCachedCount()", Conn);
            Assert.AreNotEqual(0, (int)cmd2.ExecuteScalar());
            Assert.AreNotEqual(0, (int)cmd3.ExecuteScalar());
            Assert.AreEqual(0, (int)cmd2.ExecuteScalar());
            Assert.IsTrue((bool)cmd.ExecuteScalar());
            Assert.IsTrue((bool)cmd.ExecuteScalar());
            Assert.AreEqual(1, (int)cmd2.ExecuteScalar());
            using var cmd4 = new SqlCommand("SELECT dbo.RegExExecCount()", Conn);
            Assert.AreNotEqual(0, (long)cmd4.ExecuteScalar());
            using var cmd5 = new SqlCommand("SELECT dbo.RegExResetExecCount()", Conn);
            Assert.AreNotEqual(0, (long)cmd5.ExecuteScalar());
            Assert.AreEqual(0, (long)cmd4.ExecuteScalar());
            using var cmd8 = new SqlCommand("SELECT * FROM dbo.RegExCacheList()", Conn);
            using var reader = cmd8.ExecuteReader();
            Assert.IsTrue(reader.Read());
            Assert.AreEqual("hello", reader.GetString(0));
            Assert.AreEqual(0, reader.GetInt32(1));
            Assert.AreEqual(1, reader.GetInt32(2));
        }

#if DEBUG
        [TestMethod]
#endif
        public void TestMethodBasicForceExpire()
        {
            using var cmd = new SqlCommand("SELECT dbo.RegExClearCache()", Conn);
            cmd.ExecuteNonQuery();
            using var cmd4 = new SqlCommand("SELECT dbo.RegExSetCacheEntryExpirationMilliseconds(1200)", Conn);
            Assert.AreNotEqual(0, cmd4.ExecuteNonQuery());
            using var cmd2 = new SqlCommand("SELECT dbo.RegExIsMatch('hello', 'll')", Conn);
            Assert.IsTrue((bool)cmd2.ExecuteScalar());
            using var cmd3 = new SqlCommand("SELECT dbo.RegExCachedCount()", Conn);
            Assert.AreNotEqual(0, (int)cmd3.ExecuteScalar());
            Thread.Sleep(1000);
            Assert.AreNotEqual(0, (int)cmd3.ExecuteScalar());
            Thread.Sleep(2000);
            Assert.AreEqual(0, (int)cmd3.ExecuteScalar());
            Thread.Sleep(2000);

            // Let's ensure now that cleaner process started again
            Assert.IsTrue((bool)cmd2.ExecuteScalar());
            Assert.AreNotEqual(0, (int)cmd3.ExecuteScalar());
            Thread.Sleep(1000);
            Assert.AreNotEqual(0, (int)cmd3.ExecuteScalar());
            Thread.Sleep(2000);
            Assert.AreEqual(0, (int)cmd3.ExecuteScalar());
        }
    }
}
