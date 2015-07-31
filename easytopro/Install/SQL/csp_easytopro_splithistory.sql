CREATE PROCEDURE [dbo].[csp_easytopro_splithistory]
	(
    @@top INT = 500 ,
    @@maxnotelength INT = NULL,
    @@rebuildtable AS BIT ,
    @@errormessage NVARCHAR(2048) = N'' OUTPUT
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @HistoryDateFormat NVARCHAR(10)
        DECLARE @MatchHistoryDateFormat NVARCHAR(128)
        DECLARE @matchDateOnly NVARCHAR(128)
        DECLARE @matchDateAndTime NVARCHAR(128)
        DECLARE @matchNewNotes NVARCHAR(128)
        DECLARE @retval INT
        DECLARE @transaction INT
        
        SET @@errormessage = N''
        SET @retval = 0
        SET @transaction = 0
        
        DECLARE @handle TABLE
            (
              [id] INT ,
              [Type] SMALLINT ,
              [Key 1] INT ,
              [Key 2] INT ,
              [History] NVARCHAR(MAX) ,
              [splitted] INT
            )
        
        -- Begin transaction
        IF @@TRANCOUNT = 0 
            BEGIN
                BEGIN TRANSACTION tran_split
                SELECT  @transaction = 1
            END
        BEGIN TRY
            INSERT  INTO @handle
                    ( id ,
                      [Type] ,
                      [Key 1] ,
                      [Key 2] ,
                      History ,
                      splitted
                    )
                    SELECT TOP ( @@top )
                            [id] ,
                            [Type] ,
                            [Key 1] ,
                            [Key 2] ,
                            History ,
                            splitted
                    FROM    [dbo].[EASY__HISTORY]
                    WHERE   [splitted] = 0
							AND ((LEN(ISNULL([History],N''))<= ISNULL(@@maxnotelength, 0)) OR (@@maxnotelength IS NULL))
        
            SELECT  @HistoryDateFormat = [Value]
            FROM    [EASY__SETTINGS]
            WHERE   [Item] = N'HistoryDateFormat'
        
            SET @MatchHistoryDateFormat = @HistoryDateFormat
        
            SET @MatchHistoryDateFormat = ISNULL(@MatchHistoryDateFormat,
                                                 N'yyyy-MM-dd')
		--dd.MM.yyyy (no, fi)
		--yyyy-MM-dd (sv)
            SET @MatchHistoryDateFormat = REPLACE(@MatchHistoryDateFormat,
                                                  N'yyyy',
                                                  N'[1-2][0-9][0-9][0-9]')
            SET @MatchHistoryDateFormat = REPLACE(@MatchHistoryDateFormat,
                                                  N'MM', N'[0-1][0-9]')
            SET @MatchHistoryDateFormat = REPLACE(@MatchHistoryDateFormat,
                                                  N'dd', N'[0-3][0-9]')
		
            SELECT  @matchNewNotes = N'%' + CHAR(10) + @MatchHistoryDateFormat
                    + N'%'
            SELECT  @matchDateOnly = @MatchHistoryDateFormat + N'%'
            SELECT  @matchDateAndTime = @MatchHistoryDateFormat
                    + N'_[0-2][0-9]:[0-6][0-9]%';



            IF ( @@rebuildtable = 1 ) 
                BEGIN

                    IF EXISTS ( SELECT  *
                                FROM    sys.objects
                                WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__SPLITTEDHISTORY]')
                                        AND type IN ( N'U' ) ) 
                        DROP TABLE [dbo].EASY__SPLITTEDHISTORY 

                    CREATE TABLE [dbo].EASY__SPLITTEDHISTORY
                        (
                          [Type] SMALLINT NOT NULL ,
                          [Key 1] INT NOT NULL ,
                          [Key 2] INT NOT NULL ,
                          [date] DATETIME ,
                          [historytype] NVARCHAR(96) ,
                          [note] NVARCHAR(MAX) ,
                          [user_limeeasyid] INT ,
                          [refs_limeeasyid] INT ,
                          [contact_limeeasyid] INT ,
                          [project_limeeasyid] INT ,
                          [time_limeeasyid] INT
                        )
                END;
            WITH    CTE_HISTORY
                      AS ( SELECT   [easytype] = eh.[Type] ,
                                    [key1] = eh.[Key 1] ,
                                    [key2] = eh.[Key 2] ,
                                    [historynote] = RTRIM(LTRIM(SUBSTRING(REPLACE(eh.[History],
                                                              CHAR(13)
                                                              + CHAR(10),
                                                              CHAR(10)), 0,
                                                              CASE
                                                              WHEN ( PATINDEX(@matchNewNotes,
                                                              REPLACE(eh.[History],
                                                              CHAR(13)
                                                              + CHAR(10),
                                                              CHAR(10))) > 0 )
                                                              THEN PATINDEX(@matchNewNotes,
                                                              REPLACE(eh.[History],
                                                              CHAR(13)
                                                              + CHAR(10),
                                                              CHAR(10)))
                                                              ELSE LEN(eh.[History])
                                                              END))) ,
                                    [remaininghistory] = SUBSTRING(REPLACE(eh.[History],
                                                              CHAR(13)
                                                              + CHAR(10),
                                                              CHAR(10)),
                                                       CASE WHEN ( PATINDEX(@matchNewNotes,
                                                              REPLACE(eh.[History],
                                                              CHAR(13)
                                                              + CHAR(10),
                                                              CHAR(10))) > 0 )
                                                            THEN PATINDEX(@matchNewNotes,
                                                              REPLACE(eh.[History],
                                                              CHAR(13)
                                                              + CHAR(10),
                                                              CHAR(10)))
                                                            ELSE LEN(eh.[History])
                                                       END + 1,
                                                       LEN(REPLACE(eh.[History],
                                                              CHAR(13)
                                                              + CHAR(10),
                                                              CHAR(10)))) ,
                                    [raw_history] = eh.[History]
                           FROM     @handle eh
                           UNION ALL
                           SELECT   [easytype] ,
                                    [key1] ,
                                    [key2] ,
                                    CASE WHEN PATINDEX(@matchNewNotes,
                                                       [remaininghistory]) > 0
                                         THEN RTRIM(LTRIM(SUBSTRING([remaininghistory],
                                                              0,
                                                              PATINDEX(@matchNewNotes,
                                                              [remaininghistory]))))
                                         ELSE RTRIM(LTRIM([remaininghistory]))
                                    END ,
                                    CASE WHEN PATINDEX(@matchNewNotes,
                                                       [remaininghistory]) > 0
                                         THEN RTRIM(LTRIM(SUBSTRING([remaininghistory],
                                                              PATINDEX(@matchNewNotes,
                                                              [remaininghistory])
                                                              + 1,
                                                              LEN([remaininghistory]))))
                                         ELSE ''
                                    END ,
                                    [raw_history]
                           FROM     [CTE_HISTORY]
                           WHERE    LEN([remaininghistory]) > 0
                         )
                INSERT  INTO [dbo].[EASY__SPLITTEDHISTORY]
                        ( [Type] ,
                          [Key 1] ,
                          [Key 2] ,
                          [date] ,
                          [historytype] ,
                          [note] ,
                          [user_limeeasyid] ,
                          [refs_limeeasyid] ,
                          [contact_limeeasyid] ,
                          [project_limeeasyid] ,
                          [time_limeeasyid] 
                        )
                        SELECT  cte.[easytype] ,
                                cte.[key1] ,
                                cte.[key2] ,
                                CASE WHEN ( PATINDEX(@matchDateOnly,
                                                     LEFT(cte.[historynote],
                                                          10)) > 0
                                            AND PATINDEX(@matchDateAndTime,
                                                         LEFT(cte.[historynote],
                                                              16)) = 0
                                          )
                                     THEN ISNULL(( [dbo].[cfn_easytopro_formathistorydate](LEFT(cte.[historynote],
                                                              10),
                                                              @HistoryDateFormat) ),
                                                 GETDATE())
                                     WHEN ( PATINDEX(@matchDateOnly,
                                                     LEFT(cte.[historynote],
                                                          10)) > 0
                                            AND PATINDEX(@matchDateAndTime,
                                                         LEFT(cte.[historynote],
                                                              16)) > 0
                                          )
                                     THEN ISNULL(( [dbo].[cfn_easytopro_formathistorydate](LEFT(cte.[historynote],
                                                              16),
                                                              @HistoryDateFormat) ),
                                                 GETDATE())
                                     ELSE GETDATE()
                                END , -- [date]
                                ISNULL(( SELECT TOP 1
                                                es.[String]
                                         FROM   [dbo].[EASY__STRING] es
                                         WHERE  es.[String ID] = 3
                                                AND LEN(es.[String]) > 0
                                                AND CHARINDEX(es.[String]
                                                              + N':',
                                                              RTRIM(LTRIM(cte.[historynote]))) > 0
                                       ), N'NO_HIT_EASY_TO_PRO_MIGRATION') , -- [historytype]
                                cte.[historynote] , -- [note]
                                CASE WHEN ( PATINDEX(@matchDateOnly,
                                                     LEFT(RTRIM(LTRIM(cte.[historynote])),
                                                          10)) > 0
                                            AND PATINDEX(@matchDateAndTime,
                                                         LEFT(RTRIM(LTRIM(cte.[historynote])),
                                                              16)) = 0
                                          )
                                     THEN ( SELECT TOP 1
                                                    eu.[User ID]
                                            FROM    [dbo].[EASY__USER] AS eu
                                            WHERE   eu.[Signature] = RTRIM(LTRIM(SUBSTRING(RTRIM(LTRIM(cte.[historynote])),
                                                              11,
                                                              CASE
                                                              WHEN ( CHARINDEX(N':',
                                                              RTRIM(LTRIM(cte.[historynote])),
                                                              11) - 11 ) > 0
                                                              THEN ( CHARINDEX(N':',
                                                              RTRIM(LTRIM(cte.[historynote])),
                                                              11) - 11 )
                                                              ELSE 0
                                                              END)))
                                                    AND LEN(eu.[Signature]) > 0
                                          )
                                     WHEN ( PATINDEX(@matchDateOnly,
                                                     LEFT(RTRIM(LTRIM(cte.[historynote])),
                                                          10)) > 0
                                            AND PATINDEX(@matchDateAndTime,
                                                         LEFT(RTRIM(LTRIM(cte.[historynote])),
                                                              16)) > 0
                                          )
                                     THEN ( SELECT TOP 1
                                                    eu.[User ID]
                                            FROM    [dbo].[EASY__USER] AS eu
                                            WHERE   eu.[Signature] = RTRIM(LTRIM(SUBSTRING(RTRIM(LTRIM(cte.[historynote])),
                                                              17,
                                                              CASE
                                                              WHEN ( CHARINDEX(N':',
                                                              RTRIM(LTRIM(cte.[historynote])),
                                                              17) - 17 ) > 0
                                                              THEN ( CHARINDEX(N':',
                                                              RTRIM(LTRIM(cte.[historynote])),
                                                              17) - 17 )
                                                              ELSE 0
                                                              END)))
                                                    AND LEN(eu.[Signature]) > 0
                                          )
                                     ELSE NULL
                                END , -- [user_limeeasyid]
                                CASE WHEN cte.[easytype] = 0
                                     THEN ( SELECT TOP 1
                                                    er.[Reference ID]
                                            FROM    [dbo].[EASY__REFS] AS er
                                            WHERE   CHARINDEX(er.[Name] + N':',
                                                              RTRIM(LTRIM(cte.[historynote]))) > 0
                                                    AND er.[Company ID] = cte.[key1]
                                                    AND LEN(er.[Name]) > 0
                                                    AND er.[Company ID] IS NOT NULL
                                          )
                                     ELSE NULL
                                END , -- [refs_limeeasyid]
                                CASE WHEN cte.[easytype] IN ( 0, 4 )
                                     THEN cte.[key1]
                                     ELSE NULL
                                END , -- [contact_limeeasyid]
                                CASE WHEN cte.[easytype] = 2 THEN cte.[key1]
                                     ELSE NULL
                                END , -- [project_limeeasyid]
                                CASE WHEN cte.[easytype] = 4 THEN cte.[key2]
                                     ELSE NULL
                                END  -- [time_limeeasyid]
                        FROM    CTE_HISTORY AS cte
                OPTION  ( MAXRECURSION 8000 );
           
            
            UPDATE  [dbo].[EASY__HISTORY]
            SET     [splitted] = 1
            WHERE   [id] IN ( SELECT    [id]
                              FROM      @handle )
            SET @@errormessage = N''
            SET @retval = 0
        END TRY	
        BEGIN CATCH	
            SET @@errormessage = ERROR_MESSAGE()
            SET @retval = 1
        END CATCH	
           
            
        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''
          
        IF @retval <> 0 
            BEGIN
                IF @transaction = 1 
                    ROLLBACK TRANSACTION tran_split
                RETURN @retval
            END

	-- Commit transaction
        IF @transaction = 1
            AND @retval = 0 
            BEGIN
                COMMIT TRANSACTION tran_split
            END
          
    END