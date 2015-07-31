CREATE PROCEDURE [dbo].[csp_easytopro_fixtimestamps]
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
        SELECT  @sql = N''


		
		
        DECLARE row_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
            SELECT DISTINCT
                    e.[protable]
            FROM    [dbo].[EASY__FIELDMAPPING] e
            WHERE   e.[easytable] = @@easytable
                    AND LEN(e.[protable]) > 0
                    AND e.[transfertable] = 1
                    
        OPEN row_cursor
        FETCH NEXT FROM row_cursor INTO @protable
        WHILE @@FETCH_STATUS = 0 
            BEGIN
    
                IF ( @@easytable = N'ARCHIVE' ) 
                    BEGIN			
                        SELECT  @sql = @sql
                                + N', [createdtime] = DATEADD(s,e.[Time],e.[Date]), [createduser] = cw.[username]'
                                + CHAR(10)
                    END
                ELSE 
                    IF ( @@easytable = N'REFS' ) 
                        BEGIN
                            SELECT  @sql = @sql
                                    + N', [createdtime] = DATEADD(s,e.[Created time],e.[Created date]), [timestamp] = CASE WHEN ISDATE(DATEADD(s,e.[Updated time],e.[Updated date])) = 1 THEN DATEADD(s,e.[Updated time],e.[Updated date]) ELSE DATEADD(s,e.[Created time],e.[Created date]) END, [createduser] = cw.[username], [updateduser] = cw2.[username]'          
                                    + CHAR(10)
                        END
                    ELSE 
                        IF ( @@easytable = N'CONTACT' ) 
                            BEGIN			
                                SELECT  @sql = @sql
                                        + N', [createdtime] = DATEADD(s,e.[Created time],e.[Created date]), [timestamp] = CASE WHEN ISDATE(DATEADD(s,e.[Updated time],e.[Updated date])) = 1 THEN DATEADD(s,e.[Updated time],e.[Updated date]) ELSE DATEADD(s,e.[Created time],e.[Created date]) END, [createduser] = cw.[username], [updateduser] = cw2.[username]'          
                                        + CHAR(10)
                            END
                        ELSE 
                            IF ( @@easytable = N'PROJECT' ) 
                                BEGIN
                                    SELECT  @sql = @sql
                                            + N', [createdtime] = DATEADD(s,e.[Created time],e.[Created date]), [timestamp] = CASE WHEN ISDATE(DATEADD(s,e.[Updated time],e.[Updated date])) = 1 THEN DATEADD(s,e.[Updated time],e.[Updated date]) ELSE DATEADD(s,e.[Created time],e.[Created date]) END, [createduser] = cw.[username], [updateduser] = cw2.[username]'                                                        
                                            + CHAR(10)
                                END
                        
		
                FETCH NEXT FROM row_cursor INTO @protable
            END
				
        CLOSE row_cursor
        DEALLOCATE row_cursor    

        IF ( LEN(@sql) > 0 ) 
            BEGIN
                SELECT  @sql = N'UPDATE pro SET ' + RIGHT(@sql, LEN(@sql) - 1)
                        + N'FROM [dbo].' + QUOTENAME(@protable) + N' AS pro '
                        + CHAR(10)
                        + CASE @@easytable
                            WHEN N'ARCHIVE'
                            THEN N'INNER JOIN [dbo].[EASY__ARCHIVE] e ON pro.[archive_easytype] = e.[Type] AND pro.[archive_easykey1] = e.[Key 1] AND pro.[archive_easykey2]=e.[Key 2] '
								 + CHAR(10) + N'LEFT JOIN [dbo].[coworker] cw ON cw.[user_limeeasyid] = e.[User ID]'
                                 + CHAR(10) + N'WHERE pro.[status] = 0'
                                 + CHAR(10) + N'AND pro.[archive_easykey1] IS NOT NULL'
                                 + CHAR(10) + N'AND pro.[archive_easykey2] IS NOT NULL'
                                 + CHAR(10) + N'AND pro.[archive_easytype] IS NOT NULL'
                                 + CHAR(10) + N'AND ISDATE(DATEADD(s,e.[Time],e.[Date])) = 1'
                            WHEN N'REFS'
                            THEN N'INNER JOIN [dbo].[EASY__REFS] e ON pro.[contact_limeeasyid] = e.[Company ID] AND pro.[refs_limeeasyid] = e.[Reference ID] '
								 + CHAR(10) + N'LEFT JOIN [dbo].[coworker] cw ON cw.[user_limeeasyid] = e.[Created user ID]'
								 + CHAR(10) + N'LEFT JOIN [dbo].[coworker] cw2 ON cw2.[user_limeeasyid] = e.[Updated user ID]'
                                 + CHAR(10) + N'WHERE pro.[status] = 0'
                                 + CHAR(10) + N'AND pro.[contact_limeeasyid] IS NOT NULL '
                                 + CHAR(10) + N'AND pro.[refs_limeeasyid] IS NOT NULL'
                                 + CHAR(10) + N'AND ISDATE(DATEADD(s,e.[Created time],e.[Created date])) = 1'
                            WHEN N'CONTACT'
                            THEN N'INNER JOIN [dbo].[EASY__CONTACT] e ON e.[Company ID] = pro.[contact_limeeasyid] '
								 + CHAR(10) + N'LEFT JOIN [dbo].[coworker] cw ON cw.[user_limeeasyid] = e.[Created user ID]'
								 + CHAR(10) + N'LEFT JOIN [dbo].[coworker] cw2 ON cw2.[user_limeeasyid] = e.[Updated user ID]'
                                 + CHAR(10) + N'WHERE pro.[status] = 0'
								+ CHAR(10) + N'AND pro.[contact_limeeasyid] IS NOT NULL '
								+ CHAR(10) + N'AND ISDATE(DATEADD(s,e.[Created time],e.[Created date])) = 1'
                            WHEN N'PROJECT'
                            THEN N'INNER JOIN [dbo].[EASY__PROJECT] e ON e.[Project ID] = pro.[project_limeeasyid] '
								 + CHAR(10) + N'LEFT JOIN [dbo].[coworker] cw ON cw.[user_limeeasyid] = e.[Created user ID]'
								 + CHAR(10) + N'LEFT JOIN [dbo].[coworker] cw2 ON cw2.[user_limeeasyid] = e.[Updated user ID]'
                                 + CHAR(10) + N'WHERE pro.[status] = 0'
                                 + CHAR(10) + N'AND pro.[project_limeeasyid] IS NOT NULL '
								+ CHAR(10) + N'AND ISDATE(DATEADD(s,e.[Created time],e.[Created date])) = 1'
                            ELSE N''
                          END
                    
                BEGIN TRY
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