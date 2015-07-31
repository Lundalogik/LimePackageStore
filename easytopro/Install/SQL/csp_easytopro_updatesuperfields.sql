CREATE PROCEDURE [dbo].[csp_easytopro_updatesuperfields]
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
        DECLARE @protable NVARCHAR(64) 
        DECLARE @profield NVARCHAR(64) 
        DECLARE @profieldtype INT
        DECLARE @idfieldmapping INT
        DECLARE @easyfieldid NVARCHAR(64)
        DECLARE @easyfieldtype INT
        DECLARE @proposedvalue NVARCHAR(128)
        DECLARE @relatedtable NVARCHAR(64)
        DECLARE @idcategory INT
        DECLARE @defaultvalue NVARCHAR(128) 
        DECLARE @isrequired NVARCHAR(1)
            --DECLARE @relatedeasytable NVARCHAR(64)
        SELECT  @sql = N''
        SET @@errormessage = N''
        SELECT TOP 1
                @relatedtable = [protable]
        FROM    [dbo].[EASY__FIELDMAPPING]
        WHERE   [easytable] = N'USER'
                AND LEN(ISNULL([protable], N'')) > 0
                AND [transfertable] = 1


        DECLARE row_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
            SELECT  e.[idfieldmapping] ,
                    e.[protable] ,
                    e.[profieldname] ,
                    e.[easyprofieldtype] ,
                    e.[easyfieldid] ,
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
                    e.[easyfieldtype] ,
                    ( SELECT TOP 1
                                CAST(a.[value] AS INT)
                      FROM      [dbo].[fieldcache] f
                                INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                              AND t.[name] = e.[protable]
                                INNER JOIN [dbo].[attributedata] a ON f.[idfield] = a.[idrecord]
                                                              AND a.[owner] = N'field'
                                                              AND a.[name] = 'idcategory'
                      WHERE     f.[name] = e.[profieldname]
                    )
            FROM    [dbo].[EASY__FIELDMAPPING] e
            WHERE   e.[easytable] = @@easytable
                    AND e.[issuperfield] = 1
                    AND LEN(e.[protable]) > 0
                    AND e.[transfertable] = 1
                    AND e.[active] = 1
                        


        OPEN row_cursor
        FETCH NEXT FROM row_cursor INTO @idfieldmapping, @protable, @profield,
            @profieldtype, @easyfieldid, @proposedvalue, @isrequired,
            @defaultvalue, @easyfieldtype, @idcategory
        WHILE @@FETCH_STATUS = 0
            AND @@errormessage = N'' 
            BEGIN
                        
                    -- GET DATA TO FIELD
                            --DECLARE @sql NVARCHAR(MAX)
                SELECT  @sql = N''
                    
                SELECT  @sql = CASE WHEN ISNULL(@profieldtype, -1) IN ( 1, 12,
                                                              23 ) 	-- text, link, formated text
                                         THEN
						-- START SQL FOR TEXT
                                         N' UPDATE  pro
							SET   pro.' + QUOTENAME(@profield) + N'= 
									ISNULL(
										( SELECT TOP 1 ' + N'(CASE WHEN 1 = '
                                         + @isrequired
                                         + N' THEN CASE WHEN ed.[Data] =N'''
                                         + ISNULL(@defaultvalue, N'')
                                         + N''' THEN N'''
                                         + ISNULL(@proposedvalue, N'') + N''''
                                         + N' ELSE ed.[Data]  END ELSE ed.[Data] END ) '
                                         + CHAR(10)
                                         + N'FROM   [dbo].[EASY__DATA] ed 
										WHERE  ed.[Field ID] = '
                                         + CAST(ISNULL(@easyfieldid, -999) AS NVARCHAR(32))

						-- ADD TYPE SPECIFIC CRITERIA
                                         + CASE WHEN ( @easyfieldtype = 0 ) -- CONTACT (company)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid] '
                                                WHEN ( @easyfieldtype = 1 ) -- REFS (person)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[refs_limeeasyid] '
                                                WHEN ( @easyfieldtype = 2 ) -- PROJECT (project)
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid] '
                                                WHEN ( @easyfieldtype = 6 ) -- ARCHIVE (document) // CONTACT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                                WHEN ( @easyfieldtype = 7 ) -- ARCHIVE (document) // PROJECT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                           END
						
						-- END SQL
                                         + N' 
										)
									  ,  N''' + ISNULL(@proposedvalue, N'')
                                         + N''')'
                                    WHEN ( ISNULL(@profieldtype, -1) = 7 ) -- time
                                         THEN
						-- START SQL FOR TIME
                                         N' UPDATE  pro
							SET   pro.' + QUOTENAME(@profield) + N'= 
									ISNULL(( SELECT TOP 1 ISNULL(ed.[Data] , '
                                         + ISNULL(@proposedvalue, N'') + N')'
                                         + CHAR(10)
                                         + N'FROM   [dbo].[EASY__DATA] ed 
										WHERE  ed.[Field ID] = '
                                         + CAST(ISNULL(@easyfieldid, -999) AS NVARCHAR(32))
						
						-- ADD TYPE SPECIFIC CRITERIA		
                                         + CASE WHEN ( @easyfieldtype = 0 ) -- CONTACT (company)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid] '
                                                WHEN ( @easyfieldtype = 1 ) -- REFS (person)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[refs_limeeasyid] '
                                                WHEN ( @easyfieldtype = 2 ) -- PROJECT (project)
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid] '
                                                WHEN ( @easyfieldtype = 6 ) -- ARCHIVE (document) // CONTACT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                                WHEN ( @easyfieldtype = 7 ) -- ARCHIVE (document) // PROJECT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                           END	
                                       
						-- END SQL / CHECK IS DATE
                                         + N' AND ISDATE(ed.[Data]) = 1
										),  ' + ISNULL(@proposedvalue, N'')
                                         + N')'
                                    WHEN ( ISNULL(@profieldtype, -1) = 3 ) -- int
                                         THEN
						-- START SQL FOR INT
                                         N' UPDATE  pro
							SET   pro.' + QUOTENAME(@profield) + N'= 
									ISNULL(( SELECT TOP 1 ISNULL(ed.[Data], '
                                         + ISNULL(@proposedvalue, N'') + N')'
                                         + CHAR(10)
                                         + N'FROM   [dbo].[EASY__DATA] ed 
										WHERE  ed.[Field ID] = '
                                         + CAST(ISNULL(@easyfieldid, -999) AS NVARCHAR(32)) 
						
						-- ADD TYPE SPECIFIC CRITERIA		
                                         + CASE WHEN ( @easyfieldtype = 0 ) -- CONTACT (company)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid] '
                                                WHEN ( @easyfieldtype = 1 ) -- REFS (person)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[refs_limeeasyid] '
                                                WHEN ( @easyfieldtype = 2 ) -- PROJECT (project)
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid] '
                                                WHEN ( @easyfieldtype = 6 ) -- ARCHIVE (document) // CONTACT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                                WHEN ( @easyfieldtype = 7 ) -- ARCHIVE (document) // PROJECT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                           END	
						
						-- END SQL / CHECK IS INT
                                         + N'AND PATINDEX(N''[^-]%[^0-9]%'', ed.[Data]) = 0 
										),  ' + ISNULL(@proposedvalue, N'')
                                         + N')'
                                    WHEN ( ISNULL(@profieldtype, -1) = 13 ) -- yes/no
                                         THEN
						-- START SQL FOR YES/NO
                                         N' UPDATE  pro
							SET   pro.' + QUOTENAME(@profield) + N'= 
									ISNULL(
										( SELECT TOP 1 ISNULL(ed.[Data], '
                                         + ISNULL(@proposedvalue, N'') + N')'
                                         + CHAR(10)
                                         + N'FROM   [dbo].[EASY__DATA] ed 
										WHERE  ed.[Field ID] = '
                                         + CAST(ISNULL(@easyfieldid, -999) AS NVARCHAR(32))
						
						-- ADD TYPE SPECIFIC CRITERIA		
                                         + CASE WHEN ( @easyfieldtype = 0 ) -- CONTACT (company)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid] '
                                                WHEN ( @easyfieldtype = 1 ) -- REFS (person)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[refs_limeeasyid] '
                                                WHEN ( @easyfieldtype = 2 ) -- PROJECT (project)
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid] '
                                                WHEN ( @easyfieldtype = 6 ) -- ARCHIVE (document) // CONTACT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                                WHEN ( @easyfieldtype = 7 ) -- ARCHIVE (document) // PROJECT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                           END	
						-- END SQL
                                         + N'),  ' + ISNULL(@proposedvalue,
                                                            N'') + N')'
                                    WHEN ( ( ISNULL(@profieldtype, -1) = 16 )
                                           AND ( LEN(ISNULL(@relatedtable, N'')) > 0 )
                                         ) -- relation
                                         THEN
						-- START SQL FOR RELATION
                                         N' UPDATE  pro
							SET   pro.' + QUOTENAME(@profield) + N'= 
									( SELECT TOP 1 c.[id' + @relatedtable
                                         + N'] ' + CHAR(10)
                                         + N'FROM   [dbo].[EASY__DATA] ed 
										INNER JOIN [dbo].'
                                         + QUOTENAME(@relatedtable)
                                         + N' c ON (CAST(c.[user_limeeasyid] AS NVARCHAR(32)) = ed.[Data] AND c.[status] = 0)
										WHERE  ed.[Field ID] = '
                                         + CAST(ISNULL(@easyfieldid, -999) AS NVARCHAR(32)) 
						
						-- ADD TYPE SPECIFIC CRITERIA		
                                         + CASE WHEN ( @easyfieldtype = 0 ) -- CONTACT (company)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid] '
                                                WHEN ( @easyfieldtype = 1 ) -- REFS (person)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[refs_limeeasyid] '
                                                WHEN ( @easyfieldtype = 2 ) -- PROJECT (project)
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid] '
                                                WHEN ( @easyfieldtype = 6 ) -- ARCHIVE (document) // CONTACT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                                WHEN ( @easyfieldtype = 7 ) -- ARCHIVE (document) // PROJECT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                           END	
						
						-- END SQL / CHECK IS INT
                                         + N')'
                                    WHEN ( ISNULL(@profieldtype, -1) = 21 ) -- option
                                         THEN
						-- START SQL FOR OPTION
                                         N' UPDATE  pro
							SET   pro.' + QUOTENAME(@profield) + N'=   
									
										ISNULL( CAST( 
										
										
										
										( SELECT TOP 1 (CASE WHEN 1 = '
                                         + @isrequired + N' THEN CASE WHEN '
                                         + N' ISNULL([idstringlimepro],0) = '
                                         + ISNULL(@defaultvalue, N'0')
                                         + N' THEN ' + ISNULL(@proposedvalue,
                                                              N'NULL')
                                         + N' ELSE [idstringlimepro]  END ELSE [idstringlimepro] END ) 
     										FROM [dbo].[EASY__DATA] ed 
										INNER JOIN [dbo].[EASY__OPTIONMAPPING] o ON ed.[Data] = o.[easyvalue] AND o.[idcategorylimepro] = '
                                         + CAST(@idcategory AS NVARCHAR(32))
                                         + CHAR(10)
                                         + N'WHERE  ed.[Field ID] =  '
                                         + CAST(ISNULL(@easyfieldid, -999) AS NVARCHAR(32))
                                            
										
						-- ADD TYPE SPECIFIC CRITERIA		
                                         + CASE WHEN ( @easyfieldtype = 0 ) -- CONTACT (company)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid] '
                                                WHEN ( @easyfieldtype = 1 ) -- REFS (person)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[refs_limeeasyid] '
                                                WHEN ( @easyfieldtype = 2 ) -- PROJECT (project)
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid] '
                                                WHEN ( @easyfieldtype = 6 ) -- ARCHIVE (document) // CONTACT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                                WHEN ( @easyfieldtype = 7 ) -- ARCHIVE (document) // PROJECT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                           END	
						-- END SQL
                                         + N' ) AS NVARCHAR(32))' + N',  '
                                         + ISNULL(@proposedvalue, N'') + N')'
                                    WHEN ( ISNULL(@profieldtype, -1) = 20 ) -- set
                                         THEN N' UPDATE  pro
							SET   pro.' + QUOTENAME(@profield) + N'= 
									ISNULL(' + N'(CASE WHEN 1 = '
                                         + @isrequired + N' THEN CASE WHEN '
                                         + N'( SELECT CAST('';'' + CAST(o.[idstringlimepro] AS NVARCHAR(32)) AS NVARCHAR(MAX))
										FROM   [dbo].[EASY__DATA] ed 
										INNER JOIN [dbo].[EASY__OPTIONMAPPING] o ON o.[easyvalue] = ed.[Data] AND o.[idcategorylimepro] = '
                                         + CAST(@idcategory AS NVARCHAR(32))
                                         + CHAR(10)
                                         + N' WHERE  ed.[Field ID] = '
                                         + CAST(ISNULL(@easyfieldid, -999) AS NVARCHAR(32))
										
									-- ADD TYPE SPECIFIC CRITERIA		
                                         + CASE WHEN ( @easyfieldtype = 0 ) -- CONTACT (company)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid] '
                                                WHEN ( @easyfieldtype = 1 ) -- REFS (person)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[refs_limeeasyid] '
                                                WHEN ( @easyfieldtype = 2 ) -- PROJECT (project)
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid] '
                                                WHEN ( @easyfieldtype = 6 ) -- ARCHIVE (document) // CONTACT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                                WHEN ( @easyfieldtype = 7 ) -- ARCHIVE (document) // PROJECT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                           END	
						-- END SQL
                                         + CHAR(10)
                                         + N'ORDER BY o.[idstringlimepro]
										FOR XML PATH('''')
										) + N'';''' + N'='
                                         + CASE WHEN LEN(ISNULL(@defaultvalue,
                                                              N'')) > 0
                                                THEN N''';'
                                                     + ISNULL(@defaultvalue,
                                                              N'') + N';'')'
                                                ELSE N'N'''' '
                                           END + N' THEN '
                                         + CASE WHEN LEN(ISNULL(@proposedvalue,
                                                              N'')) > 0
                                                THEN N''';'
                                                     + ISNULL(@proposedvalue,
                                                              N'') + N';'')'
                                                ELSE N'N'''' '
                                           END + N' ELSE '
                                         + N'( SELECT CAST('';'' + CAST(o.[idstringlimepro] AS NVARCHAR(32)) AS NVARCHAR(MAX))
										FROM   [dbo].[EASY__DATA] ed 
										INNER JOIN [dbo].[EASY__OPTIONMAPPING] o ON o.[easyvalue] = ed.[Data] AND o.[idcategorylimepro] = '
                                         + CAST(@idcategory AS NVARCHAR(32))
                                         + CHAR(10)
                                         + N' WHERE  ed.[Field ID] = '
                                         + CAST(ISNULL(@easyfieldid, -999) AS NVARCHAR(32))
										
									-- ADD TYPE SPECIFIC CRITERIA		
                                         + CASE WHEN ( @easyfieldtype = 0 ) -- CONTACT (company)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid] '
                                                WHEN ( @easyfieldtype = 1 ) -- REFS (person)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[refs_limeeasyid] '
                                                WHEN ( @easyfieldtype = 2 ) -- PROJECT (project)
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid] '
                                                WHEN ( @easyfieldtype = 6 ) -- ARCHIVE (document) // CONTACT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                                WHEN ( @easyfieldtype = 7 ) -- ARCHIVE (document) // PROJECT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                           END	
						-- END SQL
                                         + CHAR(10)
                                         + N'ORDER BY o.[idstringlimepro]
										FOR XML PATH('''')
										) + N'';''' + N' END ELSE '
                                         + N'( SELECT CAST('';'' + CAST(o.[idstringlimepro] AS NVARCHAR(32)) AS NVARCHAR(MAX))
										FROM   [dbo].[EASY__DATA] ed 
										INNER JOIN [dbo].[EASY__OPTIONMAPPING] o ON o.[easyvalue] = ed.[Data] AND o.[idcategorylimepro] = '
                                         + CAST(@idcategory AS NVARCHAR(32))
                                         + CHAR(10)
                                         + N' WHERE  ed.[Field ID] = '
                                         + CAST(ISNULL(@easyfieldid, -999) AS NVARCHAR(32))
										
									-- ADD TYPE SPECIFIC CRITERIA		
                                         + CASE WHEN ( @easyfieldtype = 0 ) -- CONTACT (company)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid] '
                                                WHEN ( @easyfieldtype = 1 ) -- REFS (person)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[refs_limeeasyid] '
                                                WHEN ( @easyfieldtype = 2 ) -- PROJECT (project)
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid] '
                                                WHEN ( @easyfieldtype = 6 ) -- ARCHIVE (document) // CONTACT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                                WHEN ( @easyfieldtype = 7 ) -- ARCHIVE (document) // PROJECT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                           END	
						-- END SQL
                                         + CHAR(10)
                                         + N'ORDER BY o.[idstringlimepro]
										FOR XML PATH('''')
										) + N'';''' + N' END ) ' + N', '
                                         + CASE WHEN LEN(ISNULL(@proposedvalue,
                                                              N'')) > 0
                                                THEN N''';'
                                                     + ISNULL(@proposedvalue,
                                                              N'') + N';'')'
                                                ELSE N'N'''')'
                                           END
                               END
                    
                IF ( LEN(ISNULL(@sql, N'')) > 0 ) 
                    BEGIN
                        SELECT  @sql = @sql + N' FROM [dbo].'
                                + QUOTENAME(@protable) + N' AS pro 
								WHERE [status] = 0'
                                + CASE WHEN ( @easyfieldtype = 0 ) -- CONTACT (company)
                                            THEN CHAR(10)
                                            + N'AND  pro.[contact_limeeasyid] IS NOT NULL '
                                       WHEN ( @easyfieldtype = 1 ) -- REFS (person)
                                            THEN CHAR(10)
                                            + N'AND pro.[contact_limeeasyid] IS NOT NULL
										AND pro.[refs_limeeasyid] IS NOT NULL'
                                       WHEN ( @easyfieldtype = 2 ) -- PROJECT (project)
                                            THEN N'AND pro.[project_limeeasyid] IS NOT NULL'
                                       WHEN ( @easyfieldtype = 6 ) -- ARCHIVE (document) // CONTACT ARCHIVE
                                            THEN CHAR(10)
                                            + N'AND pro.[contact_limeeasyid] IS NOT NULL
										AND pro.[archive_limeeasyid] IS NOT NULL '
                                       WHEN ( @easyfieldtype = 7 ) -- ARCHIVE (document) // PROJECT ARCHIVE
                                            THEN CHAR(10)
                                            + N'AND pro.[project_limeeasyid] IS NOT NULL
										AND pro.[archive_limeeasyid] IS NOT NULL '
                                  END
                    END
								
                            
                BEGIN TRY
                    EXEC sp_executesql @sql
                        
                        --PRINT @sql + CHAR(10) + REPLICATE(N'-', 20) + CHAR(10)
                        
                    SET @@errormessage = N''
                END TRY
                BEGIN CATCH
                        --PRINT ERROR_MESSAGE()
                    SET @@errormessage = ERROR_MESSAGE()
                END CATCH
                    
                    
                        
		
                FETCH NEXT FROM row_cursor INTO @idfieldmapping, @protable,
                    @profield, @profieldtype, @easyfieldid, @proposedvalue,
                    @isrequired, @defaultvalue, @easyfieldtype, @idcategory
            END
				
        CLOSE row_cursor
        DEALLOCATE row_cursor    

                    

        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''
    END