using System;
using System.Data.SqlClient;
using System.IO;
using System.Threading.Tasks;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using UnitTestRegExSQL.Properties;

namespace UnitTestRegExSQL
{
    [TestClass]
    public class UnitTestRegExSql
    {
        private static readonly SqlConnection Conn;

        static UnitTestRegExSql()
        {
            Conn = new SqlConnection(Settings.Default.ConnectionString);
            Conn.Open();
            var regAssemblyCommands = File.ReadAllText(@"..\..\Published\CreateRegExAssembly.sql").Split(new [] {"GO\r\n"}, StringSplitOptions.RemoveEmptyEntries);
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
        public void TestRegExReplace()
        {
            using var cmd = new SqlCommand("SELECT dbo.RegExReplace('hello my world', 'my', 'your')", Conn);
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
        public void TestRegExMatchIndexed()
        {
            using var cmd = new SqlCommand("SELECT dbo.RegExMatchIndexed('hello helllo', 'hel+o', 1)", Conn);
            Assert.AreEqual("helllo", (string)cmd.ExecuteScalar());
        }

        [TestMethod]
        public void TestRegExMatchGroup()
        {
            using var cmd = new SqlCommand("SELECT dbo.RegExMatchGroup('hello', 'he(ll)o', 1)", Conn);
            Assert.AreEqual("ll", (string)cmd.ExecuteScalar());
        }

        [TestMethod]
        public void TestRegExMatchGroupIndexed()
        {
            using var cmd = new SqlCommand("SELECT dbo.RegExMatchGroupIndexed('hello helllo', 'he(l*)o', 1, 1)", Conn);
            Assert.AreEqual("lll", (string)cmd.ExecuteScalar());
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
        public void TestRegExParallelMatch()
        {
            var loopRegExAction = new Action(() =>
            {
                using var conn = new SqlConnection(Settings.Default.ConnectionString);
                conn.Open();
                for (var i = 0; i < 1000; i++)
                {
                    using var cmd = new SqlCommand("SELECT dbo.RegExMatch('hello', 'hel+o')", conn);
                    Assert.AreEqual("hello", (string)cmd.ExecuteScalar());
                    using var cmd2 = new SqlCommand("SELECT dbo.RegExMatch('hello', 'world')", conn);
                    Assert.AreEqual("", (string)cmd2.ExecuteScalar());
                }
            });
            Parallel.Invoke(loopRegExAction, loopRegExAction, loopRegExAction, loopRegExAction);
            using var cmd3 = new SqlCommand("SELECT dbo.RegExCachedCount()", Conn);
            Assert.IsTrue((int)cmd3.ExecuteScalar() > 1, "(int)cmd2.ExecuteScalar() > 1");
            using var cmd4 = new SqlCommand("SELECT dbo.RegExExecCount()", Conn);
            Assert.IsTrue((int)cmd4.ExecuteScalar() >= 8000, "(int)cmd2.ExecuteScalar() > 8000");
        }

        [TestMethod]
        public void TestRegExStatsAndCaching()
        {
            using var cmd = new SqlCommand("SELECT dbo.RegExIsMatch('hello', 'hello')", Conn);
            Assert.IsTrue((bool)cmd.ExecuteScalar());
            using var cmd2 = new SqlCommand("SELECT dbo.RegExCachedCount()", Conn);
            Assert.AreNotEqual(0, (int)cmd2.ExecuteScalar());
            using var cmd3 = new SqlCommand("SELECT dbo.RegExClearCache()", Conn);
            Assert.AreNotEqual(0, (int)cmd3.ExecuteScalar());
            Assert.AreEqual(0, (int)cmd2.ExecuteScalar());
            Assert.IsTrue((bool)cmd.ExecuteScalar());
            Assert.IsTrue((bool)cmd.ExecuteScalar());
            Assert.AreEqual(1, (int)cmd2.ExecuteScalar());
            using var cmd4 = new SqlCommand("SELECT dbo.RegExExecCount()", Conn);
            Assert.AreNotEqual(0, (int)cmd4.ExecuteScalar());
            using var cmd5 = new SqlCommand("SELECT dbo.RegExResetExecCount()", Conn);
            Assert.AreNotEqual(0, (int)cmd5.ExecuteScalar());
            Assert.AreEqual(0, (int)cmd4.ExecuteScalar());
        }
    }
}
