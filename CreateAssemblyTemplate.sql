/* Source code for the library at: https://github.com/Ascentis/mssql-regex */

PRINT 'Checking if regex package already exists...';

DECLARE @clrName nvarchar(4000) = 'Ascentis.RegExSql';
DECLARE @asmBin varbinary(max) = <BinaryDll>;
DECLARE @hash varbinary(64);

SELECT @hash = HASHBYTES('SHA2_512', @asmBin);

IF NOT EXISTS (select *
               from sys.assembly_files f
               where HASHBYTES('SHA2_512', f.content) = @hash
                     AND f.name = @clrName)
BEGIN	
    PRINT 'Dropping regex functions';
    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExIsMatch]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExIsMatch;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExIsMatchWithOptions]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExIsMatchWithOptions;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatch]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExMatch;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchWithOptions]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExMatchWithOptions;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchIndexed]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExMatchIndexed;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchIndexedWithOptions]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExMatchIndexedWithOptions;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExSplit]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExSplit;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExSplitWithOptions]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExSplitWithOptions;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExReplace]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExReplace;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExReplaceWithOptions]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExReplaceWithOptions;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExReplaceCount]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExReplaceCount;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExReplaceCountWithOptions]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExReplaceCountWithOptions;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExEscape]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExEscape;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExUnescape]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExUnescape;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatches]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExMatches;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchesWithOptions]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExMatchesWithOptions;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchGroup]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExMatchGroup;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchGroupWithOptions]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExMatchGroupWithOptions;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchGroupIndexed]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExMatchGroupIndexed;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchGroupIndexedWithOptions]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExMatchGroupIndexedWithOptions;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchesGroup]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExMatchesGroup;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchesGroupWithOptions]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExMatchesGroupWithOptions;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchesGroups]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExMatchesGroups;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchesGroupsWithOptions]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExMatchesGroupsWithOptions;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExCachedCount]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExCachedCount;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExCacheHitCount]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExCacheHitCount;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExClearCache]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExClearCache;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExExecCount]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExExecCount;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExExceptionCount]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExExceptionCount;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExResetExecCount]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExResetExecCount;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExResetCacheHitCount]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExResetCacheHitCount;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExResetExceptionCount]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExResetExceptionCount;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExSetCacheEntryExpirationMilliseconds]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExSetCacheEntryExpirationMilliseconds;

    IF EXISTS (SELECT *
               FROM   sys.objects
               WHERE  object_id = OBJECT_ID(N'[dbo].[RegExCacheList]')
                      AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
        DROP FUNCTION RegExCacheList;

    PRINT 'Dropping existing assemblies matching name "Ascentis.RegExQL"'
    IF EXISTS (select *
        from sys.assembly_files f
        full outer join  sys.assemblies a
            on f.assembly_id=a.assembly_id
        where a.name ='Ascentis.RegExSQL')
        DROP ASSEMBLY [Ascentis.RegExSQL];

    PRINT 'Resetting CLR Security to "Enabled"'
    IF EXISTS(SELECT *
              from sys.configurations	
              where name = 'clr strict security' and value = 0)
        EXEC SP_CONFIGURE 'clr strict security', 1;

    RECONFIGURE;

    PRINT 'Adding our assembly to list of trusted assemblies'
    IF EXISTS(SELECT * from sys.trusted_assemblies
              WHERE description = 'Ascentis.RegExSql')
    BEGIN
        DECLARE @UnTrustAssembliesCmd nvarchar(max) = '';

        SELECT @UnTrustAssembliesCmd = @UnTrustAssembliesCmd + 'EXEC sys.sp_drop_trusted_assembly @hash = ' + CONVERT(varchar(max), hash, 1) + ';' 
        FROM sys.trusted_assemblies
        WHERE description = 'Ascentis.RegExSql';

        EXEC sp_executesql @UnTrustAssembliesCmd;
    END;

    EXEC sys.sp_add_trusted_assembly @hash = @hash, @description = @clrName;

    PRINT 'Pushing our assembly into the database';
    CREATE ASSEMBLY [Ascentis.RegExSQL]
    FROM @asmBin
    WITH PERMISSION_SET = UNSAFE;

    PRINT 'Creating function stubs';
    DECLARE @CreateFnCommand nvarchar(max) = '';

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExIsMatch( 
          @input nvarchar(max),
          @pattern nvarchar(max)
        )
        RETURNS bit EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledIsMatch;';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExIsMatchWithOptions( 
          @input nvarchar(max),
          @pattern nvarchar(max),
          @options int
        )
        RETURNS bit EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledIsMatchWithOptions';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExMatch( 
          @input nvarchar(max),
          @pattern nvarchar(max)  
        )
        RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatch'
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExMatchWithOptions( 
          @input nvarchar(max),
          @pattern nvarchar(max),
          @options int
        )
        RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchWithOptions'
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExMatchIndexed( 
          @input nvarchar(max),
          @pattern nvarchar(max),
          @index int
        )
        RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchIndexed';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExMatchIndexedWithOptions( 
          @input nvarchar(max),
          @pattern nvarchar(max),
          @index int,
          @options int
        )
        RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchIndexedWithOptions';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExMatchGroup( 
          @input nvarchar(max),
          @pattern nvarchar(max),
          @group int
        )
        RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchGroup';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExMatchGroupWithOptions( 
          @input nvarchar(max),
          @pattern nvarchar(max),
          @group int,
          @options int
        )
        RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchGroupWithOptions';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExMatchGroupIndexed( 
          @input nvarchar(max),
          @pattern nvarchar(max),
          @group int,
          @index int
        )
        RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchGroupIndexed';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExMatchGroupIndexedWithOptions( 
          @input nvarchar(max),
          @pattern nvarchar(max),
          @group int,
          @index int,
          @options int
        )
        RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchGroupIndexedWithOptions';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExReplace( 
          @input nvarchar(max),
          @pattern nvarchar(max),
          @replacement nvarchar(max)
        )
        RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledReplace';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExReplaceWithOptions( 
          @input nvarchar(max),
          @pattern nvarchar(max),
          @replacement nvarchar(max),
          @options int
        )
        RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledReplaceWithOptions';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExReplaceCount( 
          @input nvarchar(max),
          @pattern nvarchar(max),
          @replacement nvarchar(max),
          @count int
        )
        RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledReplaceCount';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExReplaceCountWithOptions( 
          @input nvarchar(max),
          @pattern nvarchar(max),
          @replacement nvarchar(max),
          @count int,
          @options int
        )
        RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledReplaceCountWithOptions';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExSplit(
            @input nvarchar(max),
            @pattern nvarchar(max)
        )
        RETURNS TABLE (ITEM NVARCHAR(MAX)) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledSplit';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExSplitWithOptions(
            @input nvarchar(max),
            @pattern nvarchar(max),
            @options int
        )
        RETURNS TABLE (ITEM NVARCHAR(MAX)) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledSplitWithOptions';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExEscape(
            @input nvarchar(max)
        )
        RETURNS NVARCHAR(MAX) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledEscape';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExUnescape(
            @input nvarchar(max)
        )
        RETURNS NVARCHAR(MAX) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledUnescape';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExMatches(
            @input nvarchar(max),
            @pattern nvarchar(max)
        )
        RETURNS TABLE (ITEM NVARCHAR(MAX)) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatches';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExMatchesWithOptions(
            @input nvarchar(max),
            @pattern nvarchar(max),
            @options int
        )
        RETURNS TABLE (ITEM NVARCHAR(MAX)) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchesWithOptions';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExMatchesGroup(
            @input nvarchar(max),
            @pattern nvarchar(max),
            @group int
        )
        RETURNS TABLE (ITEM NVARCHAR(MAX)) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchesGroup';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExMatchesGroupWithOptions(
            @input nvarchar(max),
            @pattern nvarchar(max),
            @group int,
            @options int
        )
        RETURNS TABLE (ITEM NVARCHAR(MAX)) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchesGroupWithOptions';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExMatchesGroupsWithOptions(
            @input nvarchar(max),
            @pattern nvarchar(max),      
            @options int
        )
        RETURNS TABLE (
            MatchNum int,
            GrpNum int,
            Item NVARCHAR(MAX)) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchesGroupsWithOptions';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExMatchesGroups(
            @input nvarchar(max),
            @pattern nvarchar(max)            
        )
        RETURNS TABLE (
            MatchNum int,
            GrpNum int,
            Item NVARCHAR(MAX)) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchesGroups';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExCachedCount()
        RETURNS INT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCachedCount';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExClearCache()
        RETURNS INT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExClearCache';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExExecCount()
        RETURNS BIGINT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExExecCount';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExCacheHitCount()
        RETURNS BIGINT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCacheHitCount';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExExceptionCount()
        RETURNS BIGINT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExExceptionCount';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExResetExecCount()
        RETURNS BIGINT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExResetExecCount';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExResetCacheHitCount()
        RETURNS BIGINT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExResetCacheHitCount';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExResetExceptionCount()
        RETURNS BIGINT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExResetExceptionCount';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExSetCacheEntryExpirationMilliseconds(
            @cacheEntryExpirationMilliseconds int
        )
        RETURNS INT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExSetCacheEntryExpirationMilliseconds';
    EXEC sp_executesql @CreateFnCommand;

    SET @CreateFnCommand = '
        CREATE FUNCTION RegExCacheList()
        RETURNS TABLE (
            PATTERN NVARCHAR(MAX), 
            OPTIONS INT, 
            CACHEREGEXCOUNT INT,
            TTL INT) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCacheList';
    EXEC sp_executesql @CreateFnCommand;    
END
ELSE
BEGIN
    PRINT 'Assembly already exists. Exiting';
END
GO

PRINT 'Testing our regex library...'
IF NOT EXISTS(SELECT * 
              FROM dbo.RegExMatches('SM1,M 29,B 13', '(^|,)(E372|M 29|E275|B 13)((?=,)|(?=$))'))
BEGIN
    THROW 50001, 'Something is wrong with regex library. Expected matches calling RegExMatches(). Test failed', 1;
END
PRINT 'Test passed';
