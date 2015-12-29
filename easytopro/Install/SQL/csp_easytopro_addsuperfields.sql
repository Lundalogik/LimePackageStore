CREATE PROCEDURE [dbo].[csp_easytopro_addsuperfields]
    (
      @@easytable NVARCHAR(64) ,
      @@lang NVARCHAR(256) = N'sv' ,
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
         
        
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;

        DECLARE @idfieldmapping INT
        DECLARE @protable NVARCHAR(64)
        DECLARE @profield NVARCHAR(64)
        DECLARE @sv NVARCHAR(64)
        DECLARE @en_us NVARCHAR(64)
        DECLARE @no NVARCHAR(64)
        DECLARE @fi NVARCHAR(64)
        DECLARE @da NVARCHAR(64)
        DECLARE @length INT
        DECLARE @width INT
        DECLARE @easyprofieldtype INT
        DECLARE @relatedtable NVARCHAR(64)
        DECLARE @isnullable INT
        DECLARE @easyfieldid NVARCHAR(64)
        DECLARE @idcategory INT
        DECLARE @idstring INT
            
        SELECT TOP 1
                @relatedtable = [protable]
        FROM    [dbo].[EASY__FIELDMAPPING]
        WHERE   [easytable] = N'USER'
                AND LEN(ISNULL([protable], N'')) > 0
                AND [transfertable] = 1
            
            --SELECT TOP 1 t.[name] FROM [dbo].[fieldcache] f INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable] WHERE f.[fieldtype] = 17
                       
        SET @@errormessage = N''
            
        DECLARE field_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
            SELECT  [idfieldmapping] ,
                    [protable] ,
                    [profieldname] ,
                    [easyprofieldtype] ,
                    [localname_sv] ,
                    [localname_en_us] ,
                    [localname_no] ,
                    [localname_fi] ,
                    [localname_da] ,
                    [easyfieldid]
            FROM    [dbo].[EASY__FIELDMAPPING]
            WHERE   easytable = @@easytable
                    AND issuperfield = 1
                    AND active = 1
		

        OPEN field_cursor
        FETCH NEXT FROM field_cursor INTO @idfieldmapping, @protable,
            @profield, @easyprofieldtype, @sv, @en_us, @no, @fi, @da, @easyfieldid
        WHILE @@FETCH_STATUS = 0
            AND @@errormessage = N'' 
            BEGIN
                SET @length = NULL
                SET @width = NULL
                SET @isnullable = 0
                SET @idcategory = NULL
				
                IF ( @easyprofieldtype = 1 OR @easyprofieldtype = 12 ) -- Textfield or linkfield
                    --Set length of textfield by checking how many characters are actually used (and add some extra). If no data is found, use default value 32
                    SET @length = ISNULL((SELECT TOP 1 LEN(Data) FROM EASY__DATA WHERE [Field ID]=@easyfieldid ORDER BY LEN(data) DESC) + 10,32)
                
                --Get width from EASY__FIELD and adjust it to match width in Pro: (Easywidth + 1) * 3
                SET @width = ((SELECT TOP 1 [Field width] FROM EASY__FIELD WHERE [Field ID]=@easyfieldid) + 1) * 3
                
                IF ( @easyprofieldtype IN ( 3, 4, 7, 16 ) ) 
                    SET @isnullable = 1
					
                BEGIN TRY
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @protable
                                            AND f.[name] = @profield ) 
                        BEGIN
                            IF ( @easyprofieldtype = 16
                                 AND LEN(ISNULL(@relatedtable, N'')) > 0
                               ) 
                                BEGIN
                                    EXECUTE [dbo].[csp_easytopro_addrelation] @@tablename = @protable,
                                        @@fieldname = @profield, @@sv = @sv,
                                        @@en_us = @en_us, @@no = @no,
                                        @@fi = @fi, @@da = @da,
                                        @@relatedtablename = @relatedtable,
                                        @@errormessage = @@errormessage OUTPUT 
                                END
                            ELSE 
                                IF ( @easyprofieldtype != 16 ) 
                                    BEGIN
                                        EXECUTE [dbo].[csp_easytopro_addfield] @@table = @protable,
                                            @@name = @profield,
                                            @@fieldtype = @easyprofieldtype,
                                            @@isnullable = @isnullable,
                                            @@sv = @sv, @@en_us = @en_us,
                                            @@no = @no, @@fi = @fi,
                                            @@da = @da,
                                            @@length = @length,
                                            @@width = @width,
                                            @@errormessage = @@errormessage OUTPUT,
                                            @@idcategory = @idcategory OUTPUT
                                    END
                                -- If the new field is an option field (fieldtype 21), set stringorder to 1 for the empty option that was automatically created
								IF ( @easyprofieldtype = 21 AND @idcategory IS NOT NULL )
									BEGIN
										SET @idstring = 
											(SELECT TOP 1 [idstring]
												FROM [dbo].[string]
                                                WHERE [idcategory] = @idcategory)
                                                
										EXECUTE lsp_setstringattributevalue @@idstring = @idstring,
												@@name = N'stringorder',
												@@valueint = 1
									END
                        END
                            
                    IF EXISTS ( SELECT  *
                                FROM    [dbo].[EASY__OPTIONMAPPING]
                                WHERE   [fieldmapping] = @idfieldmapping
                                        AND ISNULL([idstringlimepro], -1) < 0 ) 
                        BEGIN
                            EXEC [dbo].[csp_easytopro_addoptions] @@idfieldmapping = @idfieldmapping,
                                @@protablename = @protable,
                                @@profieldname = @profield, @@lang = @@lang,
                                @@errormessage = @@errormessage OUTPUT
                        END
                            
                END TRY
                BEGIN CATCH
                    SET @@errormessage = ERROR_MESSAGE()
                END CATCH
                FETCH NEXT FROM field_cursor INTO @idfieldmapping, @protable,
                    @profield, @easyprofieldtype, @sv, @en_us, @no, @fi, @da, @easyfieldid    
            END
				
        CLOSE field_cursor
        DEALLOCATE field_cursor    

        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''

    END