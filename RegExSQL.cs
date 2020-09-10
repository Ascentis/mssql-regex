using System;
using System.Collections;
using System.Collections.Concurrent;
using System.Data.SqlTypes;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using Microsoft.SqlServer.Server;
using System.Text.RegularExpressions;
using System.Threading;
using Ascentis.Infrastructure;
using Timer = System.Timers.Timer;

#if UPLOCK
using System.Collections.Generic;
using AdamMil.Utilities;
#endif

[SuppressMessage("ReSharper", "CheckNamespace")]
public class RegExCompiled
{
    private const string SingleStringTableDef = "STR NVARCHAR(MAX)";
#if DEBUG
    private const int DefaultExpirationMilliseconds = 2000;
    private const int CleanerTimerInterval = 100;
#else
    private const int DefaultExpirationMilliseconds = 60000 * 5; // Five minutes
    private const int CleanerTimerInterval = 10000; // Ten seconds
#endif

#if UPLOCK
    private static readonly UpgradableReadWriteLock RegexPoolLock;
    private static readonly IDictionary<RegexKey, PooledRegexStack> RegexPool;
#else
    private static readonly ConcurrentDictionary<RegexKey, PooledRegexStack> RegexPool;
#endif

    /* Stats tracking fields */
    private static long _execCount;
    private static long _cacheHitCount;
    private static long _regExExceptionCount;

    /* RegEx cache expiration tracking related fields */
    private static readonly Timer CleanerTimer;
    private static int _lastCacheCleanerRunTickCount;
    private static volatile int _cacheEntryExpirationMilliseconds = DefaultExpirationMilliseconds;

    private class RegexKey : Tuple<string, RegexOptions>
    {
        internal RegexKey(string pattern, RegexOptions options) : base(pattern, options) { }
    }

    static RegExCompiled()
    {
#if UPLOCK
        RegexPoolLock = new UpgradableReadWriteLock();
        RegexPool = new Dictionary<RegexKey, PooledRegexStack>();
#else
        RegexPool = new ConcurrentDictionary<RegexKey, PooledRegexStack>();
#endif
        CleanerTimer = new Timer();
        CleanerTimer.Elapsed += (_, e) =>
        {
            if (_lastCacheCleanerRunTickCount == 0)
                _lastCacheCleanerRunTickCount = Environment.TickCount;
#if UPLOCK
            using var lockReleaser = RegexPoolLock.EnterRead();
#endif
            foreach (var cache in RegexPool)
            {
                cache.Value.ExpireTimeSpan = TimeSpan.FromMilliseconds(
                    cache.Value.ExpireTimeSpan.TotalMilliseconds -
                    Math.Abs(Environment.TickCount - _lastCacheCleanerRunTickCount));
                if (cache.Value.ExpireTimeSpan.Ticks > 0)
                    continue;
#if UPLOCK
                lockReleaser.Upgrade();
                try
                {
                    RegexPool.Remove(cache.Key);
                }
                finally
                {
                    lockReleaser.Downgrade();
                }
#else
                RegexPool.TryRemove(cache.Key, out var _);
#endif
            }

            CheckCleanerTimerShouldStop();
            _lastCacheCleanerRunTickCount = Environment.TickCount;
        };
        CleanerTimer.Interval = CleanerTimerInterval;
    }

    private static void CheckCleanerTimerShouldStop()
    {
        if (Math.Abs(Environment.TickCount - _lastCacheCleanerRunTickCount) >= DefaultExpirationMilliseconds * 2)
            CleanerTimer.Stop();
    }

    private static void CheckCleanerTimerStarted()
    {
        if (!CleanerTimer.Enabled)
            CleanerTimer.Start();
    }

    /*
       Refrain from replacing parent class ConcurrentStack<> with ConcurrentBag<>.
       It looks like the pattern fits the bill, after all we don't care *which* Regex object we
       are provided as long as it's an object compiled with the same pattern and set of options.
       Well, it appears that due to the complex logic ConcurrentBag<> has internally to optimize
       for performance of the caller thread to Add() and Take() if there's either a lot changes
       in the running thread (flip/flopping threads) or if there's simply a lot of threads 
       the performance of it absolutely sucks when this is running in MSSQL context. 
       The degradation is simply beyond belief.
    */
    protected class PooledRegexStack : ConcurrentStack<PooledRegex>
    {
        private readonly SpinLockedField<TimeSpan> _expireTimeSpan;
        public TimeSpan ExpireTimeSpan
        {
            get => _expireTimeSpan.Get();
            set => _expireTimeSpan.Set(value);
        }

        internal PooledRegexStack()
        {
            _expireTimeSpan = new SpinLockedField<TimeSpan>();
            Accessed();
        }

        public void Accessed()
        {
            ExpireTimeSpan = TimeSpan.FromMilliseconds(_cacheEntryExpirationMilliseconds);
        }
    }

