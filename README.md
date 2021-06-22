# mssql-regex

This package allows to use CLR RegEx class within MSSQL.

The package caches compiled Regex objects based on regex pattern and options parameter when specific version of the APIs is used.
Regex objects are taken from the cache, used and returned back to the cache. By default they have a TTL of 5 minutes.
There's an initial cost upon executing a new regex as the regex expression is compiled into intermediate language opcodes and cached for reuse.

The functions return either a scalar string value or they return a table of strings containing each match.

There's a cleanup timer that runs every 10 seconds and it will cleanup all regex stacks not used in the last 5 minutes.

The library provides a set of functions to inspect the status of the cache and the number of executions performed since the library was loaded.
Methods to reset the stats are provided.

For general reference on regular expression language as supported by Microsoft see: https://docs.microsoft.com/en-us/dotnet/standard/base-types/regular-expression-language-quick-reference

For reference on Regex class see: https://docs.microsoft.com/en-us/dotnet/api/system.text.regularexpressions.regex?view=netframework-4.6.1

Nuget repo with packaged up ready made .sql scripts: https://www.nuget.org/packages/Ascentis.RegExSQL/

IMPORTANT: Please notice when installing this package in production you will want to run the following command in your database:

```sql
GRANT UNSAFE ASSEMBLY TO "you_login"
```

It's also required to have CLR enabled in the target database:

```sql
EXEC sp_configure 'clr enabled', 1
RECONFIGURE
```

You need to run that command against all logins that may need to load this assembly, otherwise you will end up with warnings in the SQL logs each time this assembly is used given the fact it's marked unsafe.


### Functions exposed:

#### Matching functions returning a scalar value:
```sql
CREATE FUNCTION RegExIsMatch(
    @input nvarchar(max), 
    @pattern nvarchar(max)) RETURNS bit
CREATE FUNCTION RegExIsMatchWithOptions(
    @input nvarchar(max), 
    @pattern nvarchar(max), 
    @options int) RETURNS bit
CREATE FUNCTION RegExMatch(
    @input nvarchar(max), 
    @pattern nvarchar(max)) RETURNS nvarchar(max)
CREATE FUNCTION RegExMatchWithOptions(
    @input nvarchar(max), 
    @pattern nvarchar(max), 
    @options int) RETURNS nvarchar(max)
CREATE FUNCTION RegExMatchIndexed(
    @input nvarchar(max), 
    @pattern nvarchar(max), 
    @index int) RETURNS nvarchar(max)
CREATE FUNCTION RegExMatchIndexedWithOptions(
    @input nvarchar(max), 
    @pattern nvarchar(max), 
    @index int, 
    @options int) RETURNS nvarchar(max)
CREATE FUNCTION RegExMatchGroup(
    @input nvarchar(max),
    @pattern nvarchar(max),
    @group int) RETURNS nvarchar(max)
CREATE FUNCTION RegExMatchGroupWithOptions(
    @input nvarchar(max),
    @pattern nvarchar(max),
    @group int,
    @options int) RETURNS nvarchar(max)
CREATE FUNCTION RegExMatchGroupIndexed(
    @input nvarchar(max),
    @pattern nvarchar(max),
    @group int,
    @index int) RETURNS nvarchar(max)
CREATE FUNCTION RegExMatchGroupIndexedWithOptions(
    @input nvarchar(max),
    @pattern nvarchar(max),
    @group int,
    @index int,
    @options int) RETURNS nvarchar(max)
```

#### Replacement functions
```sql
CREATE FUNCTION RegExReplace(
    @input nvarchar(max),
    @pattern nvarchar(max),
    @replacement nvarchar(max)) RETURNS nvarchar(max)
CREATE FUNCTION RegExReplaceWithOptions(
    @input nvarchar(max),
    @pattern nvarchar(max),
    @replacement nvarchar(max),
    @options int) RETURNS nvarchar(max)
CREATE FUNCTION RegExReplaceCount(
    @input nvarchar(max),
    @pattern nvarchar(max),
    @replacement nvarchar(max),
    @count int) RETURNS nvarchar(max)
CREATE FUNCTION RegExReplaceCountWithOptions(
    @input nvarchar(max),
    @pattern nvarchar(max),
    @replacement nvarchar(max),
    @count int,
    @options int) RETURNS nvarchar(max)
```

#### String splitting functions
```sql
CREATE FUNCTION RegExSplit(
    @input nvarchar(max),
    @pattern nvarchar(max)) RETURNS TABLE (ITEM NVARCHAR(MAX))
CREATE FUNCTION RegExSplitWithOptions(
    @input nvarchar(max),
    @pattern nvarchar(max),
    @options int) RETURNS TABLE (ITEM NVARCHAR(MAX))
```

