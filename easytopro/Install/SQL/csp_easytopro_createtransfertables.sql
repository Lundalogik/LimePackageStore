CREATE PROCEDURE [dbo].[csp_easytopro_createtransfertables]
    (
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
         
        
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;

        DECLARE @protable NVARCHAR(64)

        SET @@errormessage = N''

        DECLARE table_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
            SELECT DISTINCT
                    [protable]
            FROM    [dbo].[EASY__FIELDMAPPING]
            WHERE   [transfertable] = 1
                    AND LEN(ISNULL([protable], N'')) > 0
		

        OPEN table_cursor
        FETCH NEXT FROM table_cursor INTO @protable       
        WHILE @@FETCH_STATUS = 0
            AND @@errormessage = N'' 
            BEGIN
                    
                BEGIN TRY
                    IF NOT EXISTS ( SELECT  t.[idtable]
                                    FROM    [dbo].[table] t
                                    WHERE   t.[name] = @protable ) 
                        BEGIN
                            EXECUTE [dbo].[csp_easytopro_create_tableifneeded] @@tablename = @protable,
                                @@errormessage = @@errormessage OUTPUT
                        END
                            
                END TRY
                BEGIN CATCH
                    SET @@errormessage = ERROR_MESSAGE()
                END CATCH
                FETCH NEXT FROM table_cursor INTO @protable
            END
				
        CLOSE table_cursor
        DEALLOCATE table_cursor    

        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''
                
    END