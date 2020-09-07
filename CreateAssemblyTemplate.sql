/* Source code for the library at: https://github.com/Ascentis/mssql-regex */

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExIsMatch]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExIsMatch
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatch]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExMatch
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchIndexed]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExMatchIndexed
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExSplit]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExSplit
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExReplace]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExReplace
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExReplaceCount]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExReplaceCount
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
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchGroup]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExMatchGroup
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchGroupIndexed]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExMatchGroupIndexed
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchesGroup]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExMatchesGroup
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExCachedCount]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExCachedCount
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
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExResetExecCount]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExResetExecCount
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
	DECLARE @UnTrustAssembliesCmd nvarchar(max);

	SELECT @UnTrustAssembliesCmd = 'EXEC sys.sp_drop_trusted_assembly @hash = ' + CONVERT(varchar(max), hash, 1) + ';' 
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

CREATE FUNCTION RegExMatch( 
  @input nvarchar(max),
  @pattern nvarchar(max)  
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatch
GO

CREATE FUNCTION RegExMatchIndexed( 
  @input nvarchar(max),
  @pattern nvarchar(max),
  @index int
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchIndexed
GO

CREATE FUNCTION RegExMatchGroup( 
  @input nvarchar(max),
  @pattern nvarchar(max),
  @group int
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchGroup
GO

CREATE FUNCTION RegExMatchGroupIndexed( 
  @input nvarchar(max),
  @pattern nvarchar(max),
  @group int,
  @index int
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchGroupIndexed
GO

CREATE FUNCTION RegExReplace( 
  @input nvarchar(max),
  @pattern nvarchar(max),
  @replacement nvarchar(max)
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledReplace
GO

CREATE FUNCTION RegExReplaceCount( 
  @input nvarchar(max),
  @pattern nvarchar(max),
  @replacement nvarchar(max),
  @count int
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledReplaceCount
GO

CREATE FUNCTION RegExSplit(
	@input nvarchar(max),
	@pattern nvarchar(max)
)
RETURNS TABLE (ITEM NVARCHAR(MAX)) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledSplit
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

CREATE FUNCTION RegExMatchesGroup(
	@input nvarchar(max),
	@pattern nvarchar(max),
	@group int
)
RETURNS TABLE (ITEM NVARCHAR(MAX)) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchesGroup
GO

CREATE FUNCTION RegExCachedCount()
RETURNS INT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCachedCount
GO

CREATE FUNCTION RegExClearCache()
RETURNS INT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExClearCache
GO

CREATE FUNCTION RegExExecCount()
RETURNS INT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExExecCount
GO

CREATE FUNCTION RegExResetExecCount()
RETURNS INT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExResetExecCount
GO