#### Matching functions returning all matches as a table
```sql
CREATE FUNCTION RegExMatches(
    @input nvarchar(max),
    @pattern nvarchar(max)) RETURNS TABLE (ITEM NVARCHAR(MAX))
CREATE FUNCTION RegExMatchesWithOptions(
    @input nvarchar(max),
    @pattern nvarchar(max),
    @options int) RETURNS TABLE (ITEM NVARCHAR(MAX))
CREATE FUNCTION RegExMatchesGroup(
    @input nvarchar(max),  
    @pattern nvarchar(max),
    @group int) RETURNS TABLE (ITEM NVARCHAR(MAX))
CREATE FUNCTION RegExMatchesGroups(
    @input nvarchar(max),  
    @pattern nvarchar(max)) RETURNS TABLE (
        MatchNum int,
        GrpNum int,
        GrpName nvarchar(255),
        Item NVARCHAR(MAX))
CREATE FUNCTION RegExMatchesGroupWithOptions(
    @input nvarchar(max),
    @pattern nvarchar(max),
    @group int,
    @options int) RETURNS TABLE (ITEM NVARCHAR(MAX))
CREATE FUNCTION RegExMatchesGroupsWithOptions(
    @input nvarchar(max),
    @pattern nvarchar(max),    
    @options int) RETURNS TABLE (
        MatchNum int,
        GrpNum int,
        GrpName nvarchar(255),
        Item NVARCHAR(MAX))
```

#### Escape and unescape string functions
```sql
CREATE FUNCTION RegExEscape(@input nvarchar(max)) RETURNS NVARCHAR(MAX)
CREATE FUNCTION RegExUnescape(@input nvarchar(max)) RETURNS NVARCHAR(MAX)
```

#### Statistic and diagnostics collection functions
```sql
CREATE FUNCTION RegExCachedCount() RETURNS INT
CREATE FUNCTION RegExClearCache() RETURNS INT
CREATE FUNCTION RegExExecCount() RETURNS BIGINT
CREATE FUNCTION RegExCacheHitCount() RETURNS BIGINT
CREATE FUNCTION RegExExceptionCount() RETURNS BIGINT
CREATE FUNCTION RegExResetExecCount() RETURNS BIGINT
CREATE FUNCTION RegExResetCacheHitCount() RETURNS BIGINT
CREATE FUNCTION RegExResetExceptionCount() RETURNS BIGINT
CREATE FUNCTION RegExSetCacheEntryExpirationMilliseconds(
    @cacheEntryExpirationMilliseconds int) RETURNS INT
CREATE FUNCTION RegExCacheList() RETURNS TABLE (
    PATTERN NVARCHAR(MAX), 
    OPTIONS INT, 
    CACHEREGEXCOUNT INT,
    TTL INT
)
```

#### Enum used for regex functions that receive @options parameter:

```CSharp
public enum RegexOptions
  {
    /// Specifies that no options are set. For more information about the default behavior
    /// of the regular expression engine, see the "Default Options" section in the 
    /// Regular Expression Options topic.
     None = 0,

    /// Specifies case-insensitive matching. For more information, see the 
    /// "Case-Insensitive Matching " section in the Regular Expression Options topic.
     IgnoreCase = 1,

    /// Multiline mode. Changes the meaning of ^ and $ so they match at the beginning 
    /// and end, respectively, of any line, and not just the beginning and end of the 
    /// entire string. For more information, see the "Multiline Mode" section in the 
    /// Regular Expression Options topic. 
     Multiline = 2,

    /// Specifies that the only valid captures are explicitly named or numbered groups 
    /// of the form. 
    /// This allows unnamed parentheses to act as noncapturing groups without the 
    /// syntactic clumsiness of the expression (?:…). For more information, see the 
    /// "Explicit Captures Only" section in the Regular Expression Options topic. 
     ExplicitCapture = 4,

    /// Specifies that the regular expression is compiled to an assembly. This yields 
    /// faster execution but increases startup time. 
    // This value should not be assigned to the property when calling the method. 
    /// For more information, see the "Compiled Regular Expressions" section in the 
    /// Regular Expression Options topic. 
     Compiled = 8,

    /// Specifies single-line mode. Changes the meaning of the dot (.) so it matches 
    /// every character (instead of every character except \n). 
    /// For more information, see the "Single-line Mode" section in the Regular Expression
    /// Options topic. 
     Singleline = 16, // 0x00000010

    /// Eliminates unescaped white space from the pattern and enables comments marked with #. 
    /// However, this value does not affect or eliminate white space in , numeric , 
    /// or tokens that mark the beginning of individual . For more information, see the 
    /// "Ignore White Space" section of the Regular Expression Options topic. 
     IgnorePatternWhitespace = 32, // 0x00000020

    /// Specifies that the search will be from right to left instead of from left to right. 
    /// For more information, 
    /// see the "Right-to-Left Mode" section in the Regular Expression Options topic. 
     RightToLeft = 64, // 0x00000040

    /// Enables ECMAScript-compliant behavior for the expression. This value can be used only 
    /// in conjunction with the and values. The use of this value with any other values results 
    /// in an exception.
    /// For more information on the option, see the "ECMAScript Matching Behavior" section in the 
    /// Regular Expression Options topic. 
     ECMAScript = 256, // 0x00000100

    /// Specifies that cultural differences in language is ignored. For more information, 
    /// see the "Comparison Using the Invariant Culture" section in the Regular Expression
    /// Options topic.
     CultureInvariant = 512, // 0x00000200
  }
```

