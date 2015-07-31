CREATE PROCEDURE [dbo].[csp_easytopro_fieldexist]
    (
      @@tablename AS NVARCHAR(64) ,
      @@fieldname AS NVARCHAR(64) ,
      @@exists AS INT = 0 OUTPUT ,
      @@required AS INT = 0 OUTPUT
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        
        SELECT  @@exists = CASE WHEN EXISTS ( SELECT    f.[idfield]
                                              FROM      [dbo].[fieldcache] f
                                                        INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                              WHERE     f.[name] = @@fieldname
                                                        AND t.[name] = @@tablename )
                                THEN 1
                                ELSE 0
                           END ,
                @@required = CASE WHEN EXISTS ( SELECT  a.[idattributedata]
                                                FROM    [dbo].[attributedata] a
                                                        INNER JOIN [dbo].[fieldcache] f ON f.[idfield] = a.[idrecord]
                                                              AND f.[name] = @@fieldname
                                                        INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                              AND t.[name] = @@tablename
                                                WHERE   a.[owner] = N'field'
                                                        AND a.[name] = 'required' )
                                  THEN 1
                                  ELSE 0
                             END
                           
                           
            

    END