CREATE PROCEDURE [dbo].[csp_easytopro_validatetable]
   (
      @@tablename NVARCHAR(64) ,
      @@message NVARCHAR(2048) = N'' OUTPUT ,
      @@validationerror INT = 0 OUTPUT
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;


        DECLARE @status INT

        SET @@message = N''

        SELECT  @status = [status]
        FROM    [dbo].[tableview]
        WHERE   [name] = @@tablename

        IF ( @status IS NULL ) 
            BEGIN 
                SET @@message = N'New table will be created'
                SET @@validationerror = NULL
            END
        ELSE 
            IF ( @status = 2 ) 
                BEGIN
                    SET @@message = N'Existing table'
                    SET @@validationerror = 0
                END
            ELSE 
                BEGIN
                    SET @@message = N'ERROR: Tablename is already used by a system table'
                    SET @@validationerror = 1
                END

        IF (@@validationerror IS NULL) 
            BEGIN
                BEGIN TRY
                    EXECUTE [dbo].[lsp_verifytablename] @@name = @@tablename -- nvarchar(64)
                    SET @@validationerror = 0
                END TRY
                BEGIN CATCH
                    SET @@message = ERROR_MESSAGE()
                    SET @@validationerror = 1
                END CATCH	
            END

    END