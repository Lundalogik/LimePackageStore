CREATE PROCEDURE [dbo].[csp_easytopro_inserteasyhistory]
    (
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
         
        
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @easytable NVARCHAR(64)
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
        DECLARE @easyfieldid NVARCHAR(64)
        DECLARE @defaultvalue NVARCHAR(128) 
        DECLARE @isrequired NVARCHAR(1)

-- SET INITIAL VALUES
        SELECT  @easytable = N'HISTORY' 
        SELECT  @sql = N''
        SELECT  @select = N''
        SELECT  @insert = N''
            


        DECLARE row_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
            SELECT DISTINCT
                    e.[protable] ,
                    e2.[protable] ,
                    e.[easyfieldid] ,
                    e.[easyfieldname] ,
                    e.[relatedeasytable] ,
                    e.[profieldname] ,
                    CASE WHEN e.[relatedeasytable] = N'REFS'
                    THEN 
                     N'(SELECT TOP 1 [id' + e2.[protable] + N'] '
                    + N'FROM [dbo].' + QUOTENAME(e2.[protable]) + N' WHERE ['
                    + LOWER(e.[relatedeasytable]) + N'_limeeasyid] = h.['
                    + LOWER(e.[relatedeasytable])
                    + '_limeeasyid] ' 
                    + N' AND [contact_limeeasyid] = h.[contact_limeeasyid]'
                    + N' AND [status] = 0)'
                    ELSE
                    N'(SELECT TOP 1 [id' + e2.[protable] + N'] '
                    + N'FROM [dbo].' + QUOTENAME(e2.[protable]) + N' WHERE ['
                    + LOWER(e.[relatedeasytable]) + N'_limeeasyid] = h.['
                    + LOWER(e.[relatedeasytable])
                    + '_limeeasyid] AND [status] = 0)' END ,
                    e.[issuperfield] ,
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
                    e.[easyprofieldtype]
            FROM    [dbo].[EASY__FIELDMAPPING] e
                    LEFT JOIN [dbo].[EASY__FIELDMAPPING] e2 ON e2.[easytable] = e.[relatedeasytable]
                                                              AND e.[active] = 1
                                                              AND e2.[transfertable] = 1
            WHERE   e.[easytable] = @easytable
                    AND e.[issuperfield] IN ( 0, 2 )
                    AND LEN(e.[protable]) > 0
                    AND e.[transfertable] = 1
                    AND ( ( e2.[protable] IS NOT NULL )
                          OR ( [e].[issuperfield] = 0 )
                        )
                    AND ( ( e.[relatedeasytable] IS NOT NULL )
                          OR ( [e].[issuperfield] = 0 )
                        )



        OPEN row_cursor
        FETCH NEXT FROM row_cursor INTO @protable, @relatedprotable,
            @easyfieldid, @easyfieldname, @relatedeasytable, @profield,
            @selectstatement, @issuperfield, @proposedvalue, @isrequired,
            @defaultvalue, @fieldtype
        WHILE @@FETCH_STATUS = 0 
            BEGIN
    
                IF ( @easytable = N'HISTORY' ) 
                    BEGIN		
				
                        SELECT  @select = @select + CHAR(10) + N', '
                                + CASE WHEN @issuperfield = 2
                                       THEN @selectstatement
                                       WHEN @issuperfield = 0
                                            AND @easyfieldid = N'history_type'
                                       THEN N'ISNULL( (CASE WHEN 1 = '
                                            + @isrequired
                                            + N' THEN CASE WHEN '
                                            + N'ISNULL(( SELECT TOP 1
                                                              o.[idstringlimepro]
                                                            FROM
                                                              [dbo].[EASY__OPTIONMAPPING]
                                                              AS o
                                                            WHERE
                                                              o.[easystringid] = 3
                                                              AND o.[easyvalue] = h.[historytype]
                                                          ), 0) = '
                                            + ISNULL(@defaultvalue, N'0')
                                            + N' THEN '
                                            + ISNULL(@proposedvalue, N'')
                                            + N' ELSE '
                                            + N' ISNULL(( SELECT TOP 1
                                                              o.[idstringlimepro]
                                                            FROM
                                                              [dbo].[EASY__OPTIONMAPPING]
                                                              AS o
                                                            WHERE
                                                              o.[easystringid] = 3
                                                              AND o.[easyvalue] = h.[historytype]
                                                          ),' + ISNULL(@proposedvalue, N'') + N') ' + N' END '
                                            + CHAR(10) + N' ELSE '
                                            + N' ISNULL(( SELECT TOP 1
                                                              o.[idstringlimepro]
                                                            FROM
                                                              [dbo].[EASY__OPTIONMAPPING]
                                                              AS o
                                                            WHERE
                                                              o.[easystringid] = 3
                                                              AND o.[easyvalue] = h.[historytype]
                                                          ),' + ISNULL(@defaultvalue, N'') + N') ' + N' END '
                                            + N'), ' + ISNULL(@proposedvalue,
                                                              N'') + N')'
                                       ELSE N'ISNULL(' + N'(CASE WHEN 1 = '
                                            + @isrequired
                                            + N' THEN CASE WHEN ISNULL('
                                            + QUOTENAME(@easyfieldname) 
                                            + CASE WHEN @fieldtype IN ( 1, 12,
                                                              23 )
                                                   THEN N', ' + N'''''' +   N')=N'''
                                                        + ISNULL(@defaultvalue,
                                                              N'') + N''''
                                                   WHEN @fieldtype = 20
                                                   THEN N', ' + N'''''' +   N')=' + CASE WHEN LEN(ISNULL(@defaultvalue,
                                                              N'')) > 0
                                                             THEN N''';'
                                                              + ISNULL(@defaultvalue,
                                                              N'') + N';'')'
                                                             ELSE N'N'''' '
                                                        END
                                                   ELSE N', ' + N'''''' +   N')=' + ISNULL(@defaultvalue,
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
                                              END + N' ELSE ISNULL('
                                            + QUOTENAME(@easyfieldname)
                                            + CASE WHEN @fieldtype IN ( 1, 12,
                                                              23 )
                                                   THEN N', N'''
                                                        + ISNULL(@proposedvalue,
                                                              N'') + N''''
                                                   WHEN @fieldtype = 20
                                                   THEN CASE WHEN LEN(ISNULL(@proposedvalue,
                                                              N'')) > 0
                                                             THEN N', '';'
                                                              + ISNULL(@proposedvalue,
                                                              N'') + N';'')'
                                                             ELSE N', N'''' '
                                                        END
                                                   ELSE N', ' + ISNULL(@proposedvalue,
                                                              N'')
                                              END + N') '
                                            + N' END ELSE ISNULL( '
                                            + QUOTENAME(@easyfieldname)
                                            + CASE WHEN @fieldtype IN ( 1, 12,
                                                              23 )
                                                   THEN N', N'''
                                                        + ISNULL(@defaultvalue,
                                                              N'') + N''''
                                                   WHEN @fieldtype = 20
                                                   THEN CASE WHEN LEN(ISNULL(@defaultvalue,
                                                              N'')) > 0
                                                             THEN N', '';'
                                                              + ISNULL(@defaultvalue,
                                                              N'') + N';'')'
                                                             ELSE N', N'''' '
                                                        END
                                                   ELSE N', ' + ISNULL(@defaultvalue,
                                                              N'')
                                              END + N') '
                                            + N' END ) ' + N', '
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
                                                             ELSE N'N'''')'
                                                        END
                                                   ELSE ISNULL(@proposedvalue,
                                                              N'')
                                              END + N')'
                                  END
                        SELECT  @insert = @insert + CHAR(10) + N', '
                                + QUOTENAME(@profield)
                
                
                    END
        
                        
		
                FETCH NEXT FROM row_cursor INTO @protable, @relatedprotable,
                    @easyfieldid, @easyfieldname, @relatedeasytable, @profield,
                    @selectstatement, @issuperfield, @proposedvalue,
                    @isrequired, @defaultvalue, @fieldtype
            END
				
        CLOSE row_cursor
        DEALLOCATE row_cursor    


        IF ( LEN(@select) > 0
             AND LEN(@insert) > 0
           ) 
            BEGIN
                SELECT  @sql = N'INSERT INTO [dbo].' + QUOTENAME(@protable)
                        + CHAR(10) + N' ([status], [createduser], [createdtime], [updateduser],[timestamp]' + @insert + N')' + CHAR(10)
                        + N'SELECT 0, 1, GETDATE(), 1, GETDATE() ' + @select + CHAR(10)
                        + N'FROM [dbo].[EASY__SPLITTEDHISTORY] h'
        
            END
    
        IF ( LEN(ISNULL(@sql, N'')) > 0 ) 
            BEGIN
                BEGIN TRY
                    --PRINT @sql
                    EXEC sp_executesql @sql
                    SET @@errormessage = N''
                END TRY
                BEGIN CATCH
                    SET @@errormessage = ERROR_MESSAGE()
                END CATCH
            END
                
                
        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''
    END