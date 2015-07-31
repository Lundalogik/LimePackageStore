CREATE PROCEDURE [dbo].[csp_easytopro_addrelation]
    (
      @@tablename NVARCHAR(64) ,
      @@fieldname NVARCHAR(64) ,
      @@sv NVARCHAR(64) = NULL ,
      @@en_us NVARCHAR(64) = NULL ,
      @@no NVARCHAR(64) = NULL ,
      @@fi NVARCHAR(64) = NULL ,
      @@da NVARCHAR(64) = NULL,
      @@relatedtablename NVARCHAR(64) ,
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
         
        
    )
AS 
    BEGIN
        DECLARE @localname INT
           
        DECLARE @idtable INT 
        DECLARE @length INT
        DECLARE @width INT
        DECLARE @height INT

        DECLARE @idfield INT
        DECLARE @idfield1 INT
        DECLARE @idfield2 INT
        DECLARE @isnullable INT 
        DECLARE @fieldtype INT
		
        DECLARE @relatedtabletabname NVARCHAR(64)
        DECLARE @namesuffix INT

	
        SET @fieldtype = 16 -- relation
        SET @isnullable = 1
        SET @namesuffix = 0
        SET @relatedtabletabname = @@tablename
        BEGIN TRY
    -- ADD RELATIONFIELD TO TABLE
            SET @idfield = NULL


            EXEC [dbo].[csp_easytopro_addfield] @@table = @@tablename,
                @@name = @@fieldname, @@fieldtype = @fieldtype,
                @@isnullable = @isnullable, @@sv = @@sv, @@en_us = @@en_us,
                @@no = @@no, @@fi = @@fi, @@da = @@da, @@idfield = @idfield OUTPUT 

            SET @idfield1 = @idfield

-- ADD RELATIONFIELD TO RELATED TABLE

            WHILE EXISTS ( SELECT   *
                           FROM     [dbo].[fieldcache] f
                                    INNER JOIN [dbo].[table] t ON t.idtable = f.idtable
                           WHERE    t.name = @@relatedtablename
                                    AND f.[name] = @relatedtabletabname ) 
                BEGIN
                    SET @namesuffix = @namesuffix + 1
                    SELECT  @relatedtabletabname = @relatedtabletabname
                            + CAST(@namesuffix AS NVARCHAR(32))
                END

            SET @idfield = NULL

            EXEC [dbo].[csp_easytopro_addfield] @@table = @@relatedtablename,
                @@name = @relatedtabletabname, @@fieldtype = @fieldtype,
                @@isnullable = @isnullable, @@sv = @relatedtabletabname,
                @@en_us = @relatedtabletabname, @@no = @relatedtabletabname,
                @@fi = @relatedtabletabname, @@da = @relatedtabletabname,
                @@idfield = @idfield OUTPUT 

            SET @idfield2 = @idfield			
			
		-- MAKE SURE RELATION FIELD IN TABLE(1) 
            EXEC lsp_setfieldattributevalue @@idfield = @idfield2,
                @@name = N'relationmaxcount', @@valueint = 1
						
		-- SETUP RELATION
            EXEC lsp_addrelation @@idfield1 = @idfield1,
                @@idfield2 = @idfield2
            SET @@errormessage = N''
        END TRY
        BEGIN CATCH
            SET @@errormessage = ERROR_MESSAGE()
        END CATCH
    END