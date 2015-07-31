CREATE PROCEDURE [dbo].[csp_easytopro_update_easy__fieldmapping]
    (
      @@easytable NVARCHAR(64) = NULL ,
      @@transfertable INT = 0 ,
      @@protable NVARCHAR(64) = N'' ,
      @@active INT = 0 ,
      @@idfieldmapping INT = NULL ,
      @@profieldname NVARCHAR(64) = N'' ,
      @@localname_sv NVARCHAR(64) = N'' ,
      @@localname_en_us NVARCHAR(64) = N'' ,
      @@localname_no NVARCHAR(64) = N'' ,
      @@localname_fi NVARCHAR(64) = N'' ,
      @@localname_da NVARCHAR(64) = N'' ,
      @@proposedvalue NVARCHAR(64) = N'' ,
      @@errormessage NVARCHAR(2048) OUTPUT
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        
        DECLARE @protablebeforechange NVARCHAR(64)
        DECLARE @idfieldmapping INT
        SET @@errormessage = N''
        
        IF EXISTS ( SELECT  *
                    FROM    sys.objects
                    WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__FIELDMAPPING]')
                            AND type IN ( N'U' ) ) 
            BEGIN
                BEGIN TRY
			
                    IF ( @@easytable IS NULL ) 
                        BEGIN
                            IF EXISTS ( SELECT  [idfieldmapping]
                                        FROM    [dbo].[EASY__FIELDMAPPING]
                                        WHERE   [idfieldmapping] = @@idfieldmapping ) 
                                BEGIN
                                    UPDATE  [dbo].[EASY__FIELDMAPPING]
                                    SET     [profieldname] = @@profieldname ,
                                            [localname_sv] = @@localname_sv ,
                                            [localname_en_us] = @@localname_en_us ,
                                            [localname_no] = @@localname_no ,
                                            [localname_fi] = @@localname_fi ,
                                            [localname_da] = @@localname_da ,
                                            [active] = @@active ,
                                            [proposedvalue] = @@proposedvalue
                                    WHERE   [idfieldmapping] = @@idfieldmapping
				         
			
                                    SET @@errormessage = N''
                                END
                            ELSE 
                                BEGIN
                                    SET @@errormessage = N' No fieldmapping exists with idfieldmapping: '
                                        + ISNULL(CAST(@@idfieldmapping AS NVARCHAR(32)),
                                                 N'UNKNOWN')
                                END
                        END
                    ELSE 
                        BEGIN
							
                            SELECT DISTINCT
                                    @protablebeforechange = [protable]
                            FROM    [dbo].[EASY__FIELDMAPPING]
                            WHERE   [easytable] = @@easytable
                        
                            UPDATE  [dbo].[EASY__FIELDMAPPING]
                            SET     [protable] = @@protable ,
                                    [transfertable] = @@transfertable
                            WHERE   [easytable] = @@easytable
                            
                            
                            -- RESET EASY__OPTIONMAPPING
                            IF OBJECT_ID('curOptions') IS NOT NULL 
                                DEALLOCATE curOptions
				
                            DECLARE curOptions CURSOR LOCAL FORWARD_ONLY STATIC READ_ONLY
                            FOR
                                SELECT DISTINCT
                                        [idfieldmapping]
                                FROM    [dbo].[EASY__FIELDMAPPING]
                                WHERE   [easytable] = @@easytable 

				
                            OPEN curOptions 
                            FETCH NEXT FROM curOptions INTO @idfieldmapping
                            WHILE @@FETCH_STATUS = 0
                                AND @@errormessage = N'' 
                                BEGIN      
                                    EXEC [dbo].[csp_easytopro_update_easy__optionmapping] @@fieldmapping = @idfieldmapping,
                                        @@errormessage = @@errormessage OUTPUT
                                
                                    FETCH NEXT FROM curOptions INTO @idfieldmapping
                                END
                            CLOSE curOptions
                            DEALLOCATE curOptions
                        END
                END TRY
                BEGIN CATCH
                    SET @@errormessage = ERROR_MESSAGE()
                END CATCH
            END
        
    END