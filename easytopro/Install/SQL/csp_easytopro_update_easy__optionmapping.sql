CREATE PROCEDURE [dbo].[csp_easytopro_update_easy__optionmapping]
    (
      @@idoptionmapping INT = NULL ,
      @@fieldmapping INT ,
      @@idstringlimepro INT = -1 ,
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
  
        BEGIN TRY
            IF ( @@idoptionmapping IS NULL ) 
                BEGIN
                   
                   
                
                    UPDATE  [dbo].[EASY__OPTIONMAPPING]
                    SET     [idcategorylimepro] = ISNULL(( SELECT TOP 1
                                                              CAST(a.[value] AS INT)
                                                           FROM
                                                              [dbo].[EASY__FIELDMAPPING] ef
                                                              INNER JOIN [dbo].[fieldcache] fc ON fc.[name] = ef.[profieldname]
                                                              INNER JOIN [dbo].[table] t ON fc.[idtable] = t.[idtable]
                                                              AND t.[name] = ef.[protable]
                                                              INNER JOIN [dbo].[attributedata] a ON a.[idrecord] = fc.[idfield]
                                                              AND a.[owner] = N'field'
                                                              AND a.[name] = N'idcategory'
                                                           WHERE
                                                              ef.[idfieldmapping] = @@fieldmapping
                                                         ), -1) ,
                            [idstringlimepro] = -1
                    WHERE   [fieldmapping] = @@fieldmapping
                    
                    SET @@errormessage = N''
                    
                END
            ELSE 
                BEGIN
			
                    IF EXISTS ( SELECT  [idoptionmapping]
                                FROM    [dbo].[EASY__OPTIONMAPPING]
                                WHERE   [idoptionmapping] = @@idoptionmapping
                                        AND [fieldmapping] = @@fieldmapping ) 
                        BEGIN
                            UPDATE  [dbo].[EASY__OPTIONMAPPING]
                            SET     [idstringlimepro] = @@idstringlimepro
                            WHERE   [idoptionmapping] = @@idoptionmapping
                                    AND [fieldmapping] = @@fieldmapping
			         
		
                            SET @@errormessage = N''
                        END
                    ELSE 
                        BEGIN
                            SET @@errormessage = N'No optionmapping exists for idoptionmapping: '
                                + ISNULL(CAST(@@idoptionmapping AS NVARCHAR(32)),
                                         N'') + N' and fieldmapping: '
                                + ISNULL(CAST(@@fieldmapping AS NVARCHAR(32)),
                                         N'')
                        END
                END
		
        END TRY
        BEGIN CATCH
            SET @@errormessage = ERROR_MESSAGE()
        END CATCH
    
        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''
        
    END