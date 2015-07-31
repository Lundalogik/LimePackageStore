CREATE PROCEDURE [dbo].[csp_easytopro_addfixedrelationfields]
    (
      @@easytable NVARCHAR(64) ,
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
         
        
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
            -- DECLARATIONS
        DECLARE @easyprofieldtype INT
        DECLARE @protable NVARCHAR(64)
        DECLARE @profield NVARCHAR(64)
        DECLARE @relatedeasytable NVARCHAR(64)
        DECLARE @relatedprotable NVARCHAR(64)
        DECLARE @localname_sv NVARCHAR(64)
        DECLARE @localname_en_us NVARCHAR(64)
        DECLARE @localname_no NVARCHAR(64)
        DECLARE @localname_fi NVARCHAR(64)
        DECLARE @localname_da NVARCHAR(64)

        SET @@errormessage = N''
                       
        DECLARE field_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
            SELECT  [protable] ,
                    [profieldname] ,
                    [localname_sv] ,
                    [localname_en_us] ,
                    [localname_no] ,
                    [localname_fi] ,
                    [localname_da] ,
                    [easyprofieldtype] ,
                    [relatedeasytable]
            FROM    [dbo].[EASY__FIELDMAPPING]
            WHERE   easytable = @@easytable
                    AND issuperfield = 2
                    AND active = 1
		

        OPEN field_cursor
        FETCH NEXT FROM field_cursor INTO @protable, @profield, @localname_sv,
            @localname_en_us, @localname_no, @localname_fi, @localname_da, @easyprofieldtype,
            @relatedeasytable        
        WHILE @@FETCH_STATUS = 0
            AND @@errormessage = N'' 
            BEGIN
       
                SELECT TOP 1
                        @relatedprotable = [protable]
                FROM    [dbo].[EASY__FIELDMAPPING]
                WHERE   [easytable] = @relatedeasytable
                        AND [issuperfield] = 0
       
                IF ( LEN(ISNULL(@relatedprotable, N'')) > 0 ) 
                    BEGIN
                        IF EXISTS ( SELECT  [idtable]
                                    FROM    dbo.[table]
                                    WHERE   [name] = @relatedprotable ) 
                            BEGIN
						 
                                IF NOT EXISTS ( SELECT  f.[idfield]
                                                FROM    [dbo].[fieldcache] f
                                                        INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                WHERE   t.[name] = @protable
                                                        AND f.[name] = @profield ) 
                                    BEGIN
					
                                        BEGIN TRY
					
                                            EXECUTE [dbo].[csp_easytopro_addrelation] @@tablename = @protable,
                                                @@fieldname = @profield,
                                                @@sv = @localname_sv,
                                                @@en_us = @localname_en_us,
                                                @@no = @localname_no,
                                                @@fi = @localname_fi,
                                                @@da = @localname_da,
                                                @@relatedtablename = @relatedprotable,
                                                @@errormessage = @@errormessage OUTPUT 
					
                                        END TRY
                                        BEGIN CATCH
                                            SET @@errormessage = ERROR_MESSAGE()
                                        END CATCH
                                    END
                            END
                    END
            
                FETCH NEXT FROM field_cursor INTO @protable, @profield,
                    @localname_sv, @localname_en_us, @localname_no,
                    @localname_fi, @localname_da, @easyprofieldtype, 
                    @relatedeasytable  
            END
				
        CLOSE field_cursor
        DEALLOCATE field_cursor    
			
        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''

    END