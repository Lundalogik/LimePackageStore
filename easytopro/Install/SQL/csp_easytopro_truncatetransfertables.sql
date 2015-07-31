CREATE PROCEDURE [dbo].[csp_easytopro_truncatetransfertables]
    (
      @@linkprojecttocompanytable NVARCHAR(64) = NULL ,
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
         
        
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;

        DECLARE @protable NVARCHAR(64)
        DECLARE @easytable NVARCHAR(64)
        DECLARE @sql NVARCHAR(MAX)

        SET @@errormessage = N''

        DECLARE table_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
            SELECT DISTINCT
                    [protable] ,
                    [easytable]
            FROM    [dbo].[EASY__FIELDMAPPING]
            WHERE   [transfertable] = 1
                    AND LEN(ISNULL([protable], N'')) > 0
                    AND [easytable] != N'USER'
		

        OPEN table_cursor
        FETCH NEXT FROM table_cursor INTO @protable, @easytable      
        WHILE @@FETCH_STATUS = 0
            AND @@errormessage = N'' 
            BEGIN
                    
                BEGIN TRY
                    IF EXISTS ( SELECT  t.[idtable]
                                FROM    [dbo].[table] t
                                WHERE   t.[name] = @protable ) 
                        BEGIN
                            SELECT  @sql = N'TRUNCATE TABLE [dbo].'
                                    + QUOTENAME(@protable)
								
                            EXEC sp_executesql @sql
								
                            IF ( @easytable = N'PROJECT'
                                 AND ( LEN(ISNULL(@@linkprojecttocompanytable,
                                                  N'')) > 0 )
                               ) 
                                BEGIN
                                    IF EXISTS ( SELECT  t.[idtable]
                                                FROM    [dbo].[table] t
                                                WHERE   t.[name] = @@linkprojecttocompanytable ) 
                                        BEGIN
                                            SELECT  @sql = N'TRUNCATE TABLE [dbo].'
                                                    + QUOTENAME(@@linkprojecttocompanytable)
								
                                            EXEC sp_executesql @sql
                                        END
                                END
								
                            IF ( @easytable = N'ARCHIVE' ) 
                                BEGIN
                                    DELETE  FROM [dbo].[file]
                                    WHERE   [filetype] = 1
                                END
								
                        END
                            
                END TRY
                BEGIN CATCH
                    SET @@errormessage = ERROR_MESSAGE()
                END CATCH
                FETCH NEXT FROM table_cursor INTO @protable, @easytable
            END
				
        CLOSE table_cursor
        DEALLOCATE table_cursor    

        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''
                
    END