CREATE PROCEDURE [dbo].[csp_easytopro_mergeuser]
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
        DECLARE @update NVARCHAR(MAX)
        DECLARE @values NVARCHAR(MAX)
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
        SELECT  @update = N''
        SELECT  @values = N''


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
           

        OPEN row_cursor
        FETCH NEXT FROM row_cursor INTO @protable, @easyfieldname, @profield,
            @proposedvalue, @isrequired, @defaultvalue, @fieldtype,
            @issuperfield
        WHILE @@FETCH_STATUS = 0 
            BEGIN
    
                IF ( @@easytable = N'USER' ) -- HISTORY AND USER IS HANDLED IN OTHER CSP
                    BEGIN		
                        
                        SELECT  @select = @select + CHAR(10) + N', ' + QUOTENAME(@easyfieldname) --+ N' AS ' + QUOTENAME(@profield)
                        SELECT @update = @update + CHAR(10) +   N', ' + QUOTENAME(@profield) + N' = ISNULL('
                                +  N'(CASE WHEN 1 = ' + @isrequired
                                            + N' THEN CASE WHEN '
                                            + N'SOURCE.' + QUOTENAME(@easyfieldname) + N'='
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
                                            + N'SOURCE.' + QUOTENAME(@easyfieldname)
                                            + N' END ELSE '
                                            + N'SOURCE.' + QUOTENAME(@easyfieldname)
                                            + N' END ) '
                                   + N', '
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
                                + QUOTENAME(@profield) ,
                                
                                @values = @values + CHAR(10) + N', SOURCE.' + QUOTENAME(@easyfieldname) 
                
                
                    END
        
                        
		
                FETCH NEXT FROM row_cursor INTO @protable, @easyfieldname,
                    @profield, @proposedvalue, @isrequired, @defaultvalue,
                    @fieldtype, @issuperfield
            END
				
        CLOSE row_cursor
        DEALLOCATE row_cursor    

        IF ( LEN(@select) > 0
             AND LEN(@insert) > 0 AND LEN(@update) > 0 AND LEN(@values) > 0
           ) 
            BEGIN
                SELECT  @sql = N'MERGE [dbo].' + QUOTENAME(@protable) + N'AS TARGET' + CHAR(10) + N'USING' + CHAR(10)
						+ N' (SELECT [User ID] AS [user_limeeasyid], [Name] AS [easy_fullname]' + @select +
                        + CHAR(10)
                        + N' FROM [dbo].[EASY__'
                        + @@easytable + N']'
                        + N') AS SOURCE ( [user_limeeasyid], [easy_fullname]' + @select + N')'
                        + CHAR(10)
                        + N' ON ( TARGET.[user_limeeasyid] = SOURCE.[user_limeeasyid] AND TARGET.[status] = 0 )'
						+ CHAR(10)
						+ N'WHEN MATCHED '
						+ CHAR(10)
						+ N'THEN'
						+ CHAR(10)
						+ N'UPDATE SET' 
						+ CHAR(10)
						+ N'[user_limeeasyid] = SOURCE.[user_limeeasyid], [easy_fullname] = SOURCE.[easy_fullname]' + @update
						+ CHAR(10)
						+ N'WHEN NOT MATCHED BY TARGET 
                    THEN
				INSERT  (
                          [status] ,
                          [createduser] ,
                          [createdtime] ,
                          [updateduser] ,
                          [timestamp] ,[user_limeeasyid] , [easy_fullname]' + @insert
                          + CHAR(10)
                          + N')'
                          + CHAR(10)
                          + N'VALUES ( 0, 1, GETDATE(), 1, GETDATE() ,
							SOURCE.[user_limeeasyid], SOURCE.[easy_fullname]' + @values 
							+CHAR(10)
							+ N');'
                          
                       
        
            END
    
        IF ( LEN(ISNULL(@sql, N'')) > 0 ) 
            BEGIN
                BEGIN TRY
                    --PRINT @sql
                    EXEC sp_executesql @sql

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