CREATE PROCEDURE  [dbo].[csp_easytopro_updatefixedrelationfields]
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
        DECLARE @relatedprotable NVARCHAR(64)
        DECLARE @relatedeasytable NVARCHAR(64)
        SELECT  @sql = N''


		--NEW 2014-09-12
		--UPDATED 2015-03-02 JSP: use migration field easy_fullname for mapping todo, document etc
        DECLARE @name_person_field AS NVARCHAR(48)
        SET @name_person_field = 'easy_fullname'
		
        --SELECT  @name_person_field = [profieldname]
        --FROM    [dbo].[EASY__FIELDMAPPING]
        --WHERE   [easyfieldid] = N'person_name'
        --        AND [easytable] = N'REFS'
		
        --SET @name_person_field = ISNULL(@name_person_field, N'')
		
        DECLARE row_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
            SELECT DISTINCT
                    e.[protable] ,
                    e2.[protable] ,
                    e.[relatedeasytable] ,
                    e.[profieldname]
            FROM    [dbo].[EASY__FIELDMAPPING] e
                    LEFT JOIN [dbo].[EASY__FIELDMAPPING] e2 ON e2.[easytable] = e.[relatedeasytable]
                                                              AND e.[active] = 1
                                                              AND e2.[transfertable] = 1
            WHERE   e.[easytable] = @@easytable
                    AND e.[issuperfield] = 2
                    AND LEN(e.[protable]) > 0
                    AND e.[transfertable] = 1
                    AND e2.[protable] IS NOT NULL
                    AND e.[relatedeasytable] IS NOT NULL



        OPEN row_cursor
        FETCH NEXT FROM row_cursor INTO @protable, @relatedprotable,
            @relatedeasytable, @profield
        WHILE @@FETCH_STATUS = 0 
            BEGIN
    
                IF ( @@easytable = N'ARCHIVE' ) 
                    BEGIN			
                        SELECT  @sql = CASE @relatedeasytable
                                         WHEN N'CONTACT'
                                         THEN @sql + N', '
                                              + QUOTENAME(@profield)
                                              + N' = CASE WHEN e.[Type] = 0 THEN (SELECT TOP 1 l.[id'
                                              + @relatedprotable + N'] '
                                              + N'FROM [dbo].'
                                              + QUOTENAME(@relatedprotable)
                                              + N'AS l WHERE l.['
                                              + LOWER(@relatedeasytable)
                                              + N'_limeeasyid] = e.[Key 1] AND l.[status] = 0) ELSE NULL END'
                                              + CHAR(10)
                                         WHEN N'PROJECT'
                                         THEN @sql + N', '
                                              + QUOTENAME(@profield)
                                              + N' = CASE WHEN e.[Type] = 2 THEN (SELECT TOP 1 l.[id'
                                              + @relatedprotable + N'] '
                                              + N'FROM [dbo].'
                                              + QUOTENAME(@relatedprotable)
                                              + N'AS l WHERE l.['
                                              + LOWER(@relatedeasytable)
                                              + N'_limeeasyid] = e.[Key 1] AND l.[status] = 0) ELSE NULL END'
                                              + CHAR(10)
                                         WHEN N'USER'
                                         THEN @sql + N', '
                                              + QUOTENAME(@profield)
                                              + N' =  (SELECT TOP 1 l.[id'
                                              + @relatedprotable + N'] '
                                              + N'FROM [dbo].'
                                              + QUOTENAME(@relatedprotable)
                                              + N'AS l WHERE l.['
                                              + LOWER(@relatedeasytable)
                                              + N'_limeeasyid] = e.[User ID] AND l.[status] = 0)'
                                              + CHAR(10)
                                         WHEN N'REFS'
                                         THEN @sql
                                              + CASE WHEN LEN(@name_person_field) = 0
                                                     THEN N''
                                                     ELSE N', '
                                                          + QUOTENAME(@profield)
                                                          + N' = CASE WHEN e.[Type] = 0 THEN (SELECT TOP 1 l.[id'
                                                          + @relatedprotable
                                                          + N'] '
                                                          + N'FROM [dbo].'
                                                          + QUOTENAME(@relatedprotable)
                                                          + N'AS l WHERE l.[contact_limeeasyid] = e.[Key 1] AND  l.'
                                                          + QUOTENAME(@name_person_field)
                                                          + N' = e.[Reference] AND l.[status] = 0)'
                                                          + CHAR(10)
                                                          + N' ELSE NULL END'
                                                          + CHAR(10)
                                                END
                                         ELSE @sql
                                       END
                    END
                ELSE 
                    IF ( @@easytable = N'REFS' ) 
                        BEGIN
                            SELECT  @sql = CASE @relatedeasytable
                                             WHEN N'CONTACT'
                                             THEN @sql + N', '
                                                  + QUOTENAME(@profield)
                                                  + N' = (SELECT TOP 1 l.[id'
                                                  + @relatedprotable + N'] '
                                                  + N'FROM [dbo].'
                                                  + QUOTENAME(@relatedprotable)
                                                  + N'AS l WHERE l.['
                                                  + LOWER(@relatedeasytable)
                                                  + N'_limeeasyid] = e.[Company ID] AND l.[status] = 0)'
                                                  + CHAR(10)
                                             ELSE @sql
                                           END
                        END
                    ELSE 
                        IF ( @@easytable = N'TODO' ) 
                            BEGIN			
                                SELECT  @sql = CASE @relatedeasytable
                                                 WHEN N'CONTACT'
                                                 THEN @sql + N', '
                                                      + QUOTENAME(@profield)
                                                      + N' = CASE WHEN e.[Type] IN (0,8) THEN (SELECT TOP 1 l.[id'
                                                      + @relatedprotable
                                                      + N'] ' + N'FROM [dbo].'
                                                      + QUOTENAME(@relatedprotable)
                                                      + N'AS l WHERE l.['
                                                      + LOWER(@relatedeasytable)
                                                      + N'_limeeasyid] = e.[Key 1] AND l.[status] = 0) ELSE NULL END'
                                                      + CHAR(10)
                                                 WHEN N'PROJECT'
                                                 THEN @sql + N', '
                                                      + QUOTENAME(@profield)
                                                      + N' = CASE WHEN e.[Type] = 2 THEN (SELECT TOP 1 l.[id'
                                                      + @relatedprotable
                                                      + N'] ' + N'FROM [dbo].'
                                                      + QUOTENAME(@relatedprotable)
                                                      + N'AS l WHERE l.['
                                                      + LOWER(@relatedeasytable)
                                                      + N'_limeeasyid] = e.[Key 1] AND l.[status] = 0) ELSE NULL END'
                                                      + CHAR(10)
                                                 WHEN N'USER'
                                                 THEN @sql + N', '
                                                      + QUOTENAME(@profield)
                                                      + N' =  (SELECT TOP 1 l.[id'
                                                      + @relatedprotable
                                                      + N'] ' + N'FROM [dbo].'
                                                      + QUOTENAME(@relatedprotable)
                                                      + N'AS l WHERE l.['
                                                      + LOWER(@relatedeasytable)
                                                      + N'_limeeasyid] = e.[User ID] AND l.[status] = 0)'
                                                      + CHAR(10)
                                                 WHEN N'REFS'
                                                 THEN @sql
                                                      + CASE WHEN LEN(@name_person_field) = 0
                                                             THEN N''
                                                             ELSE N', '
                                                              + QUOTENAME(@profield)
                                                              + N' = CASE WHEN e.[Type] IN ( 0, 8 ) THEN (SELECT TOP 1 l.[id'
                                                              + @relatedprotable
                                                              + N'] '
                                                              + N'FROM [dbo].'
                                                              + QUOTENAME(@relatedprotable)
                                                              + N'AS l WHERE l.[contact_limeeasyid] = e.[Key 1] AND CHARINDEX(N''('' + l.'
                                                              + QUOTENAME(@name_person_field)
                                                              + N' + N'')'', e.[Description])>0 AND l.[status] = 0)'
                                                              + CHAR(10)
                                                              + N' ELSE NULL END'
                                                              + CHAR(10)
                                                        END
                                                 ELSE @sql
                                               END
                            END
                        ELSE 
                            IF ( @@easytable = N'TIME' ) 
                                BEGIN
                                    SELECT  @sql = CASE @relatedeasytable
                                                     WHEN N'CONTACT'
                                                     THEN @sql + N', '
                                                          + QUOTENAME(@profield)
                                                          + N' = (SELECT TOP 1 l.[id'
                                                          + @relatedprotable
                                                          + N'] '
                                                          + N'FROM [dbo].'
                                                          + QUOTENAME(@relatedprotable)
                                                          + N' AS l WHERE l.['
                                                          + LOWER(@relatedeasytable)
                                                          + N'_limeeasyid] = e.[Company ID] AND l.[status] = 0)'
                                                          + CHAR(10)
                                                     WHEN N'USER'
                                                     THEN @sql + N', '
                                                          + QUOTENAME(@profield)
                                                          + N' =  (SELECT TOP 1 l.[id'
                                                          + @relatedprotable
                                                          + N'] '
                                                          + N'FROM [dbo].'
                                                          + QUOTENAME(@relatedprotable)
                                                          + N' AS l WHERE l.['
                                                          + LOWER(@relatedeasytable)
                                                          + N'_limeeasyid] = e.[User ID] AND l.[status] = 0)'
                                                          + CHAR(10)
                                                     ELSE @sql
                                                   END
                                END
                        
		
                FETCH NEXT FROM row_cursor INTO @protable, @relatedprotable,
                    @relatedeasytable, @profield
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
                                 + CHAR(10) + N'WHERE pro.[status] = 0'
                            WHEN N'REFS'
                            THEN N'INNER JOIN [dbo].[EASY__REFS] e ON pro.[contact_limeeasyid] = e.[Company ID] AND pro.[refs_limeeasyid] = e.[Reference ID] '
                                 + CHAR(10) + N'WHERE pro.[status] = 0'
                            WHEN N'TODO'
                            THEN N'INNER JOIN [dbo].[EASY__TODO] e ON pro.[todo_easytype] = e.[Type] AND pro.[todo_easykey1] = e.[Key 1] AND pro.[todo_easykey2]=e.[Key 2] '
                                 + CHAR(10) + N'WHERE pro.[status] = 0'
                            WHEN N'TIME'
                            THEN N'INNER JOIN [dbo].[EASY__TIME] e ON pro.[contact_limeeasyid] = e.[Company ID] AND pro.[time_limeeasyid] = e.[Time ID] '
                                 + CHAR(10) + N'WHERE pro.[status] = 0'
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