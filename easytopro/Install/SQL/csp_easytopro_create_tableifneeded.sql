CREATE PROCEDURE [dbo].[csp_easytopro_create_tableifneeded]
    (
      @@tablename NVARCHAR(64) ,
      @@sv NVARCHAR(64) = NULL ,
      @@en_us NVARCHAR(64) = NULL ,
      @@no NVARCHAR(64) = NULL ,
      @@fi NVARCHAR(64) = NULL ,
      @@da NVARCHAR(64) = NULL,
      @@errormessage AS NVARCHAR(2048) = N'' OUTPUT
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @localname INT
        DECLARE @idtable INT 
        DECLARE @retval INT
        DECLARE @transaction INT
    

	-- Set initial values
        SET @retval = 0
        SET @transaction = 0
        SET @@errormessage = N''
        SET @idtable = NULL
        SET @localname = NULL
		
        IF NOT EXISTS ( SELECT  [idtable]
                        FROM    [dbo].[table]
                        WHERE   [name] = @@tablename ) 
            BEGIN
			
			-- Begin transaction
                IF @@TRANCOUNT = 0 
                    BEGIN
                        BEGIN TRANSACTION tran_createtable
                        SELECT  @transaction = 1
                    END
                
                BEGIN TRY
                    
                    IF @retval = 0 
                        EXECUTE @retval = [dbo].[lsp_addtable] @@name = @@tablename,
                            @@idtable = @idtable OUTPUT,
                            @@localname = @localname OUTPUT
	           
	           
                    IF ( LEN(ISNULL(@@sv, N'')) > 0 ) 
                        BEGIN
                            IF @retval = 0 
                                EXECUTE @retval = [dbo].[lsp_setstringattributevalue] @@idstring = @localname,
                                    @@name = N'sv', @@value = @@sv
                        END
					
                    IF ( LEN(ISNULL(@@en_us, N'')) > 0 ) 
                        BEGIN
                            IF @retval = 0 
                                EXECUTE @retval = [dbo].[lsp_setstringattributevalue] @@idstring = @localname,
                                    @@name = N'en_us', @@value = @@en_us
                        END
					
                    IF ( LEN(ISNULL(@@no, N'')) > 0 ) 
                        BEGIN
                            IF @retval = 0 
                                EXECUTE @retval = [dbo].[lsp_setstringattributevalue] @@idstring = @localname,
                                    @@name = N'no', @@value = @@no
                        END
					
                    IF ( LEN(ISNULL(@@fi, N'')) > 0 ) 
                        BEGIN	
                            IF @retval = 0 
                                EXECUTE @retval = [dbo].[lsp_setstringattributevalue] @@idstring = @localname,
                                    @@name = N'fi', @@value = @@fi
                        END
					
                    IF ( LEN(ISNULL(@@da, N'')) > 0 ) 
                        BEGIN	
                            IF @retval = 0 
                                EXECUTE @retval = [dbo].[lsp_setstringattributevalue] @@idstring = @localname,
                                    @@name = N'da', @@value = @@da
                        END
                        
                END TRY
                BEGIN CATCH
                    SET @@errormessage = ERROR_MESSAGE()
                    SET @retval = -1
                END CATCH	
           
           
                IF @retval <> 0 
                    BEGIN
                        IF @transaction = 1 
                            ROLLBACK TRANSACTION tran_createtable
                        RETURN @retval
                    END

	-- Commit transaction
                IF @transaction = 1 
                    COMMIT TRANSACTION tran_createtable

                RETURN @retval
           
           
            END
        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''
    END