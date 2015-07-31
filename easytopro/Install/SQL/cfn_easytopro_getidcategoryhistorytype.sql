CREATE FUNCTION [dbo].[cfn_easytopro_getidcategoryhistorytype] ( )
RETURNS INT
AS 
    BEGIN
        DECLARE @idcategory INT 

        SELECT TOP 1
                @idcategory = o.[idcategorylimepro]
        FROM    [dbo].[EASY__FIELDMAPPING] e
                INNER JOIN [dbo].[EASY__OPTIONMAPPING] o ON o.[fieldmapping] = e.[idfieldmapping]
        WHERE   [easytable] = N'HISTORY'
                AND [easyfieldid] = N'history_type'

            
        RETURN ISNULL(@idcategory,-1)
    END