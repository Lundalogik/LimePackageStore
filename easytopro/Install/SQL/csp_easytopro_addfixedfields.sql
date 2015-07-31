CREATE PROCEDURE [dbo].[csp_easytopro_addfixedfields]
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
        DECLARE @easyprofieldtype INT
        DECLARE @relatedtable NVARCHAR(64)
        DECLARE @isnullable INT
            
           
                       
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
                    [localname_da]
            FROM    [dbo].[EASY__FIELDMAPPING]
            WHERE   easytable = @@easytable
                    AND issuperfield = 0
                    AND active = 1
		

        OPEN field_cursor
        FETCH NEXT FROM field_cursor INTO @idfieldmapping, @protable,
            @profield, @easyprofieldtype, @sv, @en_us, @no, @fi, @da
        WHILE @@FETCH_STATUS = 0
            AND @@errormessage = N'' 
            BEGIN
                SET @length = NULL
                SET @isnullable = 0

                IF ( @easyprofieldtype = 1 ) 
                    SET @length = 256
					
                IF ( @easyprofieldtype IN ( 3, 4, 7, 16 ) ) 
                    SET @isnullable = 1
					
                BEGIN TRY
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @protable
                                            AND f.[name] = @profield ) 
                        BEGIN
                            IF ( @easyprofieldtype != 16 ) 
                                BEGIN
                                    EXECUTE [dbo].[csp_easytopro_addfield] @@table = @protable,
                                        @@name = @profield,
                                        @@fieldtype = @easyprofieldtype,
                                        @@isnullable = @isnullable, @@sv = @sv,
                                        @@en_us = @en_us, @@no = @no,
                                        @@fi = @fi, @@da = @da,
                                        @@length = @length,
                                        @@errormessage = @@errormessage OUTPUT  
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
                    @profield, @easyprofieldtype, @sv, @en_us, @no, @fi, @da
            END
				
        CLOSE field_cursor
        DEALLOCATE field_cursor    

        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''

    END