    protected class PooledRegex : Regex, IDisposable
    {
        private readonly PooledRegexStack _stack;

        internal PooledRegex(string pattern, PooledRegexStack stack, RegexOptions options) 
            : base(pattern, RegexOptions.Compiled | options)
        {
            _stack = stack;
        }

        public void Dispose()
        {
            _stack.Push(this);
        }
    }

    protected static PooledRegex RegexAcquire(string pattern, RegexOptions options = 0)
    {
        CheckCleanerTimerStarted();
        Interlocked.Increment(ref _execCount);
        var stack = GetPooledRegexStack(pattern, options);
        if (!stack.TryPop(out var regex))
            regex = new PooledRegex(pattern, stack, options);
        else
            Interlocked.Increment(ref _cacheHitCount);
        return regex;
    }

    private static PooledRegexStack GetPooledRegexStack(string pattern, RegexOptions options)
    {
#if UPLOCK
        PooledRegexStack stack;
        using var lockReleaser = RegexPoolLock.EnterRead();
        while (true)
        {
            var key = new RegexKey(pattern, options);
            if (RegexPool.TryGetValue(key, out stack))
                break;
            var firstUpgrader = lockReleaser.Upgrade();
            if (!firstUpgrader && RegexPool.TryGetValue(key, out stack))
                break;
            stack = new PooledRegexStack();
            RegexPool.Add(key, stack);
            break;
        }
#else
        var stack = RegexPool.GetOrAdd(new RegexKey(pattern, options), _ => new PooledRegexStack());
#endif
        stack.Accessed();
        return stack;
    }

    public static void FillRow(object row, out SqlString str)
    {
        str = new SqlString((string)row);
    }

    private delegate TRet RegExApiDelegate<out TRet>();
    private static TRet RegExApiCall<TRet>(RegExApiDelegate<TRet> apiCall)
    {
        try
        {
            return apiCall();
        }
        catch
        {
            Interlocked.Increment(ref _regExExceptionCount);
            throw;
        }
    }

