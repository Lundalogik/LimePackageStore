CREATE PROCEDURE [dbo].[csp_easytopro_validate_requiredfields]
    (
      @@easytable NVARCHAR(64) = NULL 
    )
AS 
    BEGIN
		-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
	-- Declarations


        SELECT  ISNULL(t.[name], N'') AS [tablename] ,
                ISNULL(f.[name], N'') AS [fieldname]
        FROM    [dbo].[fieldcache] f
                INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                INNER JOIN [dbo].[attributedata] a ON a.[idrecord] = f.[idfield]
                                                      AND a.[owner] = N'field'
                                                      AND a.[name] = N'required'
                LEFT JOIN [dbo].[EASY__FIELDMAPPING] e ON ( e.[profieldname] = f.[name]
                                                            AND e.[protable] = t.[name]
                                                            AND LEN(ISNULL([proposedvalue],
                                                              N'')) > 0
                                                            AND e.[active] = 1
                                                          )
        WHERE   t.[name] IN ( SELECT DISTINCT
                                        [protable]
                              FROM      [dbo].[EASY__FIELDMAPPING]
                              WHERE     [transfertable] = 1
                                        AND ( ( [easytable] = @@easytable )
                                              OR ( @@easytable IS NULL )
                                            ) )
                AND e.[idfieldmapping] IS NULL
        FOR     XML AUTO
        
    END