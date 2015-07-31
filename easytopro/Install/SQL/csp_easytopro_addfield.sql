CREATE PROCEDURE [dbo].[csp_easytopro_addfield]
    (
      @@table NVARCHAR(64) ,
      @@name NVARCHAR(64) ,
      @@fieldtype INT ,
      @@length INT = NULL ,
      @@width INT = NULL ,
      @@height INT = NULL ,
      @@isnullable INT = NULL ,
      @@limereadonly INT = NULL ,
      @@sv NVARCHAR(MAX) = NULL ,
      @@en_us NVARCHAR(MAX) = NULL ,
      @@no NVARCHAR(MAX) = NULL ,
      @@fi NVARCHAR(MAX) = NULL ,
      @@da NVARCHAR(MAX) = NULL,
      @@invisible INT = NULL,
      @@idcategory INT = NULL OUTPUT ,
      @@idfield INT = NULL OUTPUT ,
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
        
    )
AS 
    BEGIN
        DECLARE @localname INT
           
        BEGIN TRY
            EXEC dbo.lsp_addfield @@table = @@table, -- nvarchar(64)
                @@name = @@name, -- nvarchar(64)
                @@fieldtype = @@fieldtype, -- INT
                @@isnullable = @@isnullable, -- INT
                @@length = @@length, -- int
                @@localname = @localname OUTPUT, -- int
                @@idcategory = @@idcategory OUTPUT, -- int
                @@idfield = @@idfield OUTPUT
	
            IF ( LEN(ISNULL(@@sv, N'')) > 0 ) 
                EXEC [dbo].[lsp_setstringattributevalue] @@idstring = @localname,
                    @@name = N'sv', @@value = @@sv
						
            IF ( LEN(ISNULL(@@en_us, N'')) > 0 ) 
                EXEC [dbo].[lsp_setstringattributevalue] @@idstring = @localname,
                    @@name = N'en_us', @@value = @@en_us
						
            IF ( LEN(ISNULL(@@no, N'')) > 0 ) 
                EXEC [dbo].[lsp_setstringattributevalue] @@idstring = @localname,
                    @@name = N'no', @@value = @@no
						
            IF ( LEN(ISNULL(@@fi, N'')) > 0 ) 
                EXEC [dbo].[lsp_setstringattributevalue] @@idstring = @localname,
                    @@name = N'fi', @@value = @@fi
                    
            IF ( LEN(ISNULL(@@da, N'')) > 0 ) 
                EXEC [dbo].[lsp_setstringattributevalue] @@idstring = @localname,
                    @@name = N'da', @@value = @@da
            
            IF ( ISNULL(@@width, 0) > 0 ) 
                BEGIN
            
                    EXEC [dbo].[lsp_setattributevalue] @@owner = N'field', -- nvarchar(64)
                        @@idrecord = @@idfield, -- int
                        @@idrecord2 = NULL, -- int
                        @@iduser = 1, @@name = N'width', -- nvarchar(64)
                        @@valueint = @@width
                END
			
            IF ( ISNULL(@@height, 0) > 0 ) 
                BEGIN
            
                    EXEC [dbo].[lsp_setattributevalue] @@owner = N'field', -- nvarchar(64)
                        @@idrecord = @@idfield, -- int
                        @@idrecord2 = NULL, -- int
                        @@iduser = 1, @@name = N'height', -- nvarchar(64)
                        @@valueint = @@width
                END
                
            IF ( ISNULL(@@limereadonly, 0) = 1 ) 
                BEGIN
                    EXEC [dbo].[lsp_setattributevalue] @@owner = N'field', -- nvarchar(64)
                        @@idrecord = @@idfield, -- int
                        @@idrecord2 = NULL, -- int
                        @@iduser = 1, @@name = N'limereadonly', -- nvarchar(64)
                        @@valueint = 1
                END
                
            IF ( ISNULL(@@invisible, 0) = 1 ) 
                BEGIN
                    EXEC [dbo].[lsp_setattributevalue] @@owner = N'field', -- nvarchar(64)
                        @@idrecord = @@idfield, -- int
                        @@idrecord2 = NULL, -- int
                        @@iduser = 1, @@name = N'invisible', -- nvarchar(64)
                        @@valueint = 1
                END
			
            SET @@errormessage = N''
        END TRY
        BEGIN CATCH
            SET @@errormessage = ERROR_MESSAGE()
        END CATCH
    END