CREATE PROCEDURE [dbo].[csp_easytopro_getoptionmappingxml] ( @@fieldmapping INT = NULL )
AS 
    BEGIN
		-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
	-- Declarations
		IF @@fieldmapping IS NULL
		-- Return full optionmapping
		BEGIN
			SELECT  *
			FROM    [dbo].[EASY__OPTIONMAPPING]
			FOR     XML AUTO
		END
		ELSE
		-- Only return current optionmapping
			SELECT  eo.[idoptionmapping] ,
					eo.[fieldmapping] ,
					eo.[easyvalue] ,
					eo.[idcategorylimepro] ,
					eo.[idstringlimepro] ,
					ISNULL(ef.[protable], N'') AS [protable] ,
					ISNULL(ef.[profieldname], N'') AS [profieldname]
			FROM    [dbo].[EASY__OPTIONMAPPING] AS eo
					INNER JOIN [dbo].[EASY__FIELDMAPPING] AS ef ON eo.[fieldmapping] = ef.[idfieldmapping]
			WHERE   [fieldmapping] = @@fieldmapping
			FOR     XML AUTO
        
        
    END 