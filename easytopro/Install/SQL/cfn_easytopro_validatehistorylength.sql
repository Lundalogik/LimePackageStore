CREATE FUNCTION [dbo].[cfn_easytopro_validatehistorylength]
    (
      @@protable NVARCHAR(64) ,
      @@profield NVARCHAR(64)
    )
RETURNS NVARCHAR(512)
AS 
    BEGIN
        DECLARE @message NVARCHAR(512)


        SELECT TOP 1
                @message = REPLACE(REPLACE('LIME Pro table ''' + @@protable
                                           + ''', field ''' + @@profield
                                           + ''': Length of field in LIME is #1# and Easy contains data of length #2#',
                                           N'#1#', f.[length]), N'#2#',
                                   ( SELECT MAX(LEN([note]))
                                     FROM   [dbo].[EASY__SPLITTEDHISTORY]
                                   ))
        FROM    [dbo].[fieldcache] f
                INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
        WHERE   f.[name] = @@profield
                AND t.[name] = @@protable
                AND ( ( ( SELECT    MAX(LEN([note]))
                          FROM      [dbo].[EASY__SPLITTEDHISTORY]
                        ) > f.[length] )
                      OR ( f.[length] IS NULL )
                    )
            
        RETURN ISNULL(@message,N'')
            
    END