using System;
using System.Collections;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using Microsoft.SqlServer.Server;
using System.Text.RegularExpressions;
using System.Threading;
using AdamMil.Utilities;

[SuppressMessage("ReSharper", "CheckNamespace")]
public class RegExCompiled
{
    // Faster by about 12% to use a regular Dictionary<> with a UpgradableReadWriteLock than a ConcurrentDictionary<>
    private static readonly UpgradableReadWriteLock RegexPoolLock;
    private static readonly IDictionary<string, ConcurrentStack<PooledRegex>> RegexPool;
    private static volatile int _execCount;

    static RegExCompiled()
    {
        RegexPoolLock = new UpgradableReadWriteLock();
        RegexPool = new Dictionary<string, ConcurrentStack<PooledRegex>>();
    }

    protected class PooledRegex : Regex, IDisposable
    {
        private readonly ConcurrentStack<PooledRegex> _stack;

        internal PooledRegex(string pattern, ConcurrentStack<PooledRegex> stack) : base(pattern, RegexOptions.Compiled)
        {
            _stack = stack;
        }

        public void Dispose()
        {
            _stack.Push(this);
        }
    }

    protected static PooledRegex RegexAcquire(string pattern)
    {
        Interlocked.Increment(ref _execCount);
        var stack = GetPooledRegexStack(pattern);
        if (!stack.TryPop(out var regex))
            regex = new PooledRegex(pattern, stack);
        return regex;
    }

    private static ConcurrentStack<PooledRegex> GetPooledRegexStack(string pattern)
    {
        ConcurrentStack<PooledRegex> stack;
        using var lockReleaser = RegexPoolLock.EnterRead();
        while (true)
        {
            if (RegexPool.TryGetValue(pattern, out stack)) 
                break;
            var firstUpgrader = RegexPoolLock.Upgrade();
            try
            {
                if (!firstUpgrader && RegexPool.TryGetValue(pattern, out stack))
                    break;
                stack = new ConcurrentStack<PooledRegex>();
                RegexPool.Add(pattern, stack);
                break;
            }
            finally
            {
                RegexPoolLock.Downgrade();
            }
        }

        return stack;
    }

    public static void FillRow(object row, out SqlString str)
    {
        str = new SqlString((string)row);
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static bool RegExCompiledIsMatch(string input, string pattern)
    {
        using var regex = RegexAcquire(pattern);
        return regex.Match(input).Success;
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static string RegExCompiledReplace(string input, string pattern, string replacement)
    {
        using var regex = RegexAcquire(pattern);
        return regex.Replace(input, replacement);
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static string RegExCompiledReplaceCount(string input, string pattern, string replacement, int count)
    {
        using var regex = RegexAcquire(pattern);
        return regex.Replace(input, replacement, count);
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true, FillRowMethodName="FillRow", TableDefinition="STR NVARCHAR(MAX)")]
    public static IEnumerable RegExCompiledSplit(string input, string pattern)
    {
        using var regex = RegexAcquire(pattern);
        return regex.Split(input);
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static string RegExCompiledEscape(string input)
    {
        return Regex.Escape(input);
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static string RegExCompiledUnescape(string input)
    {
        return Regex.Unescape(input);
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static string RegExCompiledMatch(string input, string pattern)
    {
        using var regex = RegexAcquire(pattern);
        return regex.Match(input).Value;
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static string RegExCompiledMatchIndexed(string input, string pattern, int index)
    {
        using var regex = RegexAcquire(pattern);
        var matches = regex.Matches(input);
        return index >= matches.Count ? "" : matches[index].Value;
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static string RegExCompiledMatchGroup(string input, string pattern, int group)
    {
        using var regex = RegexAcquire(pattern);
        return regex.Match(input).Groups[group].Value;
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static string RegExCompiledMatchGroupIndexed(string input, string pattern, int group, int index)
    {
        using var regex = RegexAcquire(pattern);
        var matches = regex.Matches(input);
        return index >= matches.Count ? "" : matches[index].Groups[group].Value;
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true, FillRowMethodName="FillRow", TableDefinition="STR NVARCHAR(MAX)")]
    public static IEnumerable RegExCompiledMatches(string input, string pattern)
    {
        using var regex = RegexAcquire(pattern);
        return regex.Matches(input).Cast<Match>().Select(m => m.Value).ToArray();
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true, FillRowMethodName = "FillRow", TableDefinition = "STR NVARCHAR(MAX)")]
    public static IEnumerable RegExCompiledMatchesGroup(string input, string pattern, int group)
    {
        using var regex = RegexAcquire(pattern);
        return regex.Matches(input).Cast<Match>().Select(m => m.Groups[group].Value).ToArray();
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static int RegExCachedCount()
    {
        using var lockReleaser = RegexPoolLock.EnterRead();
        return RegexPool.Sum(stack => stack.Value.Count);
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static int RegExClearCache()
    {
        var cnt = RegexPool.Count;
        using var lockReleaser = RegexPoolLock.EnterWrite();
        RegexPool.Clear();
        return cnt;
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static int RegExExecCount()
    {
        return _execCount;
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static int RegExResetExecCount()
    {
        var cnt = _execCount;
        _execCount = 0;
        return cnt;
    }
}