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
using Ascentis.Infrastructure;
using Timer = System.Timers.Timer;

#if UPLOCK
using AdamMil.Utilities;
#endif

[SuppressMessage("ReSharper", "CheckNamespace")]
public class RegExCompiled
{
    private const string SingleStringTableDef = "Str nvarchar(max)";
    private const string StringsTableDef = @"
        MatchNum int,
        GrpNum int,
        GrpName nvarchar(255),
        Item nvarchar(max)";
    private const string CachedRegExTableDef = @"
        Pattern nvarchar(max), 
        Options int, 
        RegExCacheCount int,
        Ttl int";
#if DEBUG
    private const int DefaultExpirationMilliseconds = 2000;
    private const int CleanerTimerInterval = 100;
#else
    private const int DefaultExpirationMilliseconds = 60000 * 5; // Five minutes
    private const int CleanerTimerInterval = 10000; // Ten seconds
#endif

#if UPLOCK
    private static readonly UpgradableReadWriteLock RegexPoolLock;
    private static readonly IDictionary<RegexKey, PooledRegexBag> RegexPool;
#else
    private static readonly ConcurrentDictionary<RegexKey, PooledRegexBag> RegexPool;
#endif

    /* Stats tracking fields */
    private static long _execCount;
    private static long _cacheHitCount;
    private static long _regExExceptionCount;

    /* RegEx cache expiration tracking related fields */
    private static readonly Timer CleanerTimer;
    private static int _lastCacheCleanerRunTickCount;
    private static volatile int _lastCacheUsedMilliseconds;
    private static volatile int _cacheEntryExpirationMilliseconds = DefaultExpirationMilliseconds;

    internal class RegexKey : Tuple<string, RegexOptions>
    {
        internal RegexKey(string pattern, RegexOptions options) : base(pattern, options) { }
        internal string Pattern => Item1;
        internal RegexOptions Options => Item2;
    }

    static RegExCompiled()
    {
#if UPLOCK
        RegexPoolLock = new UpgradableReadWriteLock();
        RegexPool = new Dictionary<RegexKey, PooledRegexBag>();
#else
        RegexPool = new ConcurrentDictionary<RegexKey, PooledRegexBag>();
#endif
        CleanerTimer = new Timer {Interval = CleanerTimerInterval};
        BuildCacheCleanerTimerDelegate();
    }

    private static void BuildCacheCleanerTimerDelegate()
    {
        var inCleanerCode = false;
        CleanerTimer.Elapsed += delegate
        {
            /* Nasty check to prevent re-entrancy. Timers in AutoReset mode ARE re-entrant */
            if (inCleanerCode)
                return;
            inCleanerCode = true;
            try
            {
                var currentTickCount = Environment.TickCount;
                if (_lastCacheCleanerRunTickCount == 0)
                {
                    _lastCacheCleanerRunTickCount = currentTickCount;
                    return; // Skip first run checks
                }
#if UPLOCK
                using var lockReleaser = RegexPoolLock.EnterRead();
#endif
                var removeTargets = new List<RegexKey>();
                foreach (var regExBagCachedItem in RegexPool)
                {
                    regExBagCachedItem.Value.ExpireTimeSpan = TimeSpan.FromMilliseconds(
                        regExBagCachedItem.Value.ExpireTimeSpan.TotalMilliseconds -
                        Math.Abs(currentTickCount - _lastCacheCleanerRunTickCount));
                    if (regExBagCachedItem.Value.ExpireTimeSpan.Ticks > 0)
                        continue;
                    removeTargets.Add(regExBagCachedItem.Key);
                }

                if (removeTargets.Count > 0)
                {
#if UPLOCK
                    lockReleaser.Upgrade();
#endif
                    foreach (var regExBagCacheItemKey in removeTargets)
                    {
#if UPLOCK
                        RegexPool.Remove(regExBagCacheItemKey);
#else
                        RegexPool.TryRemove(regExBagCacheItemKey, out var _);
#endif
                    }
                }

                _lastCacheCleanerRunTickCount = currentTickCount;
                CheckCleanerTimerShouldStop(currentTickCount);
            }
            finally
            {
                inCleanerCode = false;
            }
        };
    }