Example SQL to parse a tabke if key-value pairs, separated by commands and rows separates by semi-colons.
The example expects to columns: first column represent values for key named "key1" while the second column shows values for key named "key2".

```sql
SELECT MAX(Key1) Key1, MAX(Key2) Key2
FROM (
    SELECT RowGrp, Key1, Key2
    FROM (		
        SELECT GrpName, Item, SUM(RowGrp) OVER (ORDER BY MatchNum, GrpName) RowGrp
        FROM (
            SELECT MatchNum, GrpName, Item, IIF(GrpName = 'sc' AND Item = ';', 1, 0) RowGrp
            FROM dbo.RegExMatchesGroups('key1=1,key2=2,key1=5;key2=3,key1=10;key1=4;', '((?<key1>(?<=key1=)\d+(?=,)?)*(?<key2>(?<=key2=)\d+(?=,)?)*)(?<sc>;(?=.+))?')			
        ) _
    ) _
    PIVOT (
        MAX(Item) FOR GrpName IN (key1, key2)
    ) _
) _
GROUP BY RowGrp
```

Example of using RegEx to parse a file with key-value pairs separated by a delimiter and a further delimiter to split rows. Please notice the example also includes code that shows how to build the regex dynamically given the target list of "fields" to be split.

```sql
/* 
   This example code parses a delimiter separated input string into key-value pairs and returns a table with rows
   separated by a defined "row separator".
   The T-SQL part of the code is an example how to build the regex dynamically taking as input the field list, the 
   pattern used for detecting values, the key-value pair separator and the row separator.
*/

-- Input variables
DECLARE @fieldsList NVARCHAR(255) = 'key1,key2';
DECLARE @valuePattern NVARCHAR(255) = '\d+';
DECLARE @kvpSeparator NVARCHAR(255) = ',';
DECLARE @rowSeparator NVARCHAR(255) = ';';

-- Internal variables to build regex
DECLARE fields CURSOR FOR SELECT * FROM dbo.RegExSplit(@fieldsList, ',');
DECLARE @field NVARCHAR(255);
DECLARE @regex NVARCHAR(255) = '(';

OPEN fields;

FETCH NEXT FROM fields INTO @field;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @regex = @regex + CONCAT('(?<', @field, '>(?<=', @field, '=)', @valuePattern, '(?=', @kvpSeparator, ')?)*');
    FETCH NEXT FROM fields INTO @field;
END;

SET @regex = @regex + CONCAT(')(?<sc>', @rowSeparator, '(?=.+))?');
CLOSE fields;
DEALLOCATE fields;

/*
  RegEx generated above looks like this:

  ((?<key1>(?<=key1=)\d+(?=,)?)*(?<key2>(?<=key2=)\d+(?=,)?)*)(?<sc>;(?=.+))?

  Notice that in order to fetch other fields than key1 and key2 it's necessary to modify the input variable @fieldsList
  and also the SQL below adding the extra fields to the top SELECT, the second level SELECT clauses and the PIVOT clause.
*/

SELECT MAX(Key1) Key1, MAX(Key2) Key2
FROM (
    SELECT RowGrp, Key1, Key2
    FROM (		
        SELECT GrpName, Item, SUM(RowGrp) OVER (ORDER BY MatchNum, GrpName) RowGrp
        FROM (
            SELECT MatchNum, GrpName, Item, IIF(GrpName = 'sc' AND Item = ';', 1, 0) RowGrp
            FROM dbo.RegExMatchesGroups('key1=1,key2=2,key1=5;key2=3,key1=10;key1=4;key3=453,key1=34,key2=546', @regex)
        ) _
    ) _
    PIVOT (
        MAX(Item) FOR GrpName IN (key1, key2)
    ) _
) _
GROUP BY RowGrp
```