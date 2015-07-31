CREATE PROCEDURE [dbo].[csp_easytopro_createandinsertfixedfields]
    (
      @@easytable NVARCHAR(64) ,
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
         
        
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
            --DECLARATIONS
        DECLARE @sql NVARCHAR(MAX)
        DECLARE @fieldtype INT
        DECLARE @insert NVARCHAR(MAX)
        DECLARE @select NVARCHAR(MAX)
        DECLARE @protable NVARCHAR(64) 
        DECLARE @profield NVARCHAR(64) 
        DECLARE @relatedprotable NVARCHAR(64)
        DECLARE @relatedeasytable NVARCHAR(64)
        DECLARE @selectstatement NVARCHAR(2048)
        DECLARE @issuperfield INT
        DECLARE @proposedvalue NVARCHAR(128) 
        DECLARE @easyfieldname NVARCHAR(64)
        DECLARE @defaultvalue NVARCHAR(128) 
        DECLARE @isrequired NVARCHAR(1)

-- SET INITIAL VALUES
        SELECT  @sql = N''
        SELECT  @select = N''
        SELECT  @insert = N''


        DECLARE row_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
            SELECT DISTINCT
                    e.[protable] ,
                    e.[easyfieldname] ,
                    e.[profieldname] ,
                    CASE WHEN LEN(ISNULL(e.proposedvalue, N'')) > 0
                         THEN REPLACE(e.[proposedvalue], N'''', N'''''')
                         ELSE ( SELECT  CASE WHEN [isnullable] = 1
                                                  AND [defaultvalue] = N''
                                             THEN CAST(N'NULL' AS NVARCHAR(128))
                                             ELSE CAST([defaultvalue] AS NVARCHAR(128))
                                        END
                                FROM    [dbo].[fieldcache] f
                                        INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                              AND t.[name] = e.protable
                                WHERE   f.[name] = e.[profieldname]
                              )
                    END ,
                    CASE WHEN EXISTS ( SELECT   f.[idfield]
                                       FROM     [dbo].[fieldcache] f
                                                INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                INNER JOIN [dbo].[attributedata] a ON a.[idrecord] = f.[idfield]
                                                              AND a.[owner] = N'field'
                                                              AND a.[name] = N'required'
                                       WHERE    e.[profieldname] = f.[name]
                                                AND e.[protable] = t.[name] )
                         THEN N'1'
                         ELSE N'0'
                    END ,
                    ( SELECT TOP 1
                                CASE WHEN [isnullable] = 1
                                          AND [defaultvalue] = N''
                                     THEN CAST(N'NULL' AS NVARCHAR(128))
                                     ELSE CAST([defaultvalue] AS NVARCHAR(128))
                                END
                      FROM      [dbo].[fieldcache] f
                                INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                      WHERE     e.[profieldname] = f.[name]
                                AND e.[protable] = t.[name]
                    ) ,
                    e.[easyprofieldtype] ,
                    e.[issuperfield]
            FROM    [dbo].[EASY__FIELDMAPPING] e
            WHERE   e.[easytable] = @@easytable
                    AND e.[issuperfield] = 0
                    AND LEN(e.[protable]) > 0
                    AND e.[transfertable] = 1
                    AND e.[active] = 1
            UNION
            SELECT DISTINCT
                    e.[protable] ,
                    N'' ,
                    e.[profieldname] ,
                    CASE WHEN LEN(ISNULL(e.proposedvalue, N'')) > 0
                         THEN REPLACE(e.[proposedvalue], N'''', N'''''')
                         ELSE ( SELECT  CASE WHEN [isnullable] = 1
                                                  AND [defaultvalue] = N''
                                             THEN CAST(N'NULL' AS NVARCHAR(128))
                                             ELSE CAST([defaultvalue] AS NVARCHAR(128))
                                        END
                                FROM    [dbo].[fieldcache] f
                                        INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                              AND t.[name] = e.protable
                                WHERE   f.[name] = e.[profieldname]
                              )
                    END ,
                    CASE WHEN EXISTS ( SELECT   f.[idfield]
                                       FROM     [dbo].[fieldcache] f
                                                INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                INNER JOIN [dbo].[attributedata] a ON a.[idrecord] = f.[idfield]
                                                              AND a.[owner] = N'field'
                                                              AND a.[name] = N'required'
                                       WHERE    e.[profieldname] = f.[name]
                                                AND e.[protable] = t.[name] )
                         THEN 1
                         ELSE 0
                    END ,
                    ( SELECT TOP 1
                                CASE WHEN [isnullable] = 1
                                          AND [defaultvalue] = N''
                                     THEN CAST(N'NULL' AS NVARCHAR(128))
                                     ELSE CAST([defaultvalue] AS NVARCHAR(128))
                                END
                      FROM      [dbo].[fieldcache] f
                                INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                      WHERE     e.[profieldname] = f.[name]
                                AND e.[protable] = t.[name]
                    ) ,
                    e.[easyprofieldtype] ,
                    e.[issuperfield]
            FROM    dbo.EASY__FIELDMAPPING e
                    INNER JOIN [dbo].[fieldcache] f ON f.[name] = e.[profieldname]
                    INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                  AND t.[name] = e.[protable]
            WHERE   LEN(ISNULL(e.[proposedvalue], N'')) > 0
                    AND e.[issuperfield] = 1
                    AND e.[easytable] = @@easytable
                    AND LEN(e.[protable]) > 0
                    AND e.[transfertable] = 1
                    AND e.[active] = 1

        OPEN row_cursor
        FETCH NEXT FROM row_cursor INTO @protable, @easyfieldname, @profield,
            @proposedvalue, @isrequired, @defaultvalue, @fieldtype,
            @issuperfield
        WHILE @@FETCH_STATUS = 0 
            BEGIN
    
                IF ( @@easytable != N'HISTORY' AND @@easytable != N'USER' ) -- HISTORY AND USER IS HANDLED IN OTHER CSP
                    BEGIN		
                        
                        SELECT  @select = @select + CHAR(10) + N', '
                                + N'ISNULL('
                                + CASE WHEN @@easytable = 'TODO'
                                            AND @easyfieldname = N'Start date'
                                       THEN N'DATEADD(SECOND, [Start time], '
                                            + QUOTENAME(@easyfieldname) + N')'
                                       WHEN @@easytable = 'TODO'
                                            AND @easyfieldname = N'Stop date'
                                       THEN N' CASE WHEN [Done date] IS NULL THEN DATEADD(SECOND, [Stop time], '
                                            + QUOTENAME(@easyfieldname)
                                            + N') ELSE DATEADD(SECOND, [Done time], [Done date]) END'
                                       WHEN @@easytable = 'TODO'
                                            AND @easyfieldname = N'Done'
                                       THEN N' CASE WHEN [Done date] IS NULL THEN 0 ELSE 1 END'
                                       WHEN @@easytable = 'ARCHIVE'
                                            AND @easyfieldname = N'Date'
                                       THEN N'DATEADD(SECOND, [Time], '
                                            + QUOTENAME(@easyfieldname) + N')'
                                       WHEN @issuperfield = 1 THEN N'NULL' -- ALWAYS USE PROPOSEDVALUE
                                       ELSE N'(CASE WHEN 1 = ' + @isrequired
                                            + N' THEN CASE WHEN '
                                            + QUOTENAME(@easyfieldname) + N'='
                                            + CASE WHEN @fieldtype IN ( 1, 12,
                                                              23 )
                                                   THEN N'N'''
                                                        + ISNULL(@defaultvalue,
                                                              N'') + N''''
                                                   WHEN @fieldtype = 20
                                                   THEN CASE WHEN LEN(ISNULL(@defaultvalue,
                                                              N'')) > 0
                                                             THEN N''';'
                                                              + ISNULL(@defaultvalue,
                                                              N'') + N';'')'
                                                             ELSE N'N'''' '
                                                        END
                                                   ELSE ISNULL(@defaultvalue,
                                                              N'')
                                              END + N' THEN '
                                            + CASE WHEN @fieldtype IN ( 1, 12,
                                                              23 )
                                                   THEN N'N'''
                                                        + ISNULL(@proposedvalue,
                                                              N'') + N''''
                                                   WHEN @fieldtype = 20
                                                   THEN CASE WHEN LEN(ISNULL(@proposedvalue,
                                                              N'')) > 0
                                                             THEN N''';'
                                                              + ISNULL(@proposedvalue,
                                                              N'') + N';'')'
                                                             ELSE N'N'''' '
                                                        END
                                                   ELSE ISNULL(@proposedvalue,
                                                              N'')
                                              END + N' ELSE '
                                            + QUOTENAME(@easyfieldname)
                                            + N' END ELSE '
                                            + QUOTENAME(@easyfieldname)
                                            + N' END ) '
                                  END + N', '
                                + CASE WHEN @fieldtype IN ( 1, 12, 23 )
                                       THEN N'N''' + ISNULL(@proposedvalue,
                                                            N'') + N''''
                                       WHEN @fieldtype = 20
                                       THEN CASE WHEN LEN(ISNULL(@proposedvalue,
                                                              N'')) > 0
                                                 THEN N''';'
                                                      + ISNULL(@proposedvalue,
                                                              N'') + N';'')'
                                                 ELSE N'N'''')'
                                            END
                                       ELSE ISNULL(@proposedvalue, N'')
                                  END + N')' ,
                                @insert = @insert + CHAR(10) + N', '
                                + QUOTENAME(@profield) 
                
                
                    END
        
                        
		
                FETCH NEXT FROM row_cursor INTO @protable, @easyfieldname,
                    @profield, @proposedvalue, @isrequired, @defaultvalue,
                    @fieldtype, @issuperfield
            END
				
        CLOSE row_cursor
        DEALLOCATE row_cursor    

        IF ( LEN(@select) > 0
             AND LEN(@insert) > 0
           ) 
            BEGIN
                SELECT  @sql = N'INSERT INTO [dbo].' + QUOTENAME(@protable)
                        + CHAR(10) + N' ([status]' + CHAR(10)
                        + CASE @@easytable
                            WHEN N'CONTACT' THEN N', [contact_limeeasyid]'
                            WHEN N'REFS'
                            THEN N', [contact_limeeasyid]' + CHAR(10)
                                 + N', [refs_limeeasyid]' + CHAR(10)
                                 + N', [easy_fullname]'
                            WHEN N'PROJECT' THEN N', [project_limeeasyid]'
                            WHEN N'TIME'
                            THEN N', [contact_limeeasyid]' + CHAR(10)
                                 + N', [time_limeeasyid]' + CHAR(10)
                                 + N', [user_limeeasyid]'
                            WHEN N'TODO'
                            THEN N', [contact_limeeasyid]' + CHAR(10)
                                 + N', [project_limeeasyid]' + CHAR(10)
                                 + N', [user_limeeasyid]' + CHAR(10)
                                 + N', [todo_limeeasyid]' + CHAR(10)
                                 + N', [todo_easytype]' + CHAR(10)
                                 + N', [todo_easykey1]' + CHAR(10)
                                 + N', [todo_easykey2]'
                            WHEN N'ARCHIVE'
                            THEN N', [contact_limeeasyid]' + CHAR(10)
                                 + N', [project_limeeasyid]' + CHAR(10)
                                 + N', [user_limeeasyid]' + CHAR(10)
                                 + N', [archive_limeeasyid]' + CHAR(10)
                                 + N', [archive_easytype]' + CHAR(10)
                                 + N', [archive_easykey1]' + CHAR(10)
                                 + N', [archive_easykey2]' + CHAR(10)
                                 + N', [archive_limeeasypath]'
                            --WHEN N'USER' THEN N', [user_limeeasyid]'
                          END + @insert + N')' + CHAR(10) + N'SELECT '
                        + CHAR(10) + N' 0' + CHAR(10)
                        + CASE @@easytable
                            WHEN N'CONTACT' THEN N', [Company ID]'
                            WHEN N'REFS'
                            THEN N', [Company ID]' + CHAR(10)
                                 + N', [Reference ID]' + CHAR(10)
                                 + N', [Name]'
                            WHEN N'PROJECT' THEN N', [Project ID]'
                            WHEN N'TIME'
                            THEN N', [Company ID]' + CHAR(10) + N', [Time ID]'
                                 + CHAR(10) + N', [User ID]'
                            WHEN N'TODO'
                            THEN N', CASE WHEN [Type] IN (0,8) THEN [Key 1] ELSE NULL END '
                                 + CHAR(10)
                                 + N', CASE WHEN [Type] = 2 THEN [Key 1] ELSE NULL END '
                                 + CHAR(10) + N', [User ID]' + CHAR(10)
                                 + N', [Key 2]' + CHAR(10) + N', [Type]'
                                 + CHAR(10) + N', [Key 1]' + CHAR(10)
                                 + N', [Key 2]'
                            WHEN N'ARCHIVE'
                            THEN N', CASE WHEN [Type] = 0 THEN [Key 1] ELSE NULL END '
                                 + CHAR(10)
                                 + N', CASE WHEN [Type] = 2 THEN [Key 1] ELSE NULL END '
                                 + CHAR(10) + N', [User ID]' + CHAR(10)
                                 + N', [Key 2]' + CHAR(10) + N', [Type]'
                                 + CHAR(10) + N', [Key 1]' + CHAR(10)
                                 + N', [Key 2]' + CHAR(10)
                                 + N', [Path]'
                            --WHEN N'USER' THEN N', [User ID]'
                          END + @select + CHAR(10) + N' FROM [dbo].[EASY__'
                        + @@easytable + N']'
        
            END
    
        IF ( LEN(ISNULL(@sql, N'')) > 0 ) 
            BEGIN
                BEGIN TRY
                    --PRINT @sql
                    EXEC sp_executesql @sql
                        
                        --PRINT @sql
                        
                    SET @@errormessage = N''
                END TRY
                BEGIN CATCH
						--PRINT ERROR_MESSAGE()
                    SET @@errormessage = ERROR_MESSAGE()
                END CATCH
            END
                
        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''
    END