    private static void CheckCleanerTimerShouldStop(int currentTickCount)
    {
        if (Math.Abs(currentTickCount - _lastCacheUsedMilliseconds) < DefaultExpirationMilliseconds * 2) 
            return;
        _lastCacheCleanerRunTickCount = 0;
        CleanerTimer.Stop();
    }

    private static void CheckCleanerTimerStarted()
    {
        _lastCacheUsedMilliseconds = Environment.TickCount;
        if (!CleanerTimer.Enabled)
            CleanerTimer.Start();
    }

    protected class PooledRegexBag : ConcurrentStackedBagSlim<PooledRegex>
    {
        private readonly SpinLockedField<TimeSpan> _expireTimeSpan;
        public TimeSpan ExpireTimeSpan
        {
            get => _expireTimeSpan.Get();
            set => _expireTimeSpan.Set(value);
        }

        internal PooledRegexBag()
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
        private readonly PooledRegexBag _bag;

        internal PooledRegex(string pattern, PooledRegexBag bag, RegexOptions options) 
            : base(pattern, RegexOptions.Compiled | options)
        {
            _bag = bag;
        }

        public void Dispose()
        {
            _bag.Add(this);
        }
    }

    protected static PooledRegex RegexAcquire(string pattern, RegexOptions options = 0)
    {
        CheckCleanerTimerStarted();
        Interlocked.Increment(ref _execCount);
        var bag = GetPooledRegexBag(pattern, options);
        if (!bag.TryTake(out var regex))
            regex = new PooledRegex(pattern, bag, options);
        else
            Interlocked.Increment(ref _cacheHitCount);
        return regex;
    }

    private static PooledRegexBag GetPooledRegexBag(string pattern, RegexOptions options)
    {
#if UPLOCK
        PooledRegexBag bag;
        using var lockReleaser = RegexPoolLock.EnterRead();
        while (true)
        {
            var key = new RegexKey(pattern, options);
            if (RegexPool.TryGetValue(key, out bag))
                break;
            var firstUpgrader = lockReleaser.Upgrade();
            if (!firstUpgrader && RegexPool.TryGetValue(key, out bag))
                break;
            bag = new PooledRegexBag();
            RegexPool.Add(key, bag);
            break;
        }
#else
        var bag = RegexPool.GetOrAdd(new RegexKey(pattern, options), _ => new PooledRegexBag());
#endif
        bag.Accessed();
        return bag;
    }

    public static void FillRowSingleString(object row, out SqlString str)
    {
        str = new SqlString((string)row);
    }

    internal class StringsRow
    {
        internal int MatchNum;
        internal int GrpNum;
        internal string GrpName;
        internal string Item;
    }

    public static void FillGroupMatch(object row, 
        out int matchNum,
        out int grpNum,
        out string grpName,
        out SqlString item)
    {
        var stringsRow = (StringsRow) row;
        matchNum = stringsRow.MatchNum;
        grpNum = stringsRow.GrpNum;
        grpName = stringsRow.GrpName;
        item = new SqlString(stringsRow.Item);
    }

    internal class CachedRegExEntry
    {
        internal string Pattern;
        internal int Options;
        internal int Count;
        internal int Ttl;
    }

    public static void FillRowCachedRegEx(
        object row, 
        out SqlString pattern, 
        out int options, 
        out int cacheCount,
        out int ttl)
    {
        var cachedRegExEntry = (CachedRegExEntry) row;
        pattern = new SqlString(cachedRegExEntry.Pattern);
        options = cachedRegExEntry.Options;
        cacheCount = cachedRegExEntry.Count;
        ttl = cachedRegExEntry.Ttl;
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
        FillRowMethodName = nameof(FillRowSingleString), 
        TableDefinition = SingleStringTableDef)]
    public static IEnumerable RegExCompiledSplit(
        string input, string pattern)
    {
        return RegExCompiledSplitWithOptions(input, pattern, 0);
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true, 
        FillRowMethodName = nameof(FillRowSingleString), 
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
        return RegExApiCall(() => 
        {
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
        FillRowMethodName = nameof(FillRowSingleString), 
        TableDefinition = SingleStringTableDef)]
    public static IEnumerable RegExCompiledMatches(
        string input, string pattern)
    {
        return RegExCompiledMatchesWithOptions(input, pattern, 0);
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true, 
        FillRowMethodName = nameof(FillRowSingleString), 
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
        FillRowMethodName = nameof(FillRowSingleString), 
        TableDefinition = SingleStringTableDef)]
    public static IEnumerable RegExCompiledMatchesGroup(
        string input, string pattern, int group)
    {
        return RegExCompiledMatchesGroupWithOptions(input, pattern, group, 0);
    }

    [SqlFunction(
        IsDeterministic = true, 
        IsPrecise = true, 
        FillRowMethodName = nameof(FillRowSingleString), 
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
        IsPrecise = true,
        FillRowMethodName = nameof(FillGroupMatch),
        TableDefinition = StringsTableDef)]
    public static IEnumerable RegExCompiledMatchesGroups(
        string input, string pattern)
    {
        return RegExCompiledMatchesGroupsWithOptions(input, pattern, 0);
    }

    [SqlFunction(
        IsDeterministic = true,
        IsPrecise = true,
        FillRowMethodName = nameof(FillGroupMatch),
        TableDefinition = StringsTableDef)]
    public static IEnumerable RegExCompiledMatchesGroupsWithOptions(
        string input, string pattern, int options)
    {
        return RegExApiCall(() =>
        {
            using var regex = RegexAcquire(pattern, (RegexOptions)options);
            var matchesList = new List<StringsRow>();
            var matchNumber = 0;
            foreach (Match match in regex.Matches(input))
            {
                var grpNumber = 0;
                matchesList.AddRange(
                    from Group grpMatch in match.Groups 
                    select new StringsRow
                    {
                        MatchNum = matchNumber,
                        GrpName = regex.GroupNameFromNumber(grpNumber),
                        GrpNum = grpNumber++,
                        Item = grpMatch.Value
                    });
                matchNumber++;
            } 
            return matchesList;
        });
    }

    [SqlFunction(IsPrecise = true)]
    public static int RegExCachedCount()
    {
#if UPLOCK
        using var lockReleaser = RegexPoolLock.EnterRead();
#endif
        return RegexPool.Sum(bag => bag.Value.Count);
    }

    [SqlFunction(IsPrecise = true)]
    public static int RegExClearCache()
    {
        var cnt = RegexPool.Count;
#if UPLOCK
        using var lockReleaser = RegexPoolLock.EnterWrite();
#endif
        RegexPool.Clear();
        return cnt;
    }

    [SqlFunction(IsPrecise = true)]
    public static long RegExExecCount()
    {
        return Interlocked.Read(ref _execCount);
    }

    [SqlFunction(IsPrecise = true)]
    public static long RegExCacheHitCount()
    {
        return Interlocked.Read(ref _cacheHitCount);
    }

    [SqlFunction(IsPrecise = true)]
    public static long RegExExceptionCount()
    {
        return Interlocked.Read(ref _regExExceptionCount);
    }

    [SqlFunction(IsPrecise = true)]
    public static long RegExResetExecCount()
    {
        return Interlocked.Exchange(ref _execCount, 0);
    }

    [SqlFunction(IsPrecise = true)]
    public static long RegExResetCacheHitCount()
    {
        return Interlocked.Exchange(ref _cacheHitCount, 0);
    }

    [SqlFunction(IsPrecise = true)]
    public static long RegExResetExceptionCount()
    {
        return Interlocked.Exchange(ref _regExExceptionCount, 0);
    }

    [SqlFunction(IsPrecise = true)]
    public static int RegExSetCacheEntryExpirationMilliseconds(int cacheEntryExpirationMilliseconds)
    {
        return Interlocked.Exchange(ref _cacheEntryExpirationMilliseconds, cacheEntryExpirationMilliseconds);
    }

    [SqlFunction(
        IsPrecise = true,
        FillRowMethodName = nameof(FillRowCachedRegEx),
        TableDefinition = CachedRegExTableDef)]
    public static IEnumerable RegExCacheList()
    {
        return RegexPool.Select(regExCacheEntry => new CachedRegExEntry
        {
            Pattern = regExCacheEntry.Key.Pattern,
            Options = (int) regExCacheEntry.Key.Options,
            Count = regExCacheEntry.Value.Count,
            Ttl = (int)regExCacheEntry.Value.ExpireTimeSpan.TotalMilliseconds
        });
    }

    #endregion
}