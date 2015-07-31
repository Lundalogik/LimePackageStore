CREATE PROCEDURE [dbo].[csp_easytopro_runsqlonupdate]
    (
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;

        DECLARE @sql NVARCHAR(MAX)

        SET @@errormessage = N''

        DECLARE table_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
            SELECT DISTINCT
                    [dbo].[lfn_getonsqlupdate](e.[protable], 1)
            FROM    [dbo].[EASY__FIELDMAPPING] e
            WHERE   e.[transfertable] = 1
		

        OPEN table_cursor
        FETCH NEXT FROM table_cursor INTO @sql      
        WHILE @@FETCH_STATUS = 0
            AND @@errormessage = N'' 
            BEGIN
                    
                BEGIN TRY
                    IF (LEN(ISNULL(@sql,N''))>0)
                        BEGIN
                            EXEC sp_executesql @sql	
                        END
                            
                END TRY
                BEGIN CATCH
                    SET @@errormessage = ERROR_MESSAGE()
                END CATCH
                FETCH NEXT FROM table_cursor INTO @sql
            END
				
        CLOSE table_cursor
        DEALLOCATE table_cursor    

        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''
                
    END