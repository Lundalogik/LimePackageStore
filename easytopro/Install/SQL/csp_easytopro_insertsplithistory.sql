CREATE PROCEDURE [dbo].[csp_easytopro_insertsplithistory]
	(
    @@xml NVARCHAR(MAX) ,
    @@errormessage NVARCHAR(2048) = N'' OUTPUT
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;

		DECLARE @transaction INT
        DECLARE @retval INT

		SET @@errormessage = N''
        SET @retval = 0
        SET @transaction = 0

		 -- Begin transaction
        IF @@TRANCOUNT = 0 
            BEGIN
                BEGIN TRANSACTION tran_split
                SELECT  @transaction = 1
            END
        BEGIN TRY
			
			DECLARE @iXML INT
			EXEC sp_xml_preparedocument @iXML OUTPUT, @@xml

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
                          [time_limeeasyid] ,
						  [historyid]
                        )
			SELECT 
					x.[type] AS [Type], 
					x.[powersellid] AS [Key 1], 
					0 AS [Key 2], 
					CASE WHEN ISDATE(x.[date]) = 1 THEN x.[date] ELSE GETDATE() END AS [date], 
					x.[category] AS [historytype], 
					x.[rawhistory] AS [note], 
					u.[User ID] AS [user_limeeasyid], 
					e.[Reference ID] AS [refs_limeeasyid], 
					CASE WHEN x.[type] = 0 THEN x.[powersellid] ELSE NULL END AS [contact_limeeasyid], 
					CASE WHEN x.[type] = 2 THEN x.[powersellid] ELSE NULL END AS [project_limeeasyid], 
					NULL AS [time_limeeasyid],
					x.[historyid]
			FROM OPENXML(@iXML, '/root/row')
			WITH (
					[type] INT,
					[historyid] INT,
					[powersellid] INT,
					[date] NVARCHAR(64),
					[signature] NVARCHAR(64),
					[category] NVARCHAR(64),
					[reference] NVARCHAR(128),
					[rawhistory] NVARCHAR(4000)
				) x 
				LEFT JOIN [EASY__REFS] e ON e.[Company ID] = x.[powersellid] AND e.[Name] = x.[reference] AND x.[type] = 0
				LEFT JOIN [EASY__USER] u ON u.[Signature] = x.[signature] 

			EXECUTE sp_xml_removedocument @iXML


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