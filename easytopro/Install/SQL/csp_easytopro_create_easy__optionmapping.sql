CREATE PROCEDURE [dbo].[csp_easytopro_create_easy__optionmapping]
    (
      @@errormessage AS NVARCHAR(2048) OUTPUT
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        
        DECLARE @mergeresult TABLE
            (
              [action] NVARCHAR(64) ,
              [fieldmapping] INT ,
              [easystringid] SMALLINT ,
              [easyvalue] NVARCHAR(96) ,
              [idcategorylimepro] INT ,
              [idstringlimepro] INT
            )
        DECLARE @transaction INT
        DECLARE @result INT

	-- Set initial values
        SET @result = 0
        SET @transaction = 0
        
         -- Begin transaction
        IF @@TRANCOUNT = 0 
            BEGIN
                BEGIN TRANSACTION tran_create_easy__optionmapping
                SELECT  @transaction = 1
            END
        
        BEGIN TRY
            IF EXISTS ( SELECT  *
                        FROM    sys.objects
                        WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__FIELDMAPPING]')
                                AND type IN ( N'U' ) ) 
                BEGIN
                    IF NOT EXISTS ( SELECT  *
                                    FROM    sys.objects
                                    WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__OPTIONMAPPING]')
                                            AND type IN ( N'U' ) ) 
                        BEGIN


                            CREATE TABLE [dbo].[EASY__OPTIONMAPPING]
                                (
                                  [idoptionmapping] INT IDENTITY(1, 1)
                                                        PRIMARY KEY ,
                                  [fieldmapping] INT ,
                                  [easystringid] SMALLINT ,
                                  [easyvalue] NVARCHAR(96) ,
                                  [idcategorylimepro] INT ,
                                  [idstringlimepro] INT
                                )
                    
                    
                    
                        END;
                    MERGE [dbo].[EASY__OPTIONMAPPING] AS TARGET
                        USING 
                            ( SELECT    ef.[idfieldmapping] AS [fieldmapping] ,
                                        es.[String ID] AS [easystringid] ,
                                        es.[String] AS [easyvalue] ,
                                        ISNULL(( SELECT TOP 1
                                                        CAST(a.[value] AS INT)
                                                 FROM   [dbo].[fieldcache] fc
                                                        INNER JOIN [dbo].[table] t ON fc.[idtable] = t.[idtable]
                                                        INNER JOIN [dbo].[attributedata] a ON a.[idrecord] = fc.[idfield]
                                                              AND a.[owner] = N'field'
                                                              AND a.[name] = N'idcategory'
                                                 WHERE  ef.[profieldname] = fc.[name]
                                                        AND t.[name] = ef.[protable]
                                                        AND LEN(ef.[profieldname]) > 0
                                               ), -1) AS [idcategorylimepro] ,
                                        -1 AS [idstringlimepro]
                              FROM      [dbo].[EASY__FIELDMAPPING] ef
                                        INNER JOIN [dbo].[EASY__STRING] es ON es.[String ID] = ef.[easydatatypedata]
                              WHERE     ef.[easydatatype] IN ( 2, 3, 5 ) -- OPTION, TEXT OPTION, SET
                              
                            ) AS SOURCE ( [fieldmapping], [easystringid],
                                          [easyvalue], [idcategorylimepro],
                                          [idstringlimepro] )
                        ON ( TARGET.[fieldmapping] = SOURCE.[fieldmapping]
                             AND TARGET.[easyvalue] = SOURCE.[easyvalue]
                             AND TARGET.[easystringid] = SOURCE.[easystringid]
                           )
                        WHEN NOT MATCHED BY TARGET 
                            THEN
				INSERT  (
                          [fieldmapping] ,
                          [easystringid] ,
                          [easyvalue] ,
                          [idcategorylimepro] ,
                          [idstringlimepro] 
			            )     VALUES
                        ( SOURCE.[fieldmapping] ,
                          SOURCE.[easystringid] ,
                          SOURCE.[easyvalue] ,
                          SOURCE.[idcategorylimepro] ,
                          SOURCE.[idstringlimepro] 
			            )
                        WHEN NOT MATCHED BY SOURCE 
                            THEN DELETE
                        OUTPUT
                            $action ,
                            COALESCE(inserted.[fieldmapping],
                                     deleted.[fieldmapping]) ,
                            COALESCE(inserted.[easystringid],
                                     deleted.[easystringid]) ,
                            COALESCE(inserted.[easyvalue], deleted.[easyvalue]) ,
                            COALESCE(inserted.[idcategorylimepro],
                                     deleted.[idcategorylimepro]) ,
                            COALESCE(inserted.[idstringlimepro],
                                     deleted.[idstringlimepro])
                            INTO @mergeresult;

                    SELECT  *
                    FROM    @mergeresult [mergeresult]
                    WHERE   [action] IN ( N'DELETE', N'INSERT' )
                    FOR     XML AUTO
                        
                    SET @@errormessage = N''
                    SET @result = 0
                END
            ELSE 
                BEGIN
                    SET @@errormessage = N'Required table [dbo].[EASY__FIELDDMAPPING] is missing'
                    SET @result = 1
                END    
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
                    ROLLBACK TRANSACTION tran_create_easy__optionmapping
            END

	-- Commit transaction
        IF ( @transaction = 1
             AND @result = 0
           ) 
            BEGIN
                COMMIT TRANSACTION tran_create_easy__optionmapping
            END
            

    END