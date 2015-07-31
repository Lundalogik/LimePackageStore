CREATE PROCEDURE [dbo].[csp_easytopro_getdocumentxml]
    (
      @@limedocumenttable AS NVARCHAR(64)
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
		
        DECLARE @sql NVARCHAR(MAX)
        SELECT  @sql = N'SELECT  [doc].[Type] AS [type] ,
                [doc].[Key 1] AS [key1] ,
                [doc].[Key 2] AS [key2] ,
                ISNULL([doc].[Path], N'''') AS [path] ,
                ISNULL(l.[id' + @@limedocumenttable + N'], 0) AS [idrecord]
        FROM    [dbo].[EASY__ARCHIVE] [doc]
        LEFT JOIN [dbo].' + QUOTENAME(@@limedocumenttable)
                + N' l ON [doc].[Type] = l.[archive_easytype] AND [doc].[Key 1] = l.[archive_easykey1] AND [doc].[Key 2] = l.[archive_easykey2] AND l.[status]=0
        FOR     XML AUTO'
    
        EXEC sp_executesql @sql
    
    END 