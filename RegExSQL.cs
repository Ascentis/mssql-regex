﻿using System;
using System.Collections;
using System.Data.SqlTypes;
using System.Linq;
using Microsoft.SqlServer.Server;
using System.Text.RegularExpressions;

public class RegExCompiled
{
    public static void FillRow(object row, out SqlString str)
    {
        str = new SqlString((string)row);
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static bool RegExCompiledIsMatch(string input, string pattern)
    {
        return Regex.Match(input, pattern, RegexOptions.Compiled).Success;
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static string RegExCompiledReplace(string input, string pattern, string replacement)
    {
        return Regex.Replace(input, pattern, replacement, RegexOptions.Compiled);
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true, FillRowMethodName="FillRow", TableDefinition="STR NVARCHAR(MAX)")]
    public static IEnumerable RegExCompiledSplit(string input, string pattern)
    {
        return Regex.Split(input, pattern, RegexOptions.Compiled);
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
        return Regex.Match(input, pattern, RegexOptions.Compiled).Value;
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static string RegExCompiledMatchIndexed(string input, string pattern, int index)
    {
        var matches = Regex.Matches(input, pattern, RegexOptions.Compiled);
        return index >= matches.Count ? "" : matches[index].Value;
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static string RegExCompiledMatchGroup(string input, string pattern, int group)
    {
        return Regex.Match(input, pattern, RegexOptions.Compiled).Groups[group].Value;
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true)]
    public static string RegExCompiledMatchGroupIndexed(string input, string pattern, int group, int index)
    {
        var matches = Regex.Matches(input, pattern, RegexOptions.Compiled);
        return index >= matches.Count ? "" : matches[index].Groups[group].Value;
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true, FillRowMethodName="FillRow", TableDefinition="STR NVARCHAR(MAX)")]
    public static IEnumerable RegExCompiledMatches(string input, string pattern)
    {
        return Regex.Matches(input, pattern).Cast<Match>().Select(m => m.Value).ToArray();
    }

    [SqlFunction(IsDeterministic = true, IsPrecise = true, FillRowMethodName = "FillRow", TableDefinition = "STR NVARCHAR(MAX)")]
    public static IEnumerable RegExCompiledMatchesGroup(string input, string pattern, int group)
    {
        return Regex.Matches(input, pattern).Cast<Match>().Select(m => m.Groups[group].Value).ToArray();
    }
};