/* Source code for the library at: https://github.com/Ascentis/mssql-regex */

/*
  
  public enum RegexOptions
  {
    /// <summary>Specifies that no options are set. For more information about the default behavior of the regular expression engine, 
    /// see the "Default Options" section in the Regular Expression Options topic. </summary>
     None = 0,

    /// <summary>Specifies case-insensitive matching. For more information, see the "Case-Insensitive Matching " section in the Regular Expression Options topic. </summary>
     IgnoreCase = 1,

    /// <summary>Multiline mode. Changes the meaning of ^ and $ so they match at the beginning and end, respectively, of any line, 
    /// and not just the beginning and end of the entire string. For more information, see the "Multiline Mode" section in the Regular Expression Options topic. </summary>
     Multiline = 2,

    /// <summary>Specifies that the only valid captures are explicitly named or numbered groups of the form (?&lt;name&gt;…). 
    /// This allows unnamed parentheses to act as noncapturing groups without the syntactic clumsiness of the expression (?:…). For more information, see the "Explicit Captures Only" section in the Regular Expression Options topic. </summary>
     ExplicitCapture = 4,

    /// <summary>Specifies that the regular expression is compiled to an assembly. This yields faster execution but increases startup time. 
    // This value should not be assigned to the <see cref="P:System.Text.RegularExpressions.RegexCompilationInfo.Options" /> property when calling the <see cref="M:System.Text.RegularExpressions.Regex.CompileToAssembly(System.Text.RegularExpressions.RegexCompilationInfo[],System.Reflection.AssemblyName)" /> method. For more information, see the "Compiled Regular Expressions" section in the Regular Expression Options topic. </summary>
     Compiled = 8,

    /// <summary>Specifies single-line mode. Changes the meaning of the dot (.) so it matches every character (instead of every character except \n). 
    /// For more information, see the "Single-line Mode" section in the Regular Expression Options topic. </summary>
     Singleline = 16, // 0x00000010

    /// <summary>Eliminates unescaped white space from the pattern and enables comments marked with #. However, this value does not affect or eliminate white space in , numeric , 
    /// or tokens that mark the beginning of individual . For more information, see the "Ignore White Space" section of the Regular Expression Options topic. </summary>
     IgnorePatternWhitespace = 32, // 0x00000020

    /// <summary>Specifies that the search will be from right to left instead of from left to right. For more information, 
    /// see the "Right-to-Left Mode" section in the Regular Expression Options topic. </summary>
     RightToLeft = 64, // 0x00000040

    /// <summary>Enables ECMAScript-compliant behavior for the expression. This value can be used only in conjunction with the 
    /// <see cref="F:System.Text.RegularExpressions.RegexOptions.IgnoreCase" />, <see cref="F:System.Text.RegularExpressions.RegexOptions.Multiline" />, 
    /// and <see cref="F:System.Text.RegularExpressions.RegexOptions.Compiled" /> values. The use of this value with any other values results in an exception.
    /// For more information on the <see cref="F:System.Text.RegularExpressions.RegexOptions.ECMAScript" /> option, see the "ECMAScript Matching Behavior" section in the 
    /// Regular Expression Options topic. </summary>
     ECMAScript = 256, // 0x00000100

    /// <summary>Specifies that cultural differences in language is ignored. For more information, 
    /// see the "Comparison Using the Invariant Culture" section in the Regular Expression Options topic.</summary>
     CultureInvariant = 512, // 0x00000200
  }

*/

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExIsMatch]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExIsMatch
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExIsMatchWithOptions]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExIsMatchWithOptions
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatch]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExMatch
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchWithOptions]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExMatchWithOptions
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchIndexed]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExMatchIndexed
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchIndexedWithOptions]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExMatchIndexedWithOptions
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExSplit]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExSplit
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExSplitWithOptions]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExSplitWithOptions
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExReplace]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExReplace
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExReplaceWithOptions]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExReplaceWithOptions
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExReplaceCount]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExReplaceCount
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExReplaceCountWithOptions]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExReplaceCountWithOptions
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExEscape]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExEscape
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExUnescape]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExUnescape
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatches]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExMatches
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchesWithOptions]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExMatchesWithOptions
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchGroup]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExMatchGroup
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchGroupWithOptions]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExMatchGroupWithOptions
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchGroupIndexed]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExMatchGroupIndexed
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchGroupIndexedWithOptions]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExMatchGroupIndexedWithOptions
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchesGroup]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExMatchesGroup
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchesGroupWithOptions]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExMatchesGroupWithOptions
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExCachedCount]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExCachedCount
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExCacheHitCount]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExCacheHitCount
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExClearCache]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExClearCache
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExExecCount]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExExecCount
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExExceptionCount]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExExceptionCount
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExResetExecCount]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExResetExecCount
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExResetCacheHitCount]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExResetCacheHitCount
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExResetExceptionCount]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExResetExceptionCount
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExSetCacheEntryExpirationMilliseconds]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExSetCacheEntryExpirationMilliseconds
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExCacheList]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExCacheList
GO

IF EXISTS (select *
	from sys.assembly_files f
	full outer join  sys.assemblies a
		on f.assembly_id=a.assembly_id
	where a.name ='Ascentis.RegExSQL')
	DROP ASSEMBLY [Ascentis.RegExSQL]
GO

IF EXISTS(SELECT *
		  from sys.configurations	
		  where name = 'clr strict security' and value = 0)
	EXEC SP_CONFIGURE 'clr strict security', 1
GO

RECONFIGURE
GO

DECLARE @clrName nvarchar(4000) = 'Ascentis.RegExSql';
DECLARE @asmBin varbinary(max) = <BinaryDll>;
DECLARE @hash varbinary(64);

SELECT @hash = HASHBYTES('SHA2_512', @asmBin);

IF EXISTS(SELECT * from sys.trusted_assemblies
	  	  WHERE description = 'Ascentis.RegExSql')
BEGIN
	DECLARE @UnTrustAssembliesCmd nvarchar(max) = '';

	SELECT @UnTrustAssembliesCmd = @UnTrustAssembliesCmd + 'EXEC sys.sp_drop_trusted_assembly @hash = ' + CONVERT(varchar(max), hash, 1) + ';' 
	FROM sys.trusted_assemblies
	WHERE description = 'Ascentis.RegExSql';

	EXEC sp_executesql @UnTrustAssembliesCmd
END

EXEC sys.sp_add_trusted_assembly @hash = @hash, @description = @clrName;

CREATE ASSEMBLY [Ascentis.RegExSQL]
FROM @asmBin
WITH PERMISSION_SET = UNSAFE
GO

CREATE FUNCTION RegExIsMatch( 
  @input nvarchar(max),
  @pattern nvarchar(max)
)
RETURNS bit EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledIsMatch
GO

CREATE FUNCTION RegExIsMatchWithOptions( 
  @input nvarchar(max),
  @pattern nvarchar(max),
  @options int
)
RETURNS bit EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledIsMatchWithOptions
GO

CREATE FUNCTION RegExMatch( 
  @input nvarchar(max),
  @pattern nvarchar(max)  
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatch
GO

CREATE FUNCTION RegExMatchWithOptions( 
  @input nvarchar(max),
  @pattern nvarchar(max),
  @options int
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchWithOptions
GO

CREATE FUNCTION RegExMatchIndexed( 
  @input nvarchar(max),
  @pattern nvarchar(max),
  @index int
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchIndexed
GO

CREATE FUNCTION RegExMatchIndexedWithOptions( 
  @input nvarchar(max),
  @pattern nvarchar(max),
  @index int,
  @options int
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchIndexedWithOptions
GO

CREATE FUNCTION RegExMatchGroup( 
  @input nvarchar(max),
  @pattern nvarchar(max),
  @group int
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchGroup
GO

CREATE FUNCTION RegExMatchGroupWithOptions( 
  @input nvarchar(max),
  @pattern nvarchar(max),
  @group int,
  @options int
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchGroupWithOptions
GO

CREATE FUNCTION RegExMatchGroupIndexed( 
  @input nvarchar(max),
  @pattern nvarchar(max),
  @group int,
  @index int
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchGroupIndexed
GO

CREATE FUNCTION RegExMatchGroupIndexedWithOptions( 
  @input nvarchar(max),
  @pattern nvarchar(max),
  @group int,
  @index int,
  @options int
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchGroupIndexedWithOptions
GO

CREATE FUNCTION RegExReplace( 
  @input nvarchar(max),
  @pattern nvarchar(max),
  @replacement nvarchar(max)
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledReplace
GO

CREATE FUNCTION RegExReplaceWithOptions( 
  @input nvarchar(max),
  @pattern nvarchar(max),
  @replacement nvarchar(max),
  @options int
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledReplaceWithOptions
GO

CREATE FUNCTION RegExReplaceCount( 
  @input nvarchar(max),
  @pattern nvarchar(max),
  @replacement nvarchar(max),
  @count int
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledReplaceCount
GO

CREATE FUNCTION RegExReplaceCountWithOptions( 
  @input nvarchar(max),
  @pattern nvarchar(max),
  @replacement nvarchar(max),
  @count int,
  @options int
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledReplaceCountWithOptions
GO

CREATE FUNCTION RegExSplit(
	@input nvarchar(max),
	@pattern nvarchar(max)
)
RETURNS TABLE (ITEM NVARCHAR(MAX)) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledSplit
GO

CREATE FUNCTION RegExSplitWithOptions(
	@input nvarchar(max),
	@pattern nvarchar(max),
    @options int
)
RETURNS TABLE (ITEM NVARCHAR(MAX)) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledSplitWithOptions
GO

CREATE FUNCTION RegExEscape(
	@input nvarchar(max)
)
RETURNS NVARCHAR(MAX) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledEscape
GO

CREATE FUNCTION RegExUnescape(
	@input nvarchar(max)
)
RETURNS NVARCHAR(MAX) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledUnescape
GO

CREATE FUNCTION RegExMatches(
	@input nvarchar(max),
	@pattern nvarchar(max)
)
RETURNS TABLE (ITEM NVARCHAR(MAX)) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatches
GO

CREATE FUNCTION RegExMatchesWithOptions(
	@input nvarchar(max),
	@pattern nvarchar(max),
    @options int
)
RETURNS TABLE (ITEM NVARCHAR(MAX)) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchesWithOptions
GO

CREATE FUNCTION RegExMatchesGroup(
	@input nvarchar(max),
	@pattern nvarchar(max),
	@group int
)
RETURNS TABLE (ITEM NVARCHAR(MAX)) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchesGroup
GO

CREATE FUNCTION RegExMatchesGroupWithOptions(
	@input nvarchar(max),
	@pattern nvarchar(max),
	@group int,
    @options int
)
RETURNS TABLE (ITEM NVARCHAR(MAX)) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchesGroupWithOptions
GO

CREATE FUNCTION RegExCachedCount()
RETURNS INT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCachedCount
GO

CREATE FUNCTION RegExClearCache()
RETURNS INT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExClearCache
GO

CREATE FUNCTION RegExExecCount()
RETURNS BIGINT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExExecCount
GO

CREATE FUNCTION RegExCacheHitCount()
RETURNS BIGINT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCacheHitCount
GO

CREATE FUNCTION RegExExceptionCount()
RETURNS BIGINT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExExceptionCount
GO

CREATE FUNCTION RegExResetExecCount()
RETURNS BIGINT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExResetExecCount
GO

CREATE FUNCTION RegExResetCacheHitCount()
RETURNS BIGINT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExResetCacheHitCount
GO

CREATE FUNCTION RegExResetExceptionCount()
RETURNS BIGINT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExResetExceptionCount
GO

CREATE FUNCTION RegExSetCacheEntryExpirationMilliseconds(
    @cacheEntryExpirationMilliseconds int
)
RETURNS INT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExSetCacheEntryExpirationMilliseconds
GO

CREATE FUNCTION RegExCacheList()
RETURNS TABLE (
    PATTERN NVARCHAR(MAX), 
    OPTIONS INT, 
    CACHEREGEXCOUNT INT,
    TTL INT) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCacheList
GO