    #region Functions exported to SQL

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true)]
    public static bool RegExCompiledIsMatchWithOptions(
        string input, string pattern, int options)
    {
        return RegExApiCall(() =>
        {
            using var regex = RegexAcquire(pattern, (RegexOptions) options);
            return regex.Match(input).Success;
        });
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true)]
    public static bool RegExCompiledIsMatch(
        string input, string pattern)
    {
        return RegExCompiledIsMatchWithOptions(input, pattern, 0);
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true)]
    public static string RegExCompiledReplace(
        string input, string pattern, string replacement)
    {
        return RegExCompiledReplaceWithOptions(input, pattern, replacement, 0);
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true)]
    public static string RegExCompiledReplaceWithOptions(
        string input, string pattern, string replacement, int options)
    {
        return RegExApiCall(() =>
        {
            using var regex = RegexAcquire(pattern, (RegexOptions) options);
            return regex.Replace(input, replacement);
        });
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true)]
    public static string RegExCompiledReplaceCount(
        string input, string pattern, string replacement, int count)
    {
        return RegExCompiledReplaceCountWithOptions(input, pattern, replacement, count, 0);
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true)]
    public static string RegExCompiledReplaceCountWithOptions(
        string input, string pattern, string replacement, int count, int options)
    {
        return RegExApiCall(() =>
        {
            using var regex = RegexAcquire(pattern, (RegexOptions) options);
            return regex.Replace(input, replacement, count);
        });
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true, 
        FillRowMethodName = nameof(FillRow), 
        TableDefinition = SingleStringTableDef)]
    public static IEnumerable RegExCompiledSplit(
        string input, string pattern)
    {
        return RegExCompiledSplitWithOptions(input, pattern, 0);
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true, 
        FillRowMethodName = nameof(FillRow), 
        TableDefinition = SingleStringTableDef)]
    public static IEnumerable RegExCompiledSplitWithOptions(
        string input, string pattern, int options)
    {
        return RegExApiCall(() =>
        {
            using var regex = RegexAcquire(pattern, (RegexOptions) options);
            return regex.Split(input);
        });
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true)]
    public static string RegExCompiledEscape(string input)
    {
        return Regex.Escape(input);
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true)]
    public static string RegExCompiledUnescape(string input)
    {
        return Regex.Unescape(input);
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true)]
    public static string RegExCompiledMatch(
        string input, string pattern)
    {
        return RegExCompiledMatchWithOptions(input, pattern, 0);
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true)]
    public static string RegExCompiledMatchWithOptions(
        string input, string pattern, int options)
    {
        return RegExApiCall(() =>
        {
            using var regex = RegexAcquire(pattern, (RegexOptions)options);
            return regex.Match(input).Value;
        });
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true)]
    public static string RegExCompiledMatchIndexed(
        string input, string pattern, int index)
    {
        return RegExCompiledMatchIndexedWithOptions(input, pattern, index, 0);
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true)]
    public static string RegExCompiledMatchIndexedWithOptions(
        string input, string pattern, int index, int options)
    {
        return RegExApiCall(()=> {
            using var regex = RegexAcquire(pattern, (RegexOptions) options);
            var matches = regex.Matches(input);
            return index >= matches.Count ? "" : matches[index].Value;
        });
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true)]
    public static string RegExCompiledMatchGroup(
        string input, string pattern, int group)
    {
        return RegExCompiledMatchGroupWithOptions(input, pattern, group, 0);
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true)]
    public static string RegExCompiledMatchGroupWithOptions(
        string input, string pattern, int group, int options)
    {
        return RegExApiCall(() =>
        {
            using var regex = RegexAcquire(pattern, (RegexOptions) options);
            return regex.Match(input).Groups[group].Value;
        });
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true)]
    public static string RegExCompiledMatchGroupIndexed(
        string input, string pattern, int group, int index)
    {
        return RegExCompiledMatchGroupIndexedWithOptions(input, pattern, group, index, 0);
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true)]
    public static string RegExCompiledMatchGroupIndexedWithOptions(
        string input, string pattern, int group, int index, int options)
    {
        return RegExApiCall(() =>
        {
            using var regex = RegexAcquire(pattern, (RegexOptions) options);
            var matches = regex.Matches(input);
            return index >= matches.Count ? "" : matches[index].Groups[group].Value;
        });
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true, 
        FillRowMethodName = nameof(FillRow), 
        TableDefinition = SingleStringTableDef)]
    public static IEnumerable RegExCompiledMatches(
        string input, string pattern)
    {
        return RegExCompiledMatchesWithOptions(input, pattern, 0);
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true, 
        FillRowMethodName = nameof(FillRow), 
        TableDefinition = SingleStringTableDef)]
    public static IEnumerable RegExCompiledMatchesWithOptions(
        string input, string pattern, int options)
    {
        return RegExApiCall(() =>
        {
            using var regex = RegexAcquire(pattern, (RegexOptions) options);
            return regex.Matches(input).Cast<Match>().Select(m => m.Value).ToArray();
        });
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true, 
        FillRowMethodName = nameof(FillRow), 
        TableDefinition = SingleStringTableDef)]
    public static IEnumerable RegExCompiledMatchesGroup(
        string input, string pattern, int group)
    {
        return RegExCompiledMatchesGroupWithOptions(input, pattern, group, 0);
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true, 
        FillRowMethodName = nameof(FillRow), 
        TableDefinition = SingleStringTableDef)]
    public static IEnumerable RegExCompiledMatchesGroupWithOptions(
        string input, string pattern, int group, int options)
    {
        return RegExApiCall(() =>
        {
            using var regex = RegexAcquire(pattern, (RegexOptions) options);
            return regex.Matches(input).Cast<Match>().Select(m => m.Groups[group].Value).ToArray();
        });
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true)]
    public static int RegExCachedCount()
    {
#if UPLOCK
        using var lockReleaser = RegexPoolLock.EnterRead();
#endif
        return RegexPool.Sum(stack => stack.Value.Count);
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true)]
    public static int RegExClearCache()
    {
        var cnt = RegexPool.Count;
#if UPLOCK
        using var lockReleaser = RegexPoolLock.EnterWrite();
#endif
        RegexPool.Clear();
        return cnt;
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true)]
    public static long RegExExecCount()
    {
        return Interlocked.Read(ref _execCount);
    }

    [SqlFunction(
        IsDeterministic = true,
        IsPrecise = true)]
    public static long RegExCacheHitCount()
    {
        return Interlocked.Read(ref _cacheHitCount);
    }

    [SqlFunction(
        IsDeterministic = true,
        IsPrecise = true)]
    public static long RegExExceptionCount()
    {
        return Interlocked.Read(ref _regExExceptionCount);
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true)]
    public static long RegExResetExecCount()
    {
        return Interlocked.Exchange(ref _execCount, 0);
    }

    [SqlFunction(
        IsDeterministic = true,
        IsPrecise = true)]
    public static long RegExResetCacheHitCount()
    {
        return Interlocked.Exchange(ref _cacheHitCount, 0);
    }

    [SqlFunction(
        IsDeterministic = true,
        IsPrecise = true)]
    public static long RegExResetExceptionCount()
    {
        return Interlocked.Exchange(ref _regExExceptionCount, 0);
    }

    [SqlFunction(
        IsDeterministic = true,
        IsPrecise = true)]
    public static int RegExSetCacheEntryExpirationMilliseconds(int cacheEntryExpirationMilliseconds)
    {
        return Interlocked.Exchange(ref _cacheEntryExpirationMilliseconds, cacheEntryExpirationMilliseconds);
    }

    #endregion
}