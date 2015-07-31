CREATE PROCEDURE [dbo].[csp_easytopro_addsuperfieldsto_easy__fieldmapping]
    @@errormessage NVARCHAR(2048) OUTPUT
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
    
    
        DECLARE @mergeresult TABLE
            (
              [action] NVARCHAR(64) ,
              [easytable] NVARCHAR(64) ,
              [easyfieldname] NVARCHAR(64) ,
              [issuperfield] INT ,
              [easyfieldid] NVARCHAR(64) ,
              [easyfieldorder] INT ,
              [easyfieldtype] INT ,
              [easydatatype] INT ,
              [easydatatypedata] INT ,
              [easydatatypetext] NVARCHAR(64) ,
              [protable] NVARCHAR(64) ,
              [transfertable] INT ,
              [profieldname] NVARCHAR(64) ,
              [localname_sv] NVARCHAR(64) ,
              [localname_en_us] NVARCHAR(64) ,
              [localname_no] NVARCHAR(64) ,
              [localname_fi] NVARCHAR(64) ,
              [localname_da] NVARCHAR(64) ,
              [active] INT ,
              [easyprofieldtype] INT ,
              [proposedvalue] NVARCHAR(64)
            )
        DECLARE @transaction INT
        DECLARE @result INT

	-- Set initial values
        SET @result = 0
        SET @transaction = 0
        
         -- Begin transaction
        IF @@TRANCOUNT = 0 
            BEGIN
                BEGIN TRANSACTION tran_addsuperfieldstoeasy
                SELECT  @transaction = 1
            END

        BEGIN TRY
        
            ;
            MERGE [dbo].[EASY__FIELDMAPPING] AS TARGET
                USING 
                    ( SELECT    CASE [Field type]
                                  WHEN 0 THEN N'CONTACT'
                                  WHEN 1 THEN N'REFS'
                                  WHEN 2 THEN N'PROJECT'
                                  WHEN 6 THEN N'ARCHIVE'
                                  WHEN 7 THEN N'ARCHIVE'
                                  ELSE N'NOT_VALID'
                                END AS [easytable] ,
                                [Field name] AS [easyfieldname] ,
                                1 AS [issuperfield] ,
                                CAST([Field ID] AS NVARCHAR(64)) AS [easyfieldid] ,
                                CAST([Order] AS INT) AS [easyfieldorder] ,
                                CAST([Field type] AS INT) AS [easyfieldtype] ,
                                CAST([Data type] AS INT) AS [easydatatype] ,
                                CAST([Data type data] AS INT) AS [easydatatypedata] ,
                                [dbo].[cfn_easytopro_geteasydatatypetext]([Data type],
                                                              [Data type data]) AS [easydatatypetext] ,
                                ISNULL(( SELECT TOP 1
                                                [protable]
                                         FROM   [dbo].[EASY__FIELDMAPPING]
                                         WHERE  [easyfieldtype] = [Field type]
                                                AND [issuperfield] = 0
                                       ), N'') AS [protable] ,
                                ISNULL(( SELECT TOP 1
                                                [transfertable]
                                         FROM   [dbo].[EASY__FIELDMAPPING]
                                         WHERE  [easyfieldtype] = [Field type]
                                                AND [issuperfield] = 0
                                       ), N'') AS [transfertable] ,
                                [Field name] AS [profieldname] ,
                                REPLACE([Field name], N'.', N'') AS [localname_sv] ,
                                REPLACE([Field name], N'.', N'') AS [localname_en_us] ,
                                REPLACE([Field name], N'.', N'') AS [localname_no] ,
                                REPLACE([Field name], N'.', N'') AS [localname_fi] ,
                                REPLACE([Field name], N'.', N'') AS [localname_da] ,
                                1 AS [active] ,
                                [dbo].[cfn_easytopro_geteasyprofieldtype]([Data type],
                                                              [Data type data]) AS [easyprofieldtype] ,
                                N'' AS [proposedvalue]
                      FROM      [dbo].[EASY__FIELD]
                      WHERE     [Field type] IN ( 0, 1, 2, 6, 7 )
                                AND [Data type] IN ( 0, 1, 2, 3, 4, 5 )
                    ) AS SOURCE ( [easytable], [easyfieldname], [issuperfield],
                                  [easyfieldid], [easyfieldorder],
                                  [easyfieldtype], [easydatatype],
                                  [easydatatypedata], [easydatatypetext],
                                  [protable], [transfertable], [profieldname],
                                  [localname_sv], [localname_en_us],
                                  [localname_no], [localname_fi], [localname_da], 
                                  [active], [easyprofieldtype], [proposedvalue] )
                ON ( TARGET.[easyfieldid] = SOURCE.[easyfieldid]
                     AND TARGET.[easyfieldtype] = SOURCE.[easyfieldtype]
                     AND TARGET.[easydatatype] = SOURCE.[easydatatype]
                     AND TARGET.[easydatatypedata] = SOURCE.[easydatatypedata]
                     AND TARGET.[issuperfield] = SOURCE.[issuperfield]
                   )
                WHEN MATCHED 
                    THEN
			UPDATE       SET
                    [easyfieldname] = SOURCE.[easyfieldname] ,
                    [easyfieldorder] = SOURCE.[easyfieldorder]
                WHEN NOT MATCHED BY TARGET 
                    THEN
				INSERT  (
                          [easytable] ,
                          [easyfieldname] ,
                          [issuperfield] ,
                          [easyfieldid] ,
                          [easyfieldorder] ,
                          [easyfieldtype] ,
                          [easydatatype] ,
                          [easydatatypedata] ,
                          [easydatatypetext] ,
                          [protable] ,
                          [transfertable] ,
                          [profieldname] ,
                          [localname_sv] ,
                          [localname_en_us] ,
                          [localname_no] ,
                          [localname_fi] ,
                          [localname_da] ,
                          [active] ,
                          [easyprofieldtype] ,
                          [proposedvalue] 
			            )
                         VALUES
                        ( SOURCE.[easytable] ,
                          SOURCE.[easyfieldname] ,
                          SOURCE.[issuperfield] ,
                          SOURCE.[easyfieldid] ,
                          SOURCE.[easyfieldorder] ,
                          SOURCE.[easyfieldtype] ,
                          SOURCE.[easydatatype] ,
                          SOURCE.[easydatatypedata] ,
                          SOURCE.[easydatatypetext] ,
                          SOURCE.[protable] ,
                          SOURCE.[transfertable] ,
                          SOURCE.[profieldname] ,
                          SOURCE.[localname_sv] ,
                          SOURCE.[localname_en_us] ,
                          SOURCE.[localname_no] ,
                          SOURCE.[localname_fi] ,
                          SOURCE.[localname_da] ,
                          SOURCE.[active] ,
                          SOURCE.[easyprofieldtype] ,
                          SOURCE.[proposedvalue] 
			            )
                WHEN NOT MATCHED BY SOURCE AND TARGET.[issuperfield] = 1
                    THEN DELETE
                OUTPUT
                    $action ,
                    COALESCE(inserted.[easytable], deleted.[easytable]) ,
                    COALESCE(inserted.[easyfieldname], deleted.[easyfieldname]) ,
                    COALESCE(inserted.[issuperfield], deleted.[issuperfield]) ,
                    COALESCE(inserted.[easyfieldid], deleted.[easyfieldid]) ,
                    COALESCE(inserted.[easyfieldorder],
                             deleted.[easyfieldorder]) ,
                    COALESCE(inserted.[easyfieldtype], deleted.[easyfieldtype]) ,
                    COALESCE(inserted.[easydatatype], deleted.[easydatatype]) ,
                    COALESCE(inserted.[easydatatypedata],
                             deleted.[easydatatypedata]) ,
                    COALESCE(inserted.[easydatatypetext],
                             deleted.[easydatatypetext]) ,
                    COALESCE(inserted.[protable], deleted.[protable]) ,
                    COALESCE(inserted.[transfertable], deleted.[transfertable]) ,
                    COALESCE(inserted.[profieldname], deleted.[profieldname]) ,
                    COALESCE(inserted.[localname_sv], deleted.[localname_sv]) ,
                    COALESCE(inserted.[localname_en_us],
                             deleted.[localname_en_us]) ,
                    COALESCE(inserted.[localname_no], deleted.[localname_no]) ,
                    COALESCE(inserted.[localname_fi], deleted.[localname_fi]) ,
                    COALESCE(inserted.[localname_da], deleted.[localname_da]) ,
                    COALESCE(inserted.[active], deleted.[active]) ,
                    COALESCE(inserted.[easyprofieldtype],
                             deleted.[easyprofieldtype]) ,
                    COALESCE(inserted.[proposedvalue], deleted.[proposedvalue])
                    INTO @mergeresult;

            SELECT  *
            FROM    @mergeresult [mergeresult]
            WHERE   [action] IN ( N'DELETE', N'INSERT' )
            FOR     XML AUTO     
		
            SET @@errormessage = N''
            SET @result = 0
		
        END TRY
        BEGIN CATCH
            SET @@errormessage = ERROR_MESSAGE()
            SET @result = 1
        END CATCH
        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''
        
        IF @result <> 0 
            BEGIN
                IF @transaction = 1 
                    ROLLBACK TRANSACTION tran_addsuperfieldstoeasy
            END

	-- Commit transaction
        IF ( @transaction = 1
             AND @result = 0
           ) 
            BEGIN
                COMMIT TRANSACTION tran_addsuperfieldstoeasy
            END
        
    END