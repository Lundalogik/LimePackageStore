CREATE PROCEDURE [dbo].[csp_easytopro_validate_option]
    (
      @@idfieldmapping INT = NULL 
    )
AS 
    BEGIN
		-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
	-- Declarations

         
        SELECT  eo.[fieldmapping] ,
                eo.[idoptionmapping] ,
                REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': LIME Easy option ''#3#'' is linked to non existing LIME Pro option. idcategorylime: #4#, idstring: #5#',
                                                        N'#1#',
                                                        ISNULL(ef.[protable],
                                                              N'')), N'#2#',
                                                ISNULL(ef.[profieldname], N'')),
                                        N'#3#', ISNULL(eo.[easyvalue], N'')),
                                N'#4#',
                                ISNULL(CAST(eo.[idcategorylimepro] AS NVARCHAR(32)),
                                       N'')), N'#5#',
                        ISNULL(CAST(eo.[idstringlimepro] AS NVARCHAR(32)), N'')) AS [validationmessage]
        FROM    [dbo].[EASY__OPTIONMAPPING] eo
                LEFT JOIN [dbo].[EASY__FIELDMAPPING] ef ON ef.[idfieldmapping] = eo.[fieldmapping]
                LEFT JOIN ( SELECT  f.[name] AS [fieldname] ,
                                    t.[name] AS [tablename] ,
                                    a.[value] AS [idcategory] ,
                                    s.[idstring] AS [idstring]
                            FROM    [dbo].[fieldcache] f
                                    INNER JOIN [dbo].[table] t ON f.[idtable] = t.[idtable]
                                    INNER JOIN [dbo].[attributedata] a ON a.[idrecord] = f.[idfield]
                                                              AND a.[owner] = N'field'
                                                              AND a.[name] = N'idcategory'
                                    INNER JOIN [dbo].[string] s ON s.[idcategory] = a.[value]
                          ) m ON m.[fieldname] = ISNULL(ef.[profieldname], N'')
                                 AND m.[tablename] = ISNULL(ef.[protable], N'')
                                 AND m.[idcategory] = ISNULL(eo.[idcategorylimepro],
                                                             0)
                                 AND ISNULL(eo.[idstringlimepro], 0) = m.[idstring]
        WHERE   ISNULL(eo.[idstringlimepro], 0) > 0
                AND m.[idstring] IS NULL
                AND ( ( eo.[fieldmapping] = @@idfieldmapping )
                      OR ( @@idfieldmapping IS NULL )
                    )
        FOR     XML AUTO
        
        
    END 