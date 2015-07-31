CREATE PROCEDURE [dbo].[csp_easytopro_endmigration]
    (
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
        SET @sql = N''

        DECLARE table_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
            SELECT DISTINCT
                    [protable] ,
                    [easytable]
            FROM    [dbo].[EASY__FIELDMAPPING]
            WHERE   [transfertable] = 1
                    AND LEN(ISNULL([protable], N'')) > 0
		

        OPEN table_cursor
        FETCH NEXT FROM table_cursor INTO @protable, @easytable      
        WHILE @@FETCH_STATUS = 0
            AND @@errormessage = N'' 
            BEGIN

                IF EXISTS ( SELECT  t.[idtable]
                            FROM    [dbo].[table] t
                            WHERE   t.[name] = @protable ) 
                    BEGIN
						-- ADDING RESULTSET IN @table TO PREVENT RESULTSET,  SINCE PROCEDURE IN LIME NEEDS RESULT IN XML-FORMAT
                        SELECT  @sql = @sql
                                + N'INSERT INTO @table EXEC  [dbo].[lsp_formatdb]'
                                + CHAR(10) + REPLICATE(CHAR(9), 4)
                                + N'@@table = ' + @protable + N',' + CHAR(10)
                                + REPLICATE(CHAR(9), 4) + N'@@commit = 1'
                                + CHAR(10)
                    END

                FETCH NEXT FROM table_cursor INTO @protable, @easytable
            END
				
        CLOSE table_cursor
        DEALLOCATE table_cursor    
		
        SELECT  @sql = @sql + CHAR(10) + N'EXEC [dbo].[lsp_refreshldc]' 
        IF ( LEN(ISNULL(@sql, N'')) > 0 ) 
            BEGIN
                BEGIN TRY
				-- ADDING RESULTSET IN @table TO PREVENT RESULTSET,  SINCE PROCEDURE IN LIME NEEDS RESULT IN XML-FORMAT
                    SET @sql = N'declare @table table (	[table] NVARCHAR(64), 
														idrecord INT, 
														fieldtype NVARCHAR(64),
														[expecte] NVARCHAR(MAX) ,
														expected__formatted NVARCHAR(MAX))'
                        + CHAR(10) + @sql
				
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