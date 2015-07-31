CREATE PROCEDURE [dbo].[csp_easytopro_replace_easy__optionmapping] 
	(
      @@xml NVARCHAR(MAX),
      @@errormessage NVARCHAR(2048) OUTPUT
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;

        SET @@errormessage = N''
        
        IF EXISTS ( SELECT  *
                    FROM    sys.objects
                    WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__OPTIONMAPPING]')
                            AND type IN ( N'U' ) ) 
            BEGIN
                BEGIN TRY
					declare @idoc int
					exec sp_xml_preparedocument @idoc output, @@xml
					
					TRUNCATE TABLE [dbo].[EASY__OPTIONMAPPING]
					
					SET IDENTITY_INSERT EASY__OPTIONMAPPING ON
					
					INSERT INTO [dbo].[EASY__OPTIONMAPPING]
					(idoptionmapping, fieldmapping, easystringid, easyvalue, idcategorylimepro, idstringlimepro)
					SELECT *
					FROM OPENXML (@idoc, 'data/dbo.EASY__OPTIONMAPPING')
					WITH(
						idoptionmapping INT,
						fieldmapping INT,
						easystringid SMALLINT,
						easyvalue NVARCHAR(96),
						idcategorylimepro INT,
						idstringlimepro INT
					)
					
					SET IDENTITY_INSERT EASY__OPTIONMAPPING OFF
					
                END TRY
                BEGIN CATCH
                    SET @@errormessage = ERROR_MESSAGE()
                END CATCH
            END
        
    END