using System.Collections;
using System.Collections.Concurrent;
using System.Data.SqlTypes;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using Microsoft.SqlServer.Server;
using System.Text.RegularExpressions;

[SuppressMessage("ReSharper", "InconsistentNaming")]
[SuppressMessage("ReSharper", "CheckNamespace")]
[SuppressMessage("ReSharper", "UnusedMember.Global")]
public class RegExCompiled
{
    private static readonly ConcurrentDictionary<string, ConcurrentStack<Regex>> RegexCache = new ConcurrentDictionary<string, ConcurrentStack<Regex>>();

    private static ConcurrentStack<Regex> GetRegexStack(string pattern)
    {
        return RegexCache.GetOrAdd(pattern, _ => new ConcurrentStack<Regex>());
    }

    private static Regex RegexAcquire(string pattern)
    {
        var stack = GetRegexStack(pattern);
        if (!stack.TryPop(out var regex))
            regex = new Regex(pattern, RegexOptions.Compiled);
        return regex;
    }

    private static void RegexRelease(string pattern, Regex regex)
    {
        var stack = GetRegexStack(pattern);
        stack.Push(regex);
    }

    public static void FillRow(object row, out SqlString str)
    {
        str = new SqlString((string)row);
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static bool RegExCompiledIsMatch(string input, string pattern)
    {
        var regex = RegexAcquire(pattern);
        try
        {
            return regex.Match(input).Success;
        }
        finally
        {
            RegexRelease(pattern, regex);
        }
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static string RegExCompiledReplace(string input, string pattern, string replacement)
    {
        var regex = RegexAcquire(pattern);
        try
        {
            return regex.Replace(input, replacement);
        }
        finally
        {
            RegexRelease(pattern, regex);
        }
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static string RegExCompiledReplaceCount(string input, string pattern, string replacement, int count)
    {
        var regex = RegexAcquire(pattern);
        try 
        {
            return regex.Replace(input, replacement, count);
        } 
        finally
        {
            RegexRelease(pattern, regex);
        }
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true, FillRowMethodName="FillRow", TableDefinition="STR NVARCHAR(MAX)")]
    public static IEnumerable RegExCompiledSplit(string input, string pattern)
    {
        var regex = RegexAcquire(pattern);
        try
        {
            return regex.Split(input);
        }
        finally
        {
            RegexRelease(pattern, regex);
        }
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
        var regex = RegexAcquire(pattern);
        try
        {
            return regex.Match(input).Value;
        }
        finally
        {
            RegexRelease(pattern, regex);
        }
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static string RegExCompiledMatchIndexed(string input, string pattern, int index)
    {
        var regex = RegexAcquire(pattern);
        try
        {
            var matches = regex.Matches(input);
            return index >= matches.Count ? "" : matches[index].Value;
        }
        finally
        {
            RegexRelease(pattern, regex);
        }
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static string RegExCompiledMatchGroup(string input, string pattern, int group)
    {
        var regex = RegexAcquire(pattern);
        try
        {
            return regex.Match(input).Groups[group].Value;
        }
        finally
        {
            RegexRelease(pattern, regex);
        }
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static string RegExCompiledMatchGroupIndexed(string input, string pattern, int group, int index)
    {
        var regex = RegexAcquire(pattern);
        try
        {
            var matches = regex.Matches(input);
            return index >= matches.Count ? "" : matches[index].Groups[group].Value;
        }
        finally
        {
            RegexRelease(pattern, regex);
        }
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true, FillRowMethodName="FillRow", TableDefinition="STR NVARCHAR(MAX)")]
    public static IEnumerable RegExCompiledMatches(string input, string pattern)
    {
        var regex = RegexAcquire(pattern);
        try
        {
            return regex.Matches(input).Cast<Match>().Select(m => m.Value).ToArray();
        }
        finally
        {
            RegexRelease(pattern, regex);
        }
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true, FillRowMethodName = "FillRow", TableDefinition = "STR NVARCHAR(MAX)")]
    public static IEnumerable RegExCompiledMatchesGroup(string input, string pattern, int group)
    {
        var regex = RegexAcquire(pattern);
        try
        {
            return regex.Matches(input).Cast<Match>().Select(m => m.Groups[group].Value).ToArray();
        }
        finally
        {
            RegexRelease(pattern, regex);
        }
    }
};