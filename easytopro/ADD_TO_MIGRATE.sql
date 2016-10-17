IF ( OBJECT_ID('cfn_easytopro_formathistorydate') > 0 )
	BEGIN
		DROP FUNCTION cfn_easytopro_formathistorydate
	END
GO


CREATE FUNCTION [dbo].[cfn_easytopro_formathistorydate]
    (
      @historydate NVARCHAR(16) ,
      @historydateformat NVARCHAR(10)
    )
RETURNS DATETIME
AS 
    BEGIN
        DECLARE @result NVARCHAR(16)
        DECLARE @date DATETIME
    
        SELECT  @result = SUBSTRING(@historydate,
                                    CHARINDEX(N'yyyy', @historydateformat), 4)
                + N'-' + SUBSTRING(@historydate,
                                   CHARINDEX(N'MM', @historydateformat), 2)
                + N'-' + SUBSTRING(@historydate,
                                   CHARINDEX(N'dd', @historydateformat), 2)
                + N' ' + SUBSTRING(@historydate, 12, 6)

        IF ( ISDATE(@result) = 0 ) 
            BEGIN
                SELECT  @date = [dbo].[lfn_formatfieldtime](GETDATE(), 0)
            END
        ELSE 
            BEGIN
                SELECT  @date = CAST(@result AS DATETIME)
            END
	
        RETURN @date
	
    END
GO


IF ( OBJECT_ID('cfn_easytopro_geteasydatatypetext') > 0 )
	BEGIN
		DROP FUNCTION cfn_easytopro_geteasydatatypetext
	END
GO


CREATE FUNCTION [dbo].[cfn_easytopro_geteasydatatypetext]
    (
      @datatype INT ,
      @datatypedata INT
    )
RETURNS NVARCHAR(64)
AS 
    BEGIN

        DECLARE @result NVARCHAR(64)

        SELECT  @result = CASE @datatype
                            WHEN 0 THEN CASE @datatypedata
                                          WHEN 0 THEN N'TEXT'
                                          WHEN 1 THEN N'PHONE(TEXT)'
                                          WHEN 2 THEN N'EMAIL'
                                          WHEN 4 THEN N'FAX(TEXT)'
                                          WHEN 8 THEN N'WWW'
                                          WHEN 16 THEN N'DATE'
                                          WHEN 32 THEN N'INT'
                                          WHEN 64 THEN N'SKYPE'
                                          ELSE N'TEXT'
                                        END
                            WHEN 1 THEN N'YES/NO'
                            WHEN 2 THEN N'OPTION'
                            WHEN 3 THEN N'TEXT OPTION'
                            WHEN 4 THEN N'COWORKER'
                            WHEN 5 THEN N'SET'
                          END 
                            
        RETURN ISNULL(@result, N'UNKNOWN')
    END
GO


IF ( OBJECT_ID('cfn_easytopro_geteasyprofieldtype') > 0 )
	BEGIN
		DROP FUNCTION cfn_easytopro_geteasyprofieldtype
	END
GO


CREATE FUNCTION [dbo].[cfn_easytopro_geteasyprofieldtype]
    (
      @datatype INT ,
      @datatypedata INT
    )
RETURNS INT
AS 
    BEGIN

        DECLARE @result INT

        SELECT  @result = CASE @datatype
                            WHEN 0 THEN CASE @datatypedata
                                          WHEN 0 THEN 1 --N'TEXT'
                                          WHEN 1 THEN 23 --N'PHONE(TEXT)'
                                          WHEN 2 THEN 12 -- N'EMAIL'
                                          WHEN 4 THEN 23 --N'FAX(TEXT)'
                                          WHEN 8 THEN 12 --N'WWW'
                                          WHEN 16 THEN 7 -- N'DATE'
                                          WHEN 32 THEN 3 --N'INT'
                                          WHEN 64 THEN 1 --N'SKYPE'
                                          ELSE 1 --N'TEXT'
                                        END
                            WHEN 1 THEN 13 --N'YES/NO'
                            WHEN 2 THEN 21 --N'OPTION'
                            WHEN 3 THEN 1 --N'TEXT OPTION'
                            WHEN 4 THEN 16 --N'COWORKER'
                            WHEN 5 THEN 20 --N'SET' 
                          END 
                            
        RETURN ISNULL(@result, -1)
    END
GO


IF ( OBJECT_ID('cfn_easytopro_getidcategoryhistorytype') > 0 )
	BEGIN
		DROP FUNCTION cfn_easytopro_getidcategoryhistorytype
	END
GO


CREATE FUNCTION [dbo].[cfn_easytopro_getidcategoryhistorytype] ( )
RETURNS INT
AS 
    BEGIN
        DECLARE @idcategory INT 

        SELECT TOP 1
                @idcategory = o.[idcategorylimepro]
        FROM    [dbo].[EASY__FIELDMAPPING] e
                INNER JOIN [dbo].[EASY__OPTIONMAPPING] o ON o.[fieldmapping] = e.[idfieldmapping]
        WHERE   [easytable] = N'HISTORY'
                AND [easyfieldid] = N'history_type'

            
        RETURN ISNULL(@idcategory,-1)
    END
GO


IF ( OBJECT_ID('cfn_easytopro_validatehistorylength') > 0 )
	BEGIN
		DROP FUNCTION cfn_easytopro_validatehistorylength
	END
GO


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
GO


IF ( OBJECT_ID('csp_easytopro_addfield') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_addfield
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_addfield]
    (
      @@table NVARCHAR(64) ,
      @@name NVARCHAR(64) ,
      @@fieldtype INT ,
      @@length INT = NULL ,
      @@width INT = NULL ,
      @@height INT = NULL ,
      @@isnullable INT = NULL ,
      @@limereadonly INT = NULL ,
      @@sv NVARCHAR(MAX) = NULL ,
      @@en_us NVARCHAR(MAX) = NULL ,
      @@no NVARCHAR(MAX) = NULL ,
      @@fi NVARCHAR(MAX) = NULL ,
      @@da NVARCHAR(MAX) = NULL,
      @@invisible INT = NULL,
      @@idcategory INT = NULL OUTPUT ,
      @@idfield INT = NULL OUTPUT ,
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
        
    )
AS 
    BEGIN
        DECLARE @localname INT
           
        BEGIN TRY
            EXEC dbo.lsp_addfield @@table = @@table, -- nvarchar(64)
                @@name = @@name, -- nvarchar(64)
                @@fieldtype = @@fieldtype, -- INT
                @@isnullable = @@isnullable, -- INT
                @@length = @@length, -- int
                @@localname = @localname OUTPUT, -- int
                @@idcategory = @@idcategory OUTPUT, -- int
                @@idfield = @@idfield OUTPUT
	
            IF ( LEN(ISNULL(@@sv, N'')) > 0 ) 
                EXEC [dbo].[lsp_setstringattributevalue] @@idstring = @localname,
                    @@name = N'sv', @@value = @@sv
						
            IF ( LEN(ISNULL(@@en_us, N'')) > 0 ) 
                EXEC [dbo].[lsp_setstringattributevalue] @@idstring = @localname,
                    @@name = N'en_us', @@value = @@en_us
						
            IF ( LEN(ISNULL(@@no, N'')) > 0 ) 
                EXEC [dbo].[lsp_setstringattributevalue] @@idstring = @localname,
                    @@name = N'no', @@value = @@no
						
            IF ( LEN(ISNULL(@@fi, N'')) > 0 ) 
                EXEC [dbo].[lsp_setstringattributevalue] @@idstring = @localname,
                    @@name = N'fi', @@value = @@fi
                    
            IF ( LEN(ISNULL(@@da, N'')) > 0 ) 
                EXEC [dbo].[lsp_setstringattributevalue] @@idstring = @localname,
                    @@name = N'da', @@value = @@da
            
            IF ( ISNULL(@@width, 0) > 0 ) 
                BEGIN
            
                    EXEC [dbo].[lsp_setattributevalue] @@owner = N'field', -- nvarchar(64)
                        @@idrecord = @@idfield, -- int
                        @@idrecord2 = NULL, -- int
                        @@iduser = 1, @@name = N'width', -- nvarchar(64)
                        @@valueint = @@width
                END
			
            IF ( ISNULL(@@height, 0) > 0 ) 
                BEGIN
            
                    EXEC [dbo].[lsp_setattributevalue] @@owner = N'field', -- nvarchar(64)
                        @@idrecord = @@idfield, -- int
                        @@idrecord2 = NULL, -- int
                        @@iduser = 1, @@name = N'height', -- nvarchar(64)
                        @@valueint = @@width
                END
                
            IF ( ISNULL(@@limereadonly, 0) = 1 ) 
                BEGIN
                    EXEC [dbo].[lsp_setattributevalue] @@owner = N'field', -- nvarchar(64)
                        @@idrecord = @@idfield, -- int
                        @@idrecord2 = NULL, -- int
                        @@iduser = 1, @@name = N'limereadonly', -- nvarchar(64)
                        @@valueint = 1
                END
                
            IF ( ISNULL(@@invisible, 0) = 1 ) 
                BEGIN
                    EXEC [dbo].[lsp_setattributevalue] @@owner = N'field', -- nvarchar(64)
                        @@idrecord = @@idfield, -- int
                        @@idrecord2 = NULL, -- int
                        @@iduser = 1, @@name = N'invisible', -- nvarchar(64)
                        @@valueint = 1
                END
			
            SET @@errormessage = N''
        END TRY
        BEGIN CATCH
            SET @@errormessage = ERROR_MESSAGE()
        END CATCH
    END
GO


IF ( OBJECT_ID('csp_easytopro_addfixedfields') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_addfixedfields
	END
GO


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
GO


IF ( OBJECT_ID('csp_easytopro_addfixedrelationfields') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_addfixedrelationfields
	END
GO


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
GO


IF ( OBJECT_ID('csp_easytopro_addoptions') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_addoptions
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_addoptions]
    (
      @@idfieldmapping INT ,
      @@protablename NVARCHAR(64) ,
      @@profieldname NVARCHAR(64) ,
      @@lang NVARCHAR(256) = N'sv' ,
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
	)
AS 
    BEGIN


        DECLARE @idoptionmapping INT
        DECLARE @string NVARCHAR(512)
        DECLARE @sql NVARCHAR(MAX)
        DECLARE @idfield INT
        DECLARE @idcategory INT
        DECLARE @profieldname NVARCHAR(64)
        DECLARE @protablename NVARCHAR(64)
        DECLARE @idstring INT
        DECLARE @stringorder INT

        IF EXISTS ( SELECT  *
                    FROM    [dbo].[EASY__OPTIONMAPPING]
                    WHERE   [fieldmapping] = @@idfieldmapping
                            AND ISNULL([idstringlimepro], -1) < 0 ) 
            BEGIN
            
                SELECT  @idfield = f.[idfield] ,
                        @idcategory = CAST(a.[value] AS INT)
                FROM    [dbo].[fieldcache] f
                        INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                      AND t.[name] = @@protablename
                        LEFT JOIN [dbo].[attributedata] a ON f.[idfield] = a.[idrecord]
                                                             AND a.[owner] = N'field'
                                                             AND a.[name] = 'idcategory'
                WHERE   f.[name] = @@profieldname
                BEGIN TRY
                                                
                    IF ( ( @idcategory IS NULL )
                         AND ( @idfield IS NOT NULL )
                       ) 
                        BEGIN
                            SET @idcategory = -1
                            EXECUTE lsp_setfieldattributevalue @@idfield = @idfield,
                                @@name = N'idcategory',
                                @@valueint = @idcategory OUTPUT
                 
                        END
                
                    IF ( ISNULL(@idcategory, 0) > 0 ) 
                        BEGIN
                            IF OBJECT_ID('curOptions') IS NOT NULL 
                                DEALLOCATE curOptions
				
                            DECLARE curOptions CURSOR LOCAL FORWARD_ONLY STATIC READ_ONLY
                            FOR
                                SELECT DISTINCT
                                        [idoptionmapping] ,
                                        [easyvalue]
                                FROM    [dbo].[EASY__OPTIONMAPPING]
                                WHERE   [fieldmapping] = @@idfieldmapping
                                        AND ISNULL([idstringlimepro], -1) < 0 

				
                            OPEN curOptions 
                            FETCH NEXT FROM curOptions INTO @idoptionmapping,
                                @string
                            WHILE @@FETCH_STATUS = 0 
                                BEGIN        
                                    IF @string IS NOT NULL 
                                        BEGIN
                                            SET @sql = N''
                                            SET @sql = N'
                                IF NOT EXISTS ( SELECT  [idstring]
                                                FROM    [dbo].[string]
                                                WHERE ' + QUOTENAME(@@lang)
                                                + N' = ''' + REPLACE(@string,N'''',N'''''')
                                                + N''' AND [idcategory] = '
                                                + CAST(@idcategory AS NVARCHAR(32))
                                                + N')
                                    BEGIN
                                        EXEC dbo.lsp_addstring @@idcategory = '
                                                + CAST(@idcategory AS NVARCHAR(32))
                                                + N', 
                                            @@string = ''' + REPLACE(@string,N'''',N'''''')
                                                + N''',
                                             
                                            @@user = 1 , @@idstring	= @idstringOUT OUTPUT
                                    END 
                                    ELSE
                                    BEGIN
                                    SELECT TOP 1 @idstringOUT = [idstring]
                                                FROM    [dbo].[string]
                                                WHERE ' + QUOTENAME(@@lang)
                                                + N' = ''' + REPLACE(@string,N'''',N'''''')
                                                + N''' AND [idcategory] = '
                                                + CAST(@idcategory AS NVARCHAR(32))
                                                + CHAR(10) + N'END'
                                    
								 --EXECUTE sp_executesql @sql
                                            SET @idstring = NULL
								 --PRINT @sql
                                            EXEC sp_executesql @sql,
                                                N'@idstringOUT INT OUTPUT',
                                                @idstringOUT = @idstring OUTPUT
								 
                                            IF ( ISNULL(@idstring, 0) > 0 ) 
                                                BEGIN
                                                    UPDATE  [dbo].[EASY__OPTIONMAPPING]
                                                    SET     [idstringlimepro] = @idstring ,
                                                            [idcategorylimepro] = @idcategory
                                                    WHERE   [idoptionmapping] = @idoptionmapping
                                                
                                                    SELECT  @stringorder = ISNULL(MAX([stringorder]),
                                                              0) + 1
                                                    FROM    [dbo].[string]
                                                    WHERE   [idcategory] = @idcategory 

                                                    SET @stringorder = ISNULL(@stringorder,
                                                              1)

                                                    EXECUTE lsp_setstringattributevalue @@idstring = @idstring,
                                                        @@name = N'stringorder',
                                                        @@valueint = @stringorder
                                                
                                                END
								 
                                        END
                                    FETCH NEXT FROM curOptions INTO @idoptionmapping,
                                        @string
                                END
                            CLOSE curOptions
                            DEALLOCATE curOptions
                        END  
                END TRY
                BEGIN CATCH
                    SET @@errormessage = ERROR_MESSAGE()
                END CATCH
                 
            END
            
        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''
    END
GO


IF ( OBJECT_ID('csp_easytopro_addrelation') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_addrelation
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_addrelation]
    (
      @@tablename NVARCHAR(64) ,
      @@fieldname NVARCHAR(64) ,
      @@sv NVARCHAR(64) = NULL ,
      @@en_us NVARCHAR(64) = NULL ,
      @@no NVARCHAR(64) = NULL ,
      @@fi NVARCHAR(64) = NULL ,
      @@da NVARCHAR(64) = NULL,
      @@relatedtablename NVARCHAR(64) ,
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
         
        
    )
AS 
    BEGIN
        DECLARE @localname INT
           
        DECLARE @idtable INT 
        DECLARE @length INT
        DECLARE @width INT
        DECLARE @height INT

        DECLARE @idfield INT
        DECLARE @idfield1 INT
        DECLARE @idfield2 INT
        DECLARE @isnullable INT 
        DECLARE @fieldtype INT
		
        DECLARE @relatedtabletabname NVARCHAR(64)
        DECLARE @namesuffix INT

	
        SET @fieldtype = 16 -- relation
        SET @isnullable = 1
        SET @namesuffix = 0
        SET @relatedtabletabname = @@tablename
        BEGIN TRY
    -- ADD RELATIONFIELD TO TABLE
            SET @idfield = NULL


            EXEC [dbo].[csp_easytopro_addfield] @@table = @@tablename,
                @@name = @@fieldname, @@fieldtype = @fieldtype,
                @@isnullable = @isnullable, @@sv = @@sv, @@en_us = @@en_us,
                @@no = @@no, @@fi = @@fi, @@da = @@da, @@idfield = @idfield OUTPUT 

            SET @idfield1 = @idfield

-- ADD RELATIONFIELD TO RELATED TABLE

            WHILE EXISTS ( SELECT   *
                           FROM     [dbo].[fieldcache] f
                                    INNER JOIN [dbo].[table] t ON t.idtable = f.idtable
                           WHERE    t.name = @@relatedtablename
                                    AND f.[name] = @relatedtabletabname ) 
                BEGIN
                    SET @namesuffix = @namesuffix + 1
                    SELECT  @relatedtabletabname = @relatedtabletabname
                            + CAST(@namesuffix AS NVARCHAR(32))
                END

            SET @idfield = NULL

            EXEC [dbo].[csp_easytopro_addfield] @@table = @@relatedtablename,
                @@name = @relatedtabletabname, @@fieldtype = @fieldtype,
                @@isnullable = @isnullable, @@sv = @relatedtabletabname,
                @@en_us = @relatedtabletabname, @@no = @relatedtabletabname,
                @@fi = @relatedtabletabname, @@da = @relatedtabletabname,
                @@idfield = @idfield OUTPUT 

            SET @idfield2 = @idfield			
			
		-- MAKE SURE RELATION FIELD IN TABLE(1) 
            EXEC lsp_setfieldattributevalue @@idfield = @idfield2,
                @@name = N'relationmaxcount', @@valueint = 1
						
		-- SETUP RELATION
            EXEC lsp_addrelation @@idfield1 = @idfield1,
                @@idfield2 = @idfield2
            SET @@errormessage = N''
        END TRY
        BEGIN CATCH
            SET @@errormessage = ERROR_MESSAGE()
        END CATCH
    END
GO


IF ( OBJECT_ID('csp_easytopro_addsuperfields') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_addsuperfields
	END
GO


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
GO


IF ( OBJECT_ID('csp_easytopro_addsuperfieldsto_easy__fieldmapping') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_addsuperfieldsto_easy__fieldmapping
	END
GO


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
GO


IF ( OBJECT_ID('csp_easytopro_archive') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_archive
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_archive]
    @@xml AS NVARCHAR(MAX) ,
    @@rebuildtable AS BIT
    --@@documentpath AS NVARCHAR(MAX) = ''
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @iXML INT
        
  --      -- Delete spaces and add backslash to documentpath
  --      SET @@documentpath = LTRIM(RTRIM(@@documentpath))
		--IF(RIGHT(@@documentpath,1) <> '\' AND @@documentpath <> '')
		--BEGIN
		--	SET @@documentpath = @@documentpath + '\'
		--END

        IF ( @@rebuildtable = 1 ) 
            BEGIN


                IF EXISTS ( SELECT  *
                            FROM    sys.objects
                            WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__ARCHIVE]')
                                    AND type IN ( N'U' ) ) 
                    DROP TABLE [dbo].[EASY__ARCHIVE]


                CREATE TABLE [dbo].[EASY__ARCHIVE]
                    (
                      [Type] SMALLINT NOT NULL ,
                      [Key 1] INT NOT NULL ,
                      [Key 2] INT NOT NULL ,
                      [Path] NVARCHAR(128) ,
                      [Date] DATETIME ,
                      [Time] INT ,
                      [Comment] NVARCHAR(96) ,
                      [User ID] SMALLINT ,
                      [Reference] NVARCHAR(48)
                    )

            END

        EXEC sp_xml_preparedocument @iXML OUTPUT, @@xml

        INSERT  INTO [dbo].[EASY__ARCHIVE]
                ( [Type] ,
                  [Key 1] ,
                  [Key 2] ,
                  [Path] ,
                  [Date] ,
                  [Time] ,
                  [Comment] ,
                  [User ID] ,
                  [Reference]
                )
                SELECT  [type] ,
                        [key1] ,
                        [key2] ,
                        ---- Only add documentpath if filename is missing path
                        --CASE WHEN [path] LIKE '%:\%' OR [path] LIKE '%\\%' THEN [path] ELSE @@documentpath + [path] END ,
                        [path] ,
                        CASE WHEN [date] = N'' THEN NULL ELSE CAST([date] AS DATETIME) END ,
                        [time] ,
                        [comment] ,
                        [userid] ,
                        [reference]
                FROM    OPENXML(@iXML, '/data/row')
	WITH (	
	[type] SMALLINT,
                  [key1] INT ,
                  [key2] INT,
                  [path] NVARCHAR(128),
                  [date] NVARCHAR(32),
                  [time] INT,
                  [comment] NVARCHAR(96),
                  [userid] SMALLINT,
                  [reference]NVARCHAR(48)
		) 
	

        EXECUTE sp_xml_removedocument @iXML
    END
GO


IF ( OBJECT_ID('csp_easytopro_checkrequiredtables') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_checkrequiredtables
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_checkrequiredtables]
    (
      @@errormessage NVARCHAR(2048) OUTPUT
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @errormessage NVARCHAR(2048)
        SET @errormessage = N''
        
        IF NOT EXISTS ( SELECT  *
                        FROM    sys.objects
                        WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__FIELDMAPPING]')
                                AND type IN ( N'U' ) ) 
            BEGIN
                SET @errormessage = N' - The table [dbo].[EASY__FIELDMAPPING] is missing'
            END
        IF NOT EXISTS ( SELECT  *
                        FROM    sys.objects
                        WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__OPTIONMAPPING]')
                                AND type IN ( N'U' ) ) 
            BEGIN
                IF ( LEN(@errormessage) > 0 ) 
                    SET @errormessage = @errormessage + CHAR(10)
            	
                SET @errormessage = @errormessage
                    + N' - The table [dbo].[EASY__OPTIONMAPPING] is missing'
            END
        SET @@errormessage = ISNULL(@errormessage, N'')
    END
GO


IF ( OBJECT_ID('csp_easytopro_contact') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_contact
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_contact]
    @@xml AS NVARCHAR(MAX) ,
    @@rebuildtable AS BIT
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @iXML INT


        IF ( @@rebuildtable = 1 ) 
            BEGIN

                IF EXISTS ( SELECT  *
                            FROM    sys.objects
                            WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__CONTACT]')
                                    AND type IN ( N'U' ) ) 
                    DROP TABLE [dbo].[EASY__CONTACT] 


                CREATE TABLE [dbo].[EASY__CONTACT]
                    (
                      [Company ID] INT NOT NULL ,
                      [Company name] NVARCHAR(64) ,
                      [Suffix] NVARCHAR(48) ,
                      [Address] NVARCHAR(255) ,
                      [Telephone] NVARCHAR(48) ,
                      [Fax] NVARCHAR(48) ,
                      [Created date] DATETIME ,
                      [Created time] INT ,
                      [Created user ID] SMALLINT ,
                      [Updated date] DATETIME ,
                      [Updated time] INT ,
                      [Updated user ID] SMALLINT ,
                      [addresslinesbeforezip1] NVARCHAR(255) ,
                      [addresslinesbeforezip2] NVARCHAR(255) ,
                      [addresslinesbeforezip3] NVARCHAR(255) ,
                      [zipcode] NVARCHAR(255) ,
                      [city] NVARCHAR(255) ,
                      [addresslinesafterzip1] NVARCHAR(255) ,
                      [addresslinesafterzip2] NVARCHAR(255)
                    )
            END

        EXEC sp_xml_preparedocument @iXML OUTPUT, @@xml

        INSERT  INTO [dbo].[EASY__CONTACT]
                ( [Company ID] ,
                  [Company name] ,
                  [Suffix] ,
                  [Address] ,
                  [Telephone] ,
                  [Fax] ,
                  [Created date] ,
                  [Created time] ,
                  [Created user ID] ,
                  [Updated date] ,
                  [Updated time] ,
                  [Updated user ID] ,
                  [addresslinesbeforezip1] ,
                  [addresslinesbeforezip2] ,
                  [addresslinesbeforezip3] ,
                  [zipcode] ,
                  [city] ,
                  [addresslinesafterzip1] ,
                  [addresslinesafterzip2]
                )
                SELECT  [companyid] ,
                        [companyname] ,
                        [suffix] ,
                        [address] ,
                        [telephone] ,
                        [fax] ,
                        CASE WHEN [createddate] = N'' THEN NULL ELSE CAST([createddate] AS DATETIME) END ,
                        [createdtime] ,
                        [createduserid] ,
                        CASE WHEN [updateddate] = N'' THEN NULL ELSE CAST([updateddate] AS DATETIME) END ,
                        [updatedtime] ,
                        [updateduserid] ,
                        [addresslinesbeforezip1] ,
                        [addresslinesbeforezip2] ,
                        [addresslinesbeforezip3] ,
                        [zipcode] ,
                        [city] ,
                        [addresslinesafterzip1] ,
                        [addresslinesafterzip2]
                FROM    OPENXML(@iXML, '/data/row')
	WITH (	[companyid] INT, 
			[companyname] NVARCHAR(64), 
			[suffix] NVARCHAR(48),
			[address] NVARCHAR(255),
			[telephone] NVARCHAR(48),
			[fax] NVARCHAR(48),
			[createddate] NVARCHAR(32),
			[createdtime] INT ,
			[createduserid] SMALLINT,
			[updateddate] NVARCHAR(32) ,
			[updatedtime] INT,
			[updateduserid] SMALLINT ,
			[addresslinesbeforezip1] NVARCHAR(255),
			[addresslinesbeforezip2] NVARCHAR(255),
			[addresslinesbeforezip3] NVARCHAR(255),
			[zipcode] NVARCHAR(255),
			[city] NVARCHAR(255),
			[addresslinesafterzip1] NVARCHAR(255),
			[addresslinesafterzip2] NVARCHAR(255) 
		) 
	

        EXECUTE sp_xml_removedocument @iXML
    END
GO


IF ( OBJECT_ID('csp_easytopro_createandinsertfixedfields') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_createandinsertfixedfields
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_createandinsertfixedfields]
    (
      @@easytable NVARCHAR(64) ,
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
         
        
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
            --DECLARATIONS
        DECLARE @sql NVARCHAR(MAX)
        DECLARE @fieldtype INT
        DECLARE @insert NVARCHAR(MAX)
        DECLARE @select NVARCHAR(MAX)
        DECLARE @protable NVARCHAR(64) 
        DECLARE @profield NVARCHAR(64) 
        DECLARE @relatedprotable NVARCHAR(64)
        DECLARE @relatedeasytable NVARCHAR(64)
        DECLARE @selectstatement NVARCHAR(2048)
        DECLARE @issuperfield INT
        DECLARE @proposedvalue NVARCHAR(128) 
        DECLARE @easyfieldname NVARCHAR(64)
        DECLARE @defaultvalue NVARCHAR(128) 
        DECLARE @isrequired NVARCHAR(1)

-- SET INITIAL VALUES
        SELECT  @sql = N''
        SELECT  @select = N''
        SELECT  @insert = N''


        DECLARE row_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
            SELECT DISTINCT
                    e.[protable] ,
                    e.[easyfieldname] ,
                    e.[profieldname] ,
                    CASE WHEN LEN(ISNULL(e.proposedvalue, N'')) > 0
                         THEN REPLACE(e.[proposedvalue], N'''', N'''''')
                         ELSE ( SELECT  CASE WHEN [isnullable] = 1
                                                  AND [defaultvalue] = N''
                                             THEN CAST(N'NULL' AS NVARCHAR(128))
                                             ELSE CAST([defaultvalue] AS NVARCHAR(128))
                                        END
                                FROM    [dbo].[fieldcache] f
                                        INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                              AND t.[name] = e.protable
                                WHERE   f.[name] = e.[profieldname]
                              )
                    END ,
                    CASE WHEN EXISTS ( SELECT   f.[idfield]
                                       FROM     [dbo].[fieldcache] f
                                                INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                INNER JOIN [dbo].[attributedata] a ON a.[idrecord] = f.[idfield]
                                                              AND a.[owner] = N'field'
                                                              AND a.[name] = N'required'
                                       WHERE    e.[profieldname] = f.[name]
                                                AND e.[protable] = t.[name] )
                         THEN N'1'
                         ELSE N'0'
                    END ,
                    ( SELECT TOP 1
                                CASE WHEN [isnullable] = 1
                                          AND [defaultvalue] = N''
                                     THEN CAST(N'NULL' AS NVARCHAR(128))
                                     ELSE CAST([defaultvalue] AS NVARCHAR(128))
                                END
                      FROM      [dbo].[fieldcache] f
                                INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                      WHERE     e.[profieldname] = f.[name]
                                AND e.[protable] = t.[name]
                    ) ,
                    e.[easyprofieldtype] ,
                    e.[issuperfield]
            FROM    [dbo].[EASY__FIELDMAPPING] e
            WHERE   e.[easytable] = @@easytable
                    AND e.[issuperfield] = 0
                    AND LEN(e.[protable]) > 0
                    AND e.[transfertable] = 1
                    AND e.[active] = 1
            UNION
            SELECT DISTINCT
                    e.[protable] ,
                    N'' ,
                    e.[profieldname] ,
                    CASE WHEN LEN(ISNULL(e.proposedvalue, N'')) > 0
                         THEN REPLACE(e.[proposedvalue], N'''', N'''''')
                         ELSE ( SELECT  CASE WHEN [isnullable] = 1
                                                  AND [defaultvalue] = N''
                                             THEN CAST(N'NULL' AS NVARCHAR(128))
                                             ELSE CAST([defaultvalue] AS NVARCHAR(128))
                                        END
                                FROM    [dbo].[fieldcache] f
                                        INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                              AND t.[name] = e.protable
                                WHERE   f.[name] = e.[profieldname]
                              )
                    END ,
                    CASE WHEN EXISTS ( SELECT   f.[idfield]
                                       FROM     [dbo].[fieldcache] f
                                                INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                INNER JOIN [dbo].[attributedata] a ON a.[idrecord] = f.[idfield]
                                                              AND a.[owner] = N'field'
                                                              AND a.[name] = N'required'
                                       WHERE    e.[profieldname] = f.[name]
                                                AND e.[protable] = t.[name] )
                         THEN 1
                         ELSE 0
                    END ,
                    ( SELECT TOP 1
                                CASE WHEN [isnullable] = 1
                                          AND [defaultvalue] = N''
                                     THEN CAST(N'NULL' AS NVARCHAR(128))
                                     ELSE CAST([defaultvalue] AS NVARCHAR(128))
                                END
                      FROM      [dbo].[fieldcache] f
                                INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                      WHERE     e.[profieldname] = f.[name]
                                AND e.[protable] = t.[name]
                    ) ,
                    e.[easyprofieldtype] ,
                    e.[issuperfield]
            FROM    dbo.EASY__FIELDMAPPING e
                    INNER JOIN [dbo].[fieldcache] f ON f.[name] = e.[profieldname]
                    INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                  AND t.[name] = e.[protable]
            WHERE   LEN(ISNULL(e.[proposedvalue], N'')) > 0
                    AND e.[issuperfield] = 1
                    AND e.[easytable] = @@easytable
                    AND LEN(e.[protable]) > 0
                    AND e.[transfertable] = 1
                    AND e.[active] = 1

        OPEN row_cursor
        FETCH NEXT FROM row_cursor INTO @protable, @easyfieldname, @profield,
            @proposedvalue, @isrequired, @defaultvalue, @fieldtype,
            @issuperfield
        WHILE @@FETCH_STATUS = 0 
            BEGIN
    
                IF ( @@easytable != N'HISTORY' AND @@easytable != N'USER' ) -- HISTORY AND USER IS HANDLED IN OTHER CSP
                    BEGIN		
                        
                        SELECT  @select = @select + CHAR(10) + N', '
                                + N'ISNULL('
                                + CASE WHEN @@easytable = 'TODO'
                                            AND @easyfieldname = N'Start date'
                                       THEN N'DATEADD(SECOND, [Start time], '
                                            + QUOTENAME(@easyfieldname) + N')'
                                       WHEN @@easytable = 'TODO'
                                            AND @easyfieldname = N'Stop date'
                                       THEN N' CASE WHEN [Done date] IS NULL THEN DATEADD(SECOND, [Stop time], '
                                            + QUOTENAME(@easyfieldname)
                                            + N') ELSE DATEADD(SECOND, [Done time], [Done date]) END'
                                       WHEN @@easytable = 'TODO'
                                            AND @easyfieldname = N'Done'
                                       THEN N' CASE WHEN [Done date] IS NULL THEN 0 ELSE 1 END'
                                       WHEN @@easytable = 'ARCHIVE'
                                            AND @easyfieldname = N'Date'
                                       THEN N'DATEADD(SECOND, [Time], '
                                            + QUOTENAME(@easyfieldname) + N')'
                                       WHEN @issuperfield = 1 THEN N'NULL' -- ALWAYS USE PROPOSEDVALUE
                                       ELSE N'(CASE WHEN 1 = ' + @isrequired
                                            + N' THEN CASE WHEN '
                                            + QUOTENAME(@easyfieldname) + N'='
                                            + CASE WHEN @fieldtype IN ( 1, 12,
                                                              23 )
                                                   THEN N'N'''
                                                        + ISNULL(@defaultvalue,
                                                              N'') + N''''
                                                   WHEN @fieldtype = 20
                                                   THEN CASE WHEN LEN(ISNULL(@defaultvalue,
                                                              N'')) > 0
                                                             THEN N''';'
                                                              + ISNULL(@defaultvalue,
                                                              N'') + N';'')'
                                                             ELSE N'N'''' '
                                                        END
                                                   ELSE ISNULL(@defaultvalue,
                                                              N'')
                                              END + N' THEN '
                                            + CASE WHEN @fieldtype IN ( 1, 12,
                                                              23 )
                                                   THEN N'N'''
                                                        + ISNULL(@proposedvalue,
                                                              N'') + N''''
                                                   WHEN @fieldtype = 20
                                                   THEN CASE WHEN LEN(ISNULL(@proposedvalue,
                                                              N'')) > 0
                                                             THEN N''';'
                                                              + ISNULL(@proposedvalue,
                                                              N'') + N';'')'
                                                             ELSE N'N'''' '
                                                        END
                                                   ELSE ISNULL(@proposedvalue,
                                                              N'')
                                              END + N' ELSE '
                                            + QUOTENAME(@easyfieldname)
                                            + N' END ELSE '
                                            + QUOTENAME(@easyfieldname)
                                            + N' END ) '
                                  END + N', '
                                + CASE WHEN @fieldtype IN ( 1, 12, 23 )
                                       THEN N'N''' + ISNULL(@proposedvalue,
                                                            N'') + N''''
                                       WHEN @fieldtype = 20
                                       THEN CASE WHEN LEN(ISNULL(@proposedvalue,
                                                              N'')) > 0
                                                 THEN N''';'
                                                      + ISNULL(@proposedvalue,
                                                              N'') + N';'')'
                                                 ELSE N'N'''')'
                                            END
                                       ELSE ISNULL(@proposedvalue, N'')
                                  END + N')' ,
                                @insert = @insert + CHAR(10) + N', '
                                + QUOTENAME(@profield) 
                
                
                    END
        
                        
		
                FETCH NEXT FROM row_cursor INTO @protable, @easyfieldname,
                    @profield, @proposedvalue, @isrequired, @defaultvalue,
                    @fieldtype, @issuperfield
            END
				
        CLOSE row_cursor
        DEALLOCATE row_cursor    

        IF ( LEN(@select) > 0
             AND LEN(@insert) > 0
           ) 
            BEGIN
                SELECT  @sql = N'INSERT INTO [dbo].' + QUOTENAME(@protable)
                        + CHAR(10) + N' ([status]' + CHAR(10)
                        + CASE @@easytable
                            WHEN N'CONTACT' THEN N', [contact_limeeasyid]'
                            WHEN N'REFS'
                            THEN N', [contact_limeeasyid]' + CHAR(10)
                                 + N', [refs_limeeasyid]' + CHAR(10)
                                 + N', [easy_fullname]'
                            WHEN N'PROJECT' THEN N', [project_limeeasyid]'
                            WHEN N'TIME'
                            THEN N', [contact_limeeasyid]' + CHAR(10)
                                 + N', [time_limeeasyid]' + CHAR(10)
                                 + N', [user_limeeasyid]'
                            WHEN N'TODO'
                            THEN N', [contact_limeeasyid]' + CHAR(10)
                                 + N', [project_limeeasyid]' + CHAR(10)
                                 + N', [user_limeeasyid]' + CHAR(10)
                                 + N', [todo_limeeasyid]' + CHAR(10)
                                 + N', [todo_easytype]' + CHAR(10)
                                 + N', [todo_easykey1]' + CHAR(10)
                                 + N', [todo_easykey2]'
                            WHEN N'ARCHIVE'
                            THEN N', [contact_limeeasyid]' + CHAR(10)
                                 + N', [project_limeeasyid]' + CHAR(10)
                                 + N', [user_limeeasyid]' + CHAR(10)
                                 + N', [archive_limeeasyid]' + CHAR(10)
                                 + N', [archive_easytype]' + CHAR(10)
                                 + N', [archive_easykey1]' + CHAR(10)
                                 + N', [archive_easykey2]' + CHAR(10)
                                 + N', [archive_limeeasypath]'
                            --WHEN N'USER' THEN N', [user_limeeasyid]'
                          END + @insert + N')' + CHAR(10) + N'SELECT '
                        + CHAR(10) + N' 0' + CHAR(10)
                        + CASE @@easytable
                            WHEN N'CONTACT' THEN N', [Company ID]'
                            WHEN N'REFS'
                            THEN N', [Company ID]' + CHAR(10)
                                 + N', [Reference ID]' + CHAR(10)
                                 + N', [Name]'
                            WHEN N'PROJECT' THEN N', [Project ID]'
                            WHEN N'TIME'
                            THEN N', [Company ID]' + CHAR(10) + N', [Time ID]'
                                 + CHAR(10) + N', [User ID]'
                            WHEN N'TODO'
                            THEN N', CASE WHEN [Type] IN (0,8) THEN [Key 1] ELSE NULL END '
                                 + CHAR(10)
                                 + N', CASE WHEN [Type] = 2 THEN [Key 1] ELSE NULL END '
                                 + CHAR(10) + N', [User ID]' + CHAR(10)
                                 + N', [Key 2]' + CHAR(10) + N', [Type]'
                                 + CHAR(10) + N', [Key 1]' + CHAR(10)
                                 + N', [Key 2]'
                            WHEN N'ARCHIVE'
                            THEN N', CASE WHEN [Type] = 0 THEN [Key 1] ELSE NULL END '
                                 + CHAR(10)
                                 + N', CASE WHEN [Type] = 2 THEN [Key 1] ELSE NULL END '
                                 + CHAR(10) + N', [User ID]' + CHAR(10)
                                 + N', [Key 2]' + CHAR(10) + N', [Type]'
                                 + CHAR(10) + N', [Key 1]' + CHAR(10)
                                 + N', [Key 2]' + CHAR(10)
                                 + N', [Path]'
                            --WHEN N'USER' THEN N', [User ID]'
                          END + @select + CHAR(10) + N' FROM [dbo].[EASY__'
                        + @@easytable + N']'
        
            END
    
        IF ( LEN(ISNULL(@sql, N'')) > 0 ) 
            BEGIN
                BEGIN TRY
                    --PRINT @sql
                    EXEC sp_executesql @sql
                        
                        --PRINT @sql
                        
                    SET @@errormessage = N''
                END TRY
                BEGIN CATCH
						--PRINT ERROR_MESSAGE()
                    SET @@errormessage = ERROR_MESSAGE()
                END CATCH
            END
                
        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''
    END
GO


IF ( OBJECT_ID('csp_easytopro_createmigrationfields') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_createmigrationfields
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_createmigrationfields]
    (
      @@CONTACT_table NVARCHAR(64) = NULL ,
      @@REFS_table NVARCHAR(64) = NULL ,
      @@PROJECT_table NVARCHAR(64) = NULL ,
      @@ARCHIVE_table NVARCHAR(64) = NULL ,
      @@TODO_table NVARCHAR(64) = NULL ,
      @@USER_table NVARCHAR(64) = NULL ,
      @@HISTORY_table NVARCHAR(64) = NULL ,
      @@TIME_table NVARCHAR(64) = NULL ,
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
        
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
            
        DECLARE @fieldtype INT
        DECLARE @isnullable INT
        DECLARE @limereadonly INT
        DECLARE @invisible INT
        DECLARE @sql NVARCHAR(500)
        SET @isnullable = 1
        SET @limereadonly = 1
        SET @fieldtype = 3
        SET @invisible = 1 --Invisible on forms

        BEGIN TRY
-- CONTACT
            IF ( LEN(ISNULL(@@CONTACT_table, N'')) > 0 ) 
                BEGIN
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@CONTACT_table
                                            AND f.[name] = N'contact_limeeasyid' ) 
                        BEGIN
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@CONTACT_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''contact_limeeasyid'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(@fieldtype AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql
                        END
                END
    
    
 -- REFS        
            IF ( LEN(ISNULL(@@REFS_table, N'')) > 0 ) 
                BEGIN
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@REFS_table
                                            AND f.[name] = N'contact_limeeasyid' ) 
                        BEGIN
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@REFS_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''contact_limeeasyid'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(@fieldtype AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql
                        END
      
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@REFS_table
                                            AND f.[name] = N'refs_limeeasyid' ) 
                        BEGIN
      
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@REFS_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''refs_limeeasyid'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(@fieldtype AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql   
         
                        END
                        
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@REFS_table
                                            AND f.[name] = N'easy_fullname' ) 
                        BEGIN
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@REFS_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''easy_fullname'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(1 AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql
                        END
         
                END
    -- PROJECT
            IF ( LEN(ISNULL(@@PROJECT_table, N'')) > 0 ) 
                BEGIN
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@PROJECT_table
                                            AND f.[name] = N'project_limeeasyid' ) 
                        BEGIN
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@PROJECT_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''project_limeeasyid'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(@fieldtype AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql
                        END
                END
    
    
    -- ARCHIVE        
            IF ( LEN(ISNULL(@@ARCHIVE_table, N'')) > 0 ) 
                BEGIN
    
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@ARCHIVE_table
                                            AND f.[name] = N'archive_limeeasyid' ) 
                        BEGIN
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@ARCHIVE_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''archive_limeeasyid'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(@fieldtype AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql
                        END
    
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@ARCHIVE_table
                                            AND f.[name] = N'contact_limeeasyid' ) 
                        BEGIN
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@ARCHIVE_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''contact_limeeasyid'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(@fieldtype AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql
                        END
      
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@ARCHIVE_table
                                            AND f.[name] = N'project_limeeasyid' ) 
                        BEGIN
      
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@ARCHIVE_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''project_limeeasyid'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(@fieldtype AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql   
         
                        END
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@ARCHIVE_table
                                            AND f.[name] = N'user_limeeasyid' ) 
                        BEGIN
      
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@ARCHIVE_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''user_limeeasyid'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(@fieldtype AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql   
         
                        END
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@ARCHIVE_table
                                            AND f.[name] = N'archive_easytype' ) 
                        BEGIN
      
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@ARCHIVE_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''archive_easytype'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(@fieldtype AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql   
         
                        END
                        
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@ARCHIVE_table
                                            AND f.[name] = N'archive_easykey1' ) 
                        BEGIN
      
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@ARCHIVE_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''archive_easykey1'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(@fieldtype AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql   
         
                        END
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@ARCHIVE_table
                                            AND f.[name] = N'archive_easykey2' ) 
                        BEGIN
      
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@ARCHIVE_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''archive_easykey2'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(@fieldtype AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql   
         
                        END
                        
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@ARCHIVE_table
                                            AND f.[name] = N'archive_limeeasypath' ) 
                        BEGIN
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@ARCHIVE_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''archive_limeeasypath'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(12 AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql
                        END
         
                END

-- TODO        
            IF ( LEN(ISNULL(@@TODO_table, N'')) > 0 ) 
                BEGIN
    
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@TODO_table
                                            AND f.[name] = N'todo_limeeasyid' ) 
                        BEGIN
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@TODO_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''todo_limeeasyid'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(@fieldtype AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql
                        END
    
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@TODO_table
                                            AND f.[name] = N'contact_limeeasyid' ) 
                        BEGIN
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@TODO_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''contact_limeeasyid'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(@fieldtype AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql
                        END
      
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@TODO_table
                                            AND f.[name] = N'project_limeeasyid' ) 
                        BEGIN
      
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@TODO_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''project_limeeasyid'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(@fieldtype AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql   
         
                        END
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@TODO_table
                                            AND f.[name] = N'user_limeeasyid' ) 
                        BEGIN
      
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@TODO_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''user_limeeasyid'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(@fieldtype AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql   
         
                        END
                        
                        
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@TODO_table
                                            AND f.[name] = N'todo_easytype' ) 
                        BEGIN
      
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@TODO_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''todo_easytype'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(@fieldtype AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql   
         
                        END
                        
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@TODO_table
                                            AND f.[name] = N'todo_easykey1' ) 
                        BEGIN
      
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@TODO_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''todo_easykey1'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(@fieldtype AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql   
         
                        END
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@TODO_table
                                            AND f.[name] = N'todo_easykey2' ) 
                        BEGIN
      
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@TODO_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''todo_easykey2'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(@fieldtype AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql   
         
                        END
                        
         
                END
    
    -- USER
            IF ( LEN(ISNULL(@@USER_table, N'')) > 0 ) 
                BEGIN
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@USER_table
                                            AND f.[name] = N'user_limeeasyid' ) 
                        BEGIN
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@USER_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''user_limeeasyid'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(@fieldtype AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql
                        END
                        
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@USER_table
                                            AND f.[name] = N'easy_fullname' ) 
                        BEGIN
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@USER_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''easy_fullname'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(1 AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql
                        END
                        
                END
    
    
    ---- HISTORY        
            --IF ( LEN(ISNULL(@@HISTORY_table, N'')) > 0 ) 
            --    BEGIN
    
                --    IF NOT EXISTS ( SELECT  f.[idfield]
                --                    FROM    [dbo].[fieldcache] f
                --                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                --                    WHERE   t.[name] = @@HISTORY_table
                --                            AND f.[name] = N'time_limeeasyid' ) 
                --        BEGIN
                --            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                --                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                --                    + N'@@table = N''' + @@HISTORY_table
                --                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                --                                              3)
                --                    + N'@@name = N''time_limeeasyid'' , '
                --                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                --                    + N'@@fieldtype = '
                --                    + CAST(@fieldtype AS NVARCHAR(32))
                --                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                --                    + N'@@isnullable  = '
                --                    + CAST(@isnullable AS NVARCHAR(32))
                --                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                --                    + N'@@limereadonly  = '
                --                    + CAST(@limereadonly AS NVARCHAR(32)) 
          
          
                --            EXECUTE sp_executesql @sql
                --        END
    
                --    IF NOT EXISTS ( SELECT  f.[idfield]
                --                    FROM    [dbo].[fieldcache] f
                --                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                --                    WHERE   t.[name] = @@HISTORY_table
                --                            AND f.[name] = N'contact_limeeasyid' ) 
                --        BEGIN
                --            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                --                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                --                    + N'@@table = N''' + @@HISTORY_table
                --                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                --                                              3)
                --                    + N'@@name = N''contact_limeeasyid'' , '
                --                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                --                    + N'@@fieldtype = '
                --                    + CAST(@fieldtype AS NVARCHAR(32))
                --                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                --                    + N'@@isnullable  = '
                --                    + CAST(@isnullable AS NVARCHAR(32))
                --                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                --                    + N'@@limereadonly  = '
                --                    + CAST(@limereadonly AS NVARCHAR(32)) 
          
          
                --            EXECUTE sp_executesql @sql
                --        END
      
                --    IF NOT EXISTS ( SELECT  f.[idfield]
                --                    FROM    [dbo].[fieldcache] f
                --                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                --                    WHERE   t.[name] = @@HISTORY_table
                --                            AND f.[name] = N'project_limeeasyid' ) 
                --        BEGIN
      
                --            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                --                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                --                    + N'@@table = N''' + @@HISTORY_table
                --                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                --                                              3)
                --                    + N'@@name = N''project_limeeasyid'' , '
                --                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                --                    + N'@@fieldtype = '
                --                    + CAST(@fieldtype AS NVARCHAR(32))
                --                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                --                    + N'@@isnullable  = '
                --                    + CAST(@isnullable AS NVARCHAR(32))
                --                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                --                    + N'@@limereadonly  = '
                --                    + CAST(@limereadonly AS NVARCHAR(32)) 
          
          
                --            EXECUTE sp_executesql @sql   
         
                --        END
                        
                --    IF NOT EXISTS ( SELECT  f.[idfield]
                --                    FROM    [dbo].[fieldcache] f
                --                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                --                    WHERE   t.[name] = @@HISTORY_table
                --                            AND f.[name] = N'user_limeeasyid' ) 
                --        BEGIN
      
                --            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                --                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                --                    + N'@@table = N''' + @@HISTORY_table
                --                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                --                                              3)
                --                    + N'@@name = N''user_limeeasyid'' , '
                --                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                --                    + N'@@fieldtype = '
                --                    + CAST(@fieldtype AS NVARCHAR(32))
                --                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                --                    + N'@@isnullable  = '
                --                    + CAST(@isnullable AS NVARCHAR(32))
                --                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                --                    + N'@@limereadonly  = '
                --                    + CAST(@limereadonly AS NVARCHAR(32)) 
          
          
                --            EXECUTE sp_executesql @sql   
         
                --        END
                --    IF NOT EXISTS ( SELECT  f.[idfield]
                --                    FROM    [dbo].[fieldcache] f
                --                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                --                    WHERE   t.[name] = @@HISTORY_table
                --                            AND f.[name] = N'refs_limeeasyid' ) 
                --        BEGIN
      
                --            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                --                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                --                    + N'@@table = N''' + @@HISTORY_table
                --                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                --                                              3)
                --                    + N'@@name = N''refs_limeeasyid'' , '
                --                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                --                    + N'@@fieldtype = '
                --                    + CAST(@fieldtype AS NVARCHAR(32))
                --                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                --                    + N'@@isnullable  = '
                --                    + CAST(@isnullable AS NVARCHAR(32))
                --                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                --                    + N'@@limereadonly  = '
                --                    + CAST(@limereadonly AS NVARCHAR(32)) 
          
          
                --            EXECUTE sp_executesql @sql   
         
                --        END
         
                --END
    
    -- TIME        
            IF ( LEN(ISNULL(@@TIME_table, N'')) > 0 ) 
                BEGIN
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@TIME_table
                                            AND f.[name] = N'contact_limeeasyid' ) 
                        BEGIN
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@TIME_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''contact_limeeasyid'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(@fieldtype AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql
                        END
      
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@TIME_table
                                            AND f.[name] = N'time_limeeasyid' ) 
                        BEGIN
      
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@TIME_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''time_limeeasyid'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(@fieldtype AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql   
         
                        END
                    IF NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@TIME_table
                                            AND f.[name] = N'user_limeeasyid' ) 
                        BEGIN
      
                            SELECT  @sql = N' EXECUTE [dbo].[csp_easytopro_addfield]'
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@table = N''' + @@TIME_table
                                    + N''' , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              3)
                                    + N'@@name = N''user_limeeasyid'' , '
                                    + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@fieldtype = '
                                    + CAST(@fieldtype AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@isnullable  = '
                                    + CAST(@isnullable AS NVARCHAR(32))
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@limereadonly  = '
                                    + CAST(@limereadonly AS NVARCHAR(32)) 
                                    + N' , ' + CHAR(10) + REPLICATE(CHAR(9), 3)
                                    + N'@@invisible  = '
                                    + CAST(@invisible AS NVARCHAR(32)) 
          
          
                            EXECUTE sp_executesql @sql   
         
                        END
         
                END
                
            SET @@errormessage = N''
        END TRY
        BEGIN CATCH
            SET @@errormessage = ERROR_MESSAGE()
        END CATCH
    END
GO


IF ( OBJECT_ID('csp_easytopro_createtransfertables') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_createtransfertables
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_createtransfertables]
    (
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
         
        
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;

        DECLARE @protable NVARCHAR(64)

        SET @@errormessage = N''

        DECLARE table_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
            SELECT DISTINCT
                    [protable]
            FROM    [dbo].[EASY__FIELDMAPPING]
            WHERE   [transfertable] = 1
                    AND LEN(ISNULL([protable], N'')) > 0
		

        OPEN table_cursor
        FETCH NEXT FROM table_cursor INTO @protable       
        WHILE @@FETCH_STATUS = 0
            AND @@errormessage = N'' 
            BEGIN
                    
                BEGIN TRY
                    IF NOT EXISTS ( SELECT  t.[idtable]
                                    FROM    [dbo].[table] t
                                    WHERE   t.[name] = @protable ) 
                        BEGIN
                            EXECUTE [dbo].[csp_easytopro_create_tableifneeded] @@tablename = @protable,
                                @@errormessage = @@errormessage OUTPUT
                        END
                            
                END TRY
                BEGIN CATCH
                    SET @@errormessage = ERROR_MESSAGE()
                END CATCH
                FETCH NEXT FROM table_cursor INTO @protable
            END
				
        CLOSE table_cursor
        DEALLOCATE table_cursor    

        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''
                
    END
GO


IF ( OBJECT_ID('csp_easytopro_create_easy__fieldmapping') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_create_easy__fieldmapping
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_create_easy__fieldmapping]
    (
      @@result INT = 0 OUTPUT ,
      @@errormessage AS NVARCHAR(2048) = N'' OUTPUT
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @xmltext NVARCHAR(MAX)
     
        DECLARE @xml XML
        DECLARE @transaction INT
    

	-- Set initial values
        SET @@result = 0
        SET @transaction = 0
        SET @xmltext = N'
        <tables>
  <table name="CONTACT" protable="company" transfertable="1">
    <field issuperfield="0" easyfieldid="company_name" easyfieldorder="-10" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Company Name" profieldname="name" localname_sv="Företagsnamn" localname_en_us="Company name" localname_no="Navn" localname_fi="Nimi" localname_da="Virksomhedsnavn" proposedvalue="NOVALUEINEASY" active="1"/>
    <field issuperfield="0" easyfieldid="company_suffix" easyfieldorder="-9" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Suffix" profieldname="suffix" localname_sv="Tillägg" localname_en_us="Suffix" localname_no="Suffix" localname_fi="Suffix" localname_da="Suffix" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="company_phone" easyfieldorder="-8" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Telephone" profieldname="phone" localname_sv="Telefon" localname_en_us="Phone" localname_no="Phone" localname_fi="Phone" localname_da="Phone" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="company_fax" easyfieldorder="-7" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Fax" profieldname="telefax" localname_sv="Fax" localname_en_us="Fax" localname_no="Fax" localname_fi="Fax" localname_da="Fax" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="company_address" easyfieldorder="-6" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Address" profieldname="address" localname_sv="Easy Adress" localname_en_us="Easy Adress" localname_no="Easy Adress" localname_fi="Easy Adress" localname_da="Easy Adress" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="company_addresslinesbeforezip1" easyfieldorder="-5" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="addresslinesbeforezip1" profieldname="postaladdress1" localname_sv="Postadress 1" localname_en_us="Postaladdress1" localname_no="Postaladdress1" localname_fi="Postaladdress1" localname_da="Postaladdress1" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="company_addresslinesbeforezip2" easyfieldorder="-4" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="addresslinesbeforezip2" profieldname="postaladdress2" localname_sv="Postadress 2" localname_en_us="Postaladdress2" localname_no="Postaladdress2" localname_fi="Postaladdress2" localname_da="Postaladdress2" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="company_addresslinesbeforezip3" easyfieldorder="-3" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="addresslinesbeforezip3" profieldname="postaladdress3" localname_sv="Postadress 3" localname_en_us="Postaladdress3" localname_no="Postaladdress3" localname_fi="Postaladdress3" localname_da="Postaladdress3" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="company_zipcode" easyfieldorder="-2" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="zipcode" profieldname="postalzipcode" localname_sv="Postnummer" localname_en_us="Zipcode" localname_no="Zipcode" localname_fi="Zipcode" localname_da="Zipcode" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="company_city" easyfieldorder="-2" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="city" profieldname="postalcity" localname_sv="Postort" localname_en_us="City" localname_no="City" localname_fi="City" localname_da="City" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="company_addresslinesafterzip1" easyfieldorder="-1" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="addresslinesafterzip1" profieldname="country" localname_sv="Land" localname_en_us="Country" localname_no="Country" localname_fi="Country" localname_da="Country" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="company_addresslinesafterzip2" easyfieldorder="0" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="addresslinesafterzip2" profieldname="addressline2afterzip" localname_sv="addressline2afterzip" localname_en_us="addressline2afterzip" localname_no="addressline2afterzip" localname_fi="addressline2afterzip" localname_da="addressline2afterzip" proposedvalue="" active="1"/>
  </table>
  <table name="REFS" protable="person" transfertable="1">
    <field issuperfield="0" easyfieldid="person_firstname" easyfieldorder="-9" easyfieldtype="1" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="firstname" profieldname="firstname" localname_sv="Förnamn" localname_en_us="Firstname" localname_no="Firstname" localname_fi="Firstname" localname_da="Firstname" proposedvalue="NOVALUEINEASY" active="1"/>
    <field issuperfield="0" easyfieldid="person_lastname" easyfieldorder="-8" easyfieldtype="1" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="lastname" profieldname="lastname" localname_sv="Efternamn" localname_en_us="Lastname" localname_no="Lastname" localname_fi="Lastname" localname_da="Lastname" proposedvalue="" active="1"/>
    <field relatedeasytable="CONTACT" issuperfield="2" easyfieldid="person_relation_contact" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO CONTACT" easyfieldname="Company" profieldname="company" localname_sv="Företag" localname_en_us="Company" localname_no="Company" localname_fi="Company" localname_da="Company" proposedvalue="" active="1"/>
  </table>
  <table name="PROJECT" protable="business" transfertable="1">
    <field issuperfield="0" easyfieldid="project_name" easyfieldorder="-10" easyfieldtype="2" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Name" profieldname="name" localname_sv="Namn" localname_en_us="Name" localname_no="Navn" localname_fi="Nimi" localname_da="Navn" proposedvalue="NOVALUEINEASY" active="1"/>
    <field issuperfield="0" easyfieldid="project_done" easyfieldorder="-9" easyfieldtype="2" easydatatype="1" easydatatypedata="0" easydatatypetext="YES/NO" easyfieldname="Flags" profieldname="done" localname_sv="Klar" localname_en_us="Done" localname_no="Done" localname_fi="Done" localname_da="Done" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="project_description" easyfieldorder="-8" easyfieldtype="2" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Description" profieldname="description" localname_sv="Beskrivning" localname_en_us="Description" localname_no="Description" localname_fi="Description" localname_da="Description" proposedvalue="" active="1"/>
    <field relatedeasytable="CONTACT" issuperfield="2" easyfieldid="project_relation_contact" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO CONTACT" easyfieldname="Company" profieldname="company" localname_sv="Företag" localname_en_us="Company" localname_no="Company" localname_fi="Company" localname_da="Company" proposedvalue="" active="1"/>
  </table>
  <table name="TIME" protable="" transfertable="0">
    <field issuperfield="0" easyfieldid="time_date" easyfieldorder="-10" easyfieldtype="-3" easydatatype="0" easydatatypedata="16" easydatatypetext="DATE" easyfieldname="Date" profieldname="date" localname_sv="Date" localname_en_us="Date" localname_no="Date" localname_fi="Date" localname_da="Date" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="time_description" easyfieldorder="-9" easyfieldtype="-3" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Description" profieldname="description" localname_sv="Specifikation" localname_en_us="Specification" localname_no="Specification" localname_fi="Specification" localname_da="Specification" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="time_done" easyfieldorder="-8" easyfieldtype="-3" easydatatype="1" easydatatypedata="0" easydatatypetext="YES/NO" easyfieldname="Done" profieldname="done" localname_sv="Klar" localname_en_us="Done" localname_no="Done" localname_fi="Done" localname_da="Done" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="time_type" easyfieldorder="-7" easyfieldtype="-3" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Type" profieldname="type" localname_sv="Typ" localname_en_us="Type" localname_no="Type" localname_fi="Type" localname_da="Type" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="time_tax" easyfieldorder="-6" easyfieldtype="-3" easydatatype="0" easydatatypedata="32" easydatatypetext="INT(FLOAT)" easyfieldname="Tax" profieldname="rate" localname_sv="Taxa" localname_en_us="Tax" localname_no="Tax" localname_fi="Tax" localname_da="Tax" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="time_minutes" easyfieldorder="-5" easyfieldtype="-3" easydatatype="0" easydatatypedata="32" easydatatypetext="INT" easyfieldname="Minutes" profieldname="minutes" localname_sv="Minuter" localname_en_us="Minutes" localname_no="Minutes" localname_fi="Minutes" localname_da="Minutes" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="time_projecttext" easyfieldorder="-4" easyfieldtype="-3" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Project" profieldname="projecttext" localname_sv="Projekt(Text)" localname_en_us="Project(Text)" localname_no="Project(Text)" localname_fi="Project(Text)" localname_da="Project (Text)" proposedvalue="" active="1"/>
    <field relatedeasytable="CONTACT" issuperfield="2" easyfieldid="time_relation_contact" easyfieldorder="-3" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO CONTACT" easyfieldname="Company" profieldname="company" localname_sv="Företag" localname_en_us="Company" localname_no="Company" localname_fi="Company" localname_da="Company" proposedvalue="" active="1"/>
    <field relatedeasytable="USER" issuperfield="2" easyfieldid="time_relation_user" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO COWORKER" easyfieldname="Coworker" profieldname="coworker" localname_sv="Medarbetare" localname_en_us="Coworker" localname_no="Coworker" localname_fi="Coworker" localname_da="Coworker" proposedvalue="" active="1"/>
  </table> 
  <table name="HISTORY" protable="history"  transfertable="1">
    <field issuperfield="0" easyfieldid="history_date" easyfieldorder="-10" easyfieldtype="-2" easydatatype="0" easydatatypedata="16" easydatatypetext="DATE" easyfieldname="Date" profieldname="date" localname_sv="Datum" localname_en_us="Date" localname_no="Date" localname_fi="Date" localname_da="Date" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="history_type" easyfieldorder="-9" easyfieldtype="-2" easydatatype="2" easydatatypedata="3" easydatatypetext="OPTION" easyfieldname="Type" profieldname="type" localname_sv="Aktivitetstyp" localname_en_us="Type" localname_no="Type" localname_fi="Type" localname_da="Type" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="history_note" easyfieldorder="-8" easyfieldtype="-2" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Note" profieldname="note" localname_sv="Anteckningar" localname_en_us="Note" localname_no="Note" localname_fi="Note" localname_da="Note" proposedvalue="NOVALUEINEASY" active="1"/>
    <field relatedeasytable="CONTACT" issuperfield="2" easyfieldid="history_relation_contact" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO CONTACT" easyfieldname="Company" profieldname="company" localname_sv="Företag" localname_en_us="Company" localname_no="Company" localname_fi="Company" localname_da="Company" proposedvalue="" active="1"/>
    <field relatedeasytable="REFS" issuperfield="2" easyfieldid="history_relation_refs" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO REFS" easyfieldname="Person" profieldname="person" localname_sv="Person" localname_en_us="Person" localname_no="Person" localname_fi="Person" localname_da="Person" proposedvalue="" active="1"/>
    <field relatedeasytable="PROJECT" issuperfield="2" easyfieldid="history_relation_project" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO PROJECT" easyfieldname="Project" profieldname="business" localname_sv="Affär" localname_en_us="Business" localname_no="Business" localname_fi="Business" localname_da="Business" proposedvalue="" active="1"/>
    <field relatedeasytable="TIME" issuperfield="2" easyfieldid="history_relation_time" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO TIME" easyfieldname="Time" profieldname="time" localname_sv="Time" localname_en_us="Time" localname_no="Time" localname_fi="Time" localname_da="Time" proposedvalue="" active="1"/>
    <field relatedeasytable="USER" issuperfield="2" easyfieldid="history_relation_user" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO COWORKER" easyfieldname="Coworker" profieldname="coworker" localname_sv="Medarbetare" localname_en_us="Coworker" localname_no="Coworker" localname_fi="Coworker" localname_da="Coworker" proposedvalue="" active="1"/>
  </table>
  <table name="TODO" protable="todo" transfertable="1">
    <field issuperfield="0" easyfieldid="todo_startdate" easyfieldorder="-10" easyfieldtype="-1" easydatatype="0" easydatatypedata="16" easydatatypetext="DATE" easyfieldname="Start date" profieldname="starttime" localname_sv="Start datum" localname_en_us="Start date" localname_no="Start date" localname_fi="Start date" localname_da="Start date" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="todo_enddate" easyfieldorder="-9" easyfieldtype="-1" easydatatype="0" easydatatypedata="16" easydatatypetext="DATE" easyfieldname="Stop date" profieldname="endtime" localname_sv="Slut datum" localname_en_us="End date" localname_no="End date" localname_fi="End date" localname_da="End date" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="todo_subject" easyfieldorder="-8" easyfieldtype="-1" easydatatype="3" easydatatypedata="2" easydatatypetext="TEXT OPTION" easyfieldname="Description" profieldname="subject" localname_sv="Ämne" localname_en_us="Subject" localname_no="Subject" localname_fi="Subject" localname_da="Subject" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="todo_done" easyfieldorder="-7" easyfieldtype="-1" easydatatype="1" easydatatypedata="0" easydatatypetext="YES/NO" easyfieldname="Done" profieldname="done" localname_sv="Klar" localname_en_us="Done" localname_no="Done" localname_fi="Done" localname_da="Done" proposedvalue="" active="1"/>
    <field relatedeasytable="CONTACT" issuperfield="2" easyfieldid="todo_relation_contact" easyfieldorder="-3" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO CONTACT" easyfieldname="Company" profieldname="company" localname_sv="Företag" localname_en_us="Company" localname_no="Company" localname_fi="Company" localname_da="Company" proposedvalue="" active="1"/>
    <field relatedeasytable="REFS" issuperfield="2" easyfieldid="todo_relation_refs" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO REFS" easyfieldname="Person" profieldname="person" localname_sv="Person" localname_en_us="Person" localname_no="Person" localname_fi="Person" localname_da="Person" proposedvalue="" active="1"/>
    <field relatedeasytable="PROJECT" issuperfield="2" easyfieldid="todo_relation_project" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO PROJECT" easyfieldname="Project" profieldname="business" localname_sv="Affär" localname_en_us="Business" localname_no="Business" localname_fi="Business" localname_da="Business" proposedvalue="" active="1"/>
    <field relatedeasytable="USER" issuperfield="2" easyfieldid="todo_relation_user" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO COWORKER" easyfieldname="Coworker" profieldname="coworker" localname_sv="Medarbetare" localname_en_us="Coworker" localname_no="Coworker" localname_fi="Coworker" localname_da="Coworker" proposedvalue="" active="1"/>
  </table>
  <!-- IMPORTANT TO HAVE easyfieldtype 6, 7 (FIELD FROM COMPANY DOCUMENT AND PROJECT DOCUMENT) BECAUSE WE NEED TO HAVE ALL FIELDTYPES LISTED-->
  <table name="ARCHIVE" protable="document" transfertable="1">
    <field issuperfield="0" easyfieldid="archive_date" easyfieldorder="-10" easyfieldtype="6" easydatatype="0" easydatatypedata="16" easydatatypetext="DATE" easyfieldname="Date" profieldname="date" localname_sv="Skapad datum LIME Easy" localname_en_us="Created date LIME Easy" localname_no="Created date LIME Easy" localname_fi="Created date LIME Easy" localname_da="Created date LIME Easy" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="archive_comment" easyfieldorder="-9" easyfieldtype="7" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Comment" profieldname="comment" localname_sv="Kommentar" localname_en_us="Comment" localname_no="Comment" localname_fi="Comment" localname_da="Comment" proposedvalue="NOVALUEINEASY" active="1"/>
    <field relatedeasytable="CONTACT" issuperfield="2" easyfieldid="archive_relation_contact" easyfieldorder="-3" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO CONTACT" easyfieldname="Company" profieldname="company" localname_sv="Företag" localname_en_us="Company" localname_no="Company" localname_fi="Company" localname_da="Company" proposedvalue="" active="1"/>
    <field relatedeasytable="REFS" issuperfield="2" easyfieldid="archive_relation_refs" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO REFS" easyfieldname="Person" profieldname="person" localname_sv="Person" localname_en_us="Person" localname_no="Person" localname_fi="Person" localname_da="Person" proposedvalue="" active="1"/>
    <field relatedeasytable="PROJECT" issuperfield="2" easyfieldid="archive_relation_project" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO PROJECT" easyfieldname="Project" profieldname="business" localname_sv="Affär" localname_en_us="Business" localname_no="Business" localname_fi="Business" localname_da="Business" proposedvalue="" active="1"/>
    <field relatedeasytable="USER" issuperfield="2" easyfieldid="archive_relation_user" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO COWORKER" easyfieldname="Coworker" profieldname="coworker" localname_sv="Medarbetare" localname_en_us="Coworker" localname_no="Coworker" localname_fi="Coworker" localname_da="Coworker" proposedvalue="" active="1"/>
  </table>
  <table name="USER" protable="coworker" transfertable="1">
    <field issuperfield="0" easyfieldid="user_firstname" easyfieldorder="-10" easyfieldtype="-4" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="firstname" profieldname="firstname" localname_sv="Förnamn" localname_en_us="First name" localname_no="Fornavn" localname_fi="Etunimi" localname_da="Navn" proposedvalue="NOVALUEINEASY" active="1"/>
    <field issuperfield="0" easyfieldid="user_lastname" easyfieldorder="-9" easyfieldtype="-4" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="lastname" profieldname="lastname" localname_sv="Efternamn" localname_en_us="Last name" localname_no="Etternavn" localname_fi="Sukunimi" localname_da="Efternavn" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="user_signature" easyfieldorder="-8" easyfieldtype="-4" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Signature" profieldname="easysignature" localname_sv="Easy signature" localname_en_us="Easy signature" localname_no="Easy signature" localname_fi="Easy signature" localname_da="Easy signature" proposedvalue="" active="1"/>
  </table>
</tables>
        '
        

        IF NOT EXISTS ( SELECT  *
                        FROM    sys.objects
                        WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__FIELDMAPPING]')
                                AND type IN ( N'U' ) ) 
            BEGIN
            
            -- Begin transaction
                IF @@TRANCOUNT = 0 
                    BEGIN
                        BEGIN TRANSACTION tran_create_easy__fieldmapping
                        SELECT  @transaction = 1
                    END
            
                BEGIN TRY
                    SET @xml = CAST(@xmltext AS XML)
					 
                    CREATE TABLE [dbo].[EASY__FIELDMAPPING]
                        (
                          [idfieldmapping] INT IDENTITY(1, 1)
                                               PRIMARY KEY ,
                          [easytable] NVARCHAR(64) ,
                          [relatedeasytable] NVARCHAR(64) ,
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
                    
                    
                    
                    INSERT  INTO [dbo].[EASY__FIELDMAPPING]
                            ( [easytable] ,
                              [relatedeasytable] ,
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
                            SELECT  t.[table].value('@name', 'NVARCHAR(64)') AS [easytable] ,
                                    f.[field].value('@relatedeasytable',
                                                    'NVARCHAR(64)') AS [relatedeasytable] ,
                                    f.[field].value('@easyfieldname',
                                                    'NVARCHAR(64)') AS [easyfieldname] ,
                                    f.[field].value('@issuperfield', 'INT') AS [issuperfield] ,
                                    f.[field].value('@easyfieldid',
                                                    'NVARCHAR(64)') AS [easyfieldid] ,
                                    f.[field].value('@easyfieldorder', 'INT') AS [easyfieldorder] ,
                                    f.[field].value('@easyfieldtype', 'INT') AS [easyfieldtype] ,
                                    f.[field].value('@easydatatype', 'INT') AS [easydatatype] ,
                                    f.[field].value('@easydatatypedata', 'INT') AS [easydatatypedata] ,
                                    CASE WHEN f.[field].value('@easydatatype',
                                                              'INT') = -999
                                         THEN f.[field].value('@easydatatypetext',
                                                              'NVARCHAR(64)') -- GET VALUE FROM XML-FILE
                                         ELSE [dbo].[cfn_easytopro_geteasydatatypetext](f.[field].value('@easydatatype',
                                                              'INT'),
                                                              f.[field].value('@easydatatypedata',
                                                              'INT'))
                                    END AS [easydatatypetext] ,
                                    t.[table].value('@protable',
                                                    'NVARCHAR(64)') AS [protable] ,
                                    t.[table].value('@transfertable',
                                                    'NVARCHAR(64)') AS [transfertable] ,
                                    f.[field].value('@profieldname',
                                                    'NVARCHAR(64)') AS [profieldname] ,
                                    f.[field].value('@localname_sv',
                                                    'NVARCHAR(64)') AS [localname_sv] ,
                                    f.[field].value('@localname_en_us',
                                                    'NVARCHAR(64)') AS [localname_en_us] ,
                                    f.[field].value('@localname_no',
                                                    'NVARCHAR(64)') AS [localname_no] ,
                                    f.[field].value('@localname_fi',
                                                    'NVARCHAR(64)') AS [localname_fi] ,
									f.[field].value('@localname_da',
                                                    'NVARCHAR(64)') AS [localname_da] ,
                                    f.[field].value('@active', 'INT') AS [active] ,
                                    CASE WHEN f.[field].value('@easydatatype',
                                                              'INT') = -999
                                         THEN 16 -- RELATION FIELD
                                         ELSE [dbo].[cfn_easytopro_geteasyprofieldtype](f.[field].value('@easydatatype',
                                                              'INT'),
                                                              f.[field].value('@easydatatypedata',
                                                              'INT'))
                                    END AS [easyprofieldtype] ,
                                    f.[field].value('@proposedvalue',
                                                    'NVARCHAR(64)') AS [proposedvalue]
                            FROM    @xml.nodes('tables/table') AS t ( [table] )
                                    CROSS APPLY [table].nodes('field') AS f ( field )
                            WHERE   f.[field].value('@issuperfield', 'INT') IN (
                                    0, 2 )
                        
                    SET @@errormessage = N''
                    SET @@result = 0
                END TRY
                BEGIN CATCH
                    SET @@errormessage = ERROR_MESSAGE()
                    SET @@result = 1
                END CATCH
                
                IF @@result <> 0 
                    BEGIN
                        IF @transaction = 1 
                            ROLLBACK TRANSACTION tran_create_easy__fieldmapping
                    END

	-- Commit transaction
                IF ( @transaction = 1
                     AND @@result = 0
                   ) 
                    BEGIN
                        COMMIT TRANSACTION tran_create_easy__fieldmapping
                    END
            END
        ELSE 
            BEGIN
                SET @@errormessage = N''
                SET @@result = 0
            END

        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''

    END
GO


IF ( OBJECT_ID('csp_easytopro_create_easy__optionmapping') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_create_easy__optionmapping
	END
GO


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
GO


IF ( OBJECT_ID('csp_easytopro_create_tableifneeded') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_create_tableifneeded
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_create_tableifneeded]
    (
      @@tablename NVARCHAR(64) ,
      @@sv NVARCHAR(64) = NULL ,
      @@en_us NVARCHAR(64) = NULL ,
      @@no NVARCHAR(64) = NULL ,
      @@fi NVARCHAR(64) = NULL ,
      @@da NVARCHAR(64) = NULL,
      @@errormessage AS NVARCHAR(2048) = N'' OUTPUT
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @localname INT
        DECLARE @idtable INT 
        DECLARE @retval INT
        DECLARE @transaction INT
    

	-- Set initial values
        SET @retval = 0
        SET @transaction = 0
        SET @@errormessage = N''
        SET @idtable = NULL
        SET @localname = NULL
		
        IF NOT EXISTS ( SELECT  [idtable]
                        FROM    [dbo].[table]
                        WHERE   [name] = @@tablename ) 
            BEGIN
			
			-- Begin transaction
                IF @@TRANCOUNT = 0 
                    BEGIN
                        BEGIN TRANSACTION tran_createtable
                        SELECT  @transaction = 1
                    END
                
                BEGIN TRY
                    
                    IF @retval = 0 
                        EXECUTE @retval = [dbo].[lsp_addtable] @@name = @@tablename,
                            @@idtable = @idtable OUTPUT,
                            @@localname = @localname OUTPUT
	           
	           
                    IF ( LEN(ISNULL(@@sv, N'')) > 0 ) 
                        BEGIN
                            IF @retval = 0 
                                EXECUTE @retval = [dbo].[lsp_setstringattributevalue] @@idstring = @localname,
                                    @@name = N'sv', @@value = @@sv
                        END
					
                    IF ( LEN(ISNULL(@@en_us, N'')) > 0 ) 
                        BEGIN
                            IF @retval = 0 
                                EXECUTE @retval = [dbo].[lsp_setstringattributevalue] @@idstring = @localname,
                                    @@name = N'en_us', @@value = @@en_us
                        END
					
                    IF ( LEN(ISNULL(@@no, N'')) > 0 ) 
                        BEGIN
                            IF @retval = 0 
                                EXECUTE @retval = [dbo].[lsp_setstringattributevalue] @@idstring = @localname,
                                    @@name = N'no', @@value = @@no
                        END
					
                    IF ( LEN(ISNULL(@@fi, N'')) > 0 ) 
                        BEGIN	
                            IF @retval = 0 
                                EXECUTE @retval = [dbo].[lsp_setstringattributevalue] @@idstring = @localname,
                                    @@name = N'fi', @@value = @@fi
                        END
					
                    IF ( LEN(ISNULL(@@da, N'')) > 0 ) 
                        BEGIN	
                            IF @retval = 0 
                                EXECUTE @retval = [dbo].[lsp_setstringattributevalue] @@idstring = @localname,
                                    @@name = N'da', @@value = @@da
                        END
                        
                END TRY
                BEGIN CATCH
                    SET @@errormessage = ERROR_MESSAGE()
                    SET @retval = -1
                END CATCH	
           
           
                IF @retval <> 0 
                    BEGIN
                        IF @transaction = 1 
                            ROLLBACK TRANSACTION tran_createtable
                        RETURN @retval
                    END

	-- Commit transaction
                IF @transaction = 1 
                    COMMIT TRANSACTION tran_createtable

                RETURN @retval
           
           
            END
        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''
    END
GO


IF ( OBJECT_ID('csp_easytopro_data') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_data
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_data]
    @@xml AS NVARCHAR(MAX) ,
    @@rebuildtable AS BIT
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @iXML INT


        IF ( @@rebuildtable = 1 ) 
            BEGIN


       
                IF EXISTS ( SELECT  *
                            FROM    sys.objects
                            WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__DATA]')
                                    AND type IN ( N'U' ) ) 
                    DROP TABLE [dbo].[EASY__DATA] 


                CREATE TABLE [dbo].[EASY__DATA]
                    (
                      [Field ID] SMALLINT NOT NULL ,
                      [Key 1] INT NOT NULL ,
                      [Key 2] INT NOT NULL ,
                      [Key 3] INT NOT NULL ,
                      [Data] NVARCHAR(255)
                    )
            END

        EXEC sp_xml_preparedocument @iXML OUTPUT, @@xml

        INSERT  INTO [dbo].[EASY__DATA]
                ( [Field ID] ,
                  [Key 1] ,
                  [Key 2] ,
                  [Key 3] ,
                  [Data]
                )
                SELECT  [fieldid] ,
                        [key1] ,
                        [key2] ,
                        [key3] ,
                        [data]
                FROM    OPENXML(@iXML, '/data/row')
	WITH (	
	[fieldid] SMALLINT,
                  [key1] INT ,
                  [key2] INT,
                  [key3] INT,
                  [data]NVARCHAR(255)
		) 
	

        EXECUTE sp_xml_removedocument @iXML
    END
GO


IF ( OBJECT_ID('csp_easytopro_endmigration') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_endmigration
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_endmigration]
    (
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
         
        
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;

        DECLARE @protable NVARCHAR(64)
        DECLARE @easytable NVARCHAR(64)
        DECLARE @sql NVARCHAR(MAX)

		

        SET @@errormessage = N''
        SET @sql = N''

        DECLARE table_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
            SELECT DISTINCT
                    [protable] ,
                    [easytable]
            FROM    [dbo].[EASY__FIELDMAPPING]
            WHERE   [transfertable] = 1
                    AND LEN(ISNULL([protable], N'')) > 0
		

        OPEN table_cursor
        FETCH NEXT FROM table_cursor INTO @protable, @easytable      
        WHILE @@FETCH_STATUS = 0
            AND @@errormessage = N'' 
            BEGIN

                IF EXISTS ( SELECT  t.[idtable]
                            FROM    [dbo].[table] t
                            WHERE   t.[name] = @protable ) 
                    BEGIN
						-- ADDING RESULTSET IN @table TO PREVENT RESULTSET,  SINCE PROCEDURE IN LIME NEEDS RESULT IN XML-FORMAT
                        SELECT  @sql = @sql
                                + N'INSERT INTO @table EXEC  [dbo].[lsp_formatdb]'
                                + CHAR(10) + REPLICATE(CHAR(9), 4)
                                + N'@@table = ' + @protable + N',' + CHAR(10)
                                + REPLICATE(CHAR(9), 4) + N'@@commit = 1'
                                + CHAR(10)
                    END

                FETCH NEXT FROM table_cursor INTO @protable, @easytable
            END
				
        CLOSE table_cursor
        DEALLOCATE table_cursor    
		
        SELECT  @sql = @sql + CHAR(10) + N'EXEC [dbo].[lsp_refreshldc]' 
        IF ( LEN(ISNULL(@sql, N'')) > 0 ) 
            BEGIN
                BEGIN TRY
				-- ADDING RESULTSET IN @table TO PREVENT RESULTSET,  SINCE PROCEDURE IN LIME NEEDS RESULT IN XML-FORMAT
                    SET @sql = N'declare @table table (	[table] NVARCHAR(64), 
														idrecord INT, 
														fieldtype NVARCHAR(64),
														[expecte] NVARCHAR(MAX) ,
														expected__formatted NVARCHAR(MAX))'
                        + CHAR(10) + @sql
				
				--PRINT @sql
                    EXEC sp_executesql @sql

                    SET @@errormessage = N''
                END TRY
                BEGIN CATCH
					--PRINT ERROR_MESSAGE()
                    SET @@errormessage = ERROR_MESSAGE()
                END CATCH
            END
        
		
		
        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''
         
    END
GO


IF ( OBJECT_ID('csp_easytopro_field') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_field
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_field]
    @@xml AS NVARCHAR(MAX) ,
    @@rebuildtable AS BIT
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @iXML INT


        IF ( @@rebuildtable = 1 ) 
            BEGIN
       
                IF EXISTS ( SELECT  *
                            FROM    sys.objects
                            WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__FIELD]')
                                    AND type IN ( N'U' ) ) 
                    DROP TABLE [dbo].[EASY__FIELD] 

                CREATE TABLE [dbo].[EASY__FIELD]
                    (
                      [Field ID] SMALLINT NOT NULL ,
                      [Field name] NVARCHAR(48) ,
                      [Field type] SMALLINT ,
                      [Order] SMALLINT ,
                      [Symbol] SMALLINT ,
                      [Field width] SMALLINT ,
                      [Data type] SMALLINT ,
                      [Data type data] INT
                    )
            END

        EXEC sp_xml_preparedocument @iXML OUTPUT, @@xml

        INSERT  INTO [dbo].[EASY__FIELD]
                ( [Field ID] ,
                  [Field name] ,
                  [Field type] ,
                  [Order] ,
                  [Symbol] ,
                  [Field width] ,
                  [Data type] ,
                  [Data type data]
                )
                SELECT  [fieldid] ,
                        [fieldname] ,
                        [fieldtype] ,
                        [order] ,
                        [symbol] ,
                        [fieldwidth] ,
                        [datatype] ,
                        [datatypedata]
                FROM    OPENXML(@iXML, '/data/row')
	WITH (	
	[fieldid] SMALLINT,
                  [fieldname] NVARCHAR(48) ,
                  [fieldtype] SMALLINT,
                  [order] SMALLINT ,
                  [symbol] SMALLINT,
                  [fieldwidth]SMALLINT,
                  [datatype] SMALLINT,
                  [datatypedata] INT
		) 
	

        EXECUTE sp_xml_removedocument @iXML
    END
GO


IF ( OBJECT_ID('csp_easytopro_fieldexist') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_fieldexist
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_fieldexist]
    (
      @@tablename AS NVARCHAR(64) ,
      @@fieldname AS NVARCHAR(64) ,
      @@exists AS INT = 0 OUTPUT ,
      @@required AS INT = 0 OUTPUT
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        
        SELECT  @@exists = CASE WHEN EXISTS ( SELECT    f.[idfield]
                                              FROM      [dbo].[fieldcache] f
                                                        INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                              WHERE     f.[name] = @@fieldname
                                                        AND t.[name] = @@tablename )
                                THEN 1
                                ELSE 0
                           END ,
                @@required = CASE WHEN EXISTS ( SELECT  a.[idattributedata]
                                                FROM    [dbo].[attributedata] a
                                                        INNER JOIN [dbo].[fieldcache] f ON f.[idfield] = a.[idrecord]
                                                              AND f.[name] = @@fieldname
                                                        INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                              AND t.[name] = @@tablename
                                                WHERE   a.[owner] = N'field'
                                                        AND a.[name] = 'required' )
                                  THEN 1
                                  ELSE 0
                             END
                           
                           
            

    END
GO


IF ( OBJECT_ID('csp_easytopro_fixtimestamps') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_fixtimestamps
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_fixtimestamps]
    (
      @@easytable NVARCHAR(64) ,
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
         
        
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
            --DECLARATIONS

        DECLARE @sql NVARCHAR(MAX)
        DECLARE @protable NVARCHAR(64) 
        SELECT  @sql = N''


		
		
        DECLARE row_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
            SELECT DISTINCT
                    e.[protable]
            FROM    [dbo].[EASY__FIELDMAPPING] e
            WHERE   e.[easytable] = @@easytable
                    AND LEN(e.[protable]) > 0
                    AND e.[transfertable] = 1
                    
        OPEN row_cursor
        FETCH NEXT FROM row_cursor INTO @protable
        WHILE @@FETCH_STATUS = 0 
            BEGIN
    
                IF ( @@easytable = N'ARCHIVE' ) 
                    BEGIN			
                        SELECT  @sql = @sql
                                + N', [createdtime] = DATEADD(s,e.[Time],e.[Date]), [createduser] = cw.[username]'
                                + CHAR(10)
                    END
                ELSE 
                    IF ( @@easytable = N'REFS' ) 
                        BEGIN
                            SELECT  @sql = @sql
                                    + N', [createdtime] = DATEADD(s,e.[Created time],e.[Created date]), [timestamp] = CASE WHEN ISDATE(DATEADD(s,e.[Updated time],e.[Updated date])) = 1 THEN DATEADD(s,e.[Updated time],e.[Updated date]) ELSE DATEADD(s,e.[Created time],e.[Created date]) END, [createduser] = cw.[username], [updateduser] = cw2.[username]'          
                                    + CHAR(10)
                        END
                    ELSE 
                        IF ( @@easytable = N'CONTACT' ) 
                            BEGIN			
                                SELECT  @sql = @sql
                                        + N', [createdtime] = DATEADD(s,e.[Created time],e.[Created date]), [timestamp] = CASE WHEN ISDATE(DATEADD(s,e.[Updated time],e.[Updated date])) = 1 THEN DATEADD(s,e.[Updated time],e.[Updated date]) ELSE DATEADD(s,e.[Created time],e.[Created date]) END, [createduser] = cw.[username], [updateduser] = cw2.[username]'          
                                        + CHAR(10)
                            END
                        ELSE 
                            IF ( @@easytable = N'PROJECT' ) 
                                BEGIN
                                    SELECT  @sql = @sql
                                            + N', [createdtime] = DATEADD(s,e.[Created time],e.[Created date]), [timestamp] = CASE WHEN ISDATE(DATEADD(s,e.[Updated time],e.[Updated date])) = 1 THEN DATEADD(s,e.[Updated time],e.[Updated date]) ELSE DATEADD(s,e.[Created time],e.[Created date]) END, [createduser] = cw.[username], [updateduser] = cw2.[username]'                                                        
                                            + CHAR(10)
                                END
                        
		
                FETCH NEXT FROM row_cursor INTO @protable
            END
				
        CLOSE row_cursor
        DEALLOCATE row_cursor    

        IF ( LEN(@sql) > 0 ) 
            BEGIN
                SELECT  @sql = N'UPDATE pro SET ' + RIGHT(@sql, LEN(@sql) - 1)
                        + N'FROM [dbo].' + QUOTENAME(@protable) + N' AS pro '
                        + CHAR(10)
                        + CASE @@easytable
                            WHEN N'ARCHIVE'
                            THEN N'INNER JOIN [dbo].[EASY__ARCHIVE] e ON pro.[archive_easytype] = e.[Type] AND pro.[archive_easykey1] = e.[Key 1] AND pro.[archive_easykey2]=e.[Key 2] '
								 + CHAR(10) + N'LEFT JOIN [dbo].[coworker] cw ON cw.[user_limeeasyid] = e.[User ID]'
                                 + CHAR(10) + N'WHERE pro.[status] = 0'
                                 + CHAR(10) + N'AND pro.[archive_easykey1] IS NOT NULL'
                                 + CHAR(10) + N'AND pro.[archive_easykey2] IS NOT NULL'
                                 + CHAR(10) + N'AND pro.[archive_easytype] IS NOT NULL'
                                 + CHAR(10) + N'AND ISDATE(DATEADD(s,e.[Time],e.[Date])) = 1'
                            WHEN N'REFS'
                            THEN N'INNER JOIN [dbo].[EASY__REFS] e ON pro.[contact_limeeasyid] = e.[Company ID] AND pro.[refs_limeeasyid] = e.[Reference ID] '
								 + CHAR(10) + N'LEFT JOIN [dbo].[coworker] cw ON cw.[user_limeeasyid] = e.[Created user ID]'
								 + CHAR(10) + N'LEFT JOIN [dbo].[coworker] cw2 ON cw2.[user_limeeasyid] = e.[Updated user ID]'
                                 + CHAR(10) + N'WHERE pro.[status] = 0'
                                 + CHAR(10) + N'AND pro.[contact_limeeasyid] IS NOT NULL '
                                 + CHAR(10) + N'AND pro.[refs_limeeasyid] IS NOT NULL'
                                 + CHAR(10) + N'AND ISDATE(DATEADD(s,e.[Created time],e.[Created date])) = 1'
                            WHEN N'CONTACT'
                            THEN N'INNER JOIN [dbo].[EASY__CONTACT] e ON e.[Company ID] = pro.[contact_limeeasyid] '
								 + CHAR(10) + N'LEFT JOIN [dbo].[coworker] cw ON cw.[user_limeeasyid] = e.[Created user ID]'
								 + CHAR(10) + N'LEFT JOIN [dbo].[coworker] cw2 ON cw2.[user_limeeasyid] = e.[Updated user ID]'
                                 + CHAR(10) + N'WHERE pro.[status] = 0'
								+ CHAR(10) + N'AND pro.[contact_limeeasyid] IS NOT NULL '
								+ CHAR(10) + N'AND ISDATE(DATEADD(s,e.[Created time],e.[Created date])) = 1'
                            WHEN N'PROJECT'
                            THEN N'INNER JOIN [dbo].[EASY__PROJECT] e ON e.[Project ID] = pro.[project_limeeasyid] '
								 + CHAR(10) + N'LEFT JOIN [dbo].[coworker] cw ON cw.[user_limeeasyid] = e.[Created user ID]'
								 + CHAR(10) + N'LEFT JOIN [dbo].[coworker] cw2 ON cw2.[user_limeeasyid] = e.[Updated user ID]'
                                 + CHAR(10) + N'WHERE pro.[status] = 0'
                                 + CHAR(10) + N'AND pro.[project_limeeasyid] IS NOT NULL '
								+ CHAR(10) + N'AND ISDATE(DATEADD(s,e.[Created time],e.[Created date])) = 1'
                            ELSE N''
                          END
                    
                BEGIN TRY
                    EXEC sp_executesql @sql
                    --PRINT @sql
                        
                    SET @@errormessage = N''
                END TRY
                BEGIN CATCH
						--PRINT ERROR_MESSAGE()
                    SET @@errormessage = ERROR_MESSAGE()
                END CATCH
                    
            END
        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''
    END
GO


IF ( OBJECT_ID('csp_easytopro_getdocumentxml') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_getdocumentxml
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_getdocumentxml]
    (
      @@limedocumenttable AS NVARCHAR(64)
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
		
        DECLARE @sql NVARCHAR(MAX)
        SELECT  @sql = N'SELECT  [doc].[Type] AS [type] ,
                [doc].[Key 1] AS [key1] ,
                [doc].[Key 2] AS [key2] ,
                ISNULL([doc].[Path], N'''') AS [path] ,
                ISNULL(l.[id' + @@limedocumenttable + N'], 0) AS [idrecord]
        FROM    [dbo].[EASY__ARCHIVE] [doc]
        LEFT JOIN [dbo].' + QUOTENAME(@@limedocumenttable)
                + N' l ON [doc].[Type] = l.[archive_easytype] AND [doc].[Key 1] = l.[archive_easykey1] AND [doc].[Key 2] = l.[archive_easykey2] AND l.[status]=0
        FOR     XML AUTO'
    
        EXEC sp_executesql @sql
    
    END 
GO


IF ( OBJECT_ID('csp_easytopro_getfieldmappingxml') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_getfieldmappingxml
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_getfieldmappingxml]
    (
      @@easytable NVARCHAR(64) = NULL
    )
AS 
    BEGIN
		-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
	-- Declarations
        IF EXISTS ( SELECT  *
                    FROM    sys.objects
                    WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__FIELDMAPPING]')
                            AND type IN ( N'U' ) ) 
            BEGIN
				IF @@easytable IS NULL
				-- Return complete fieldmapping
				BEGIN
					SELECT  *
					FROM    [dbo].[EASY__FIELDMAPPING] [fieldmapping]
					FOR     XML AUTO
				END
				ELSE
				-- Only return fieldmapping for current table
                SELECT  [idfieldmapping] ,
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
                        CASE WHEN EXISTS ( SELECT   *
                                           FROM     [dbo].[fieldcache] f
                                                    INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                           WHERE    f.[name] = [profieldname]
                                                    AND t.[name] = [protable]
                                                    AND LEN([profieldname]) > 0 )
                             THEN 1
                             ELSE 0
                        END AS [existingfield] ,
                        [easyprofieldtype] ,
                        [proposedvalue]
                FROM    [dbo].[EASY__FIELDMAPPING] [fieldmapping]
                WHERE   [easytable] = @@easytable
                FOR     XML AUTO
        
            END
    END
GO


IF ( OBJECT_ID('csp_easytopro_gethistoryxml') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_gethistoryxml
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_gethistoryxml]
	(
		@@maxnotelength INT = NULL
	)
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @xml NVARCHAR(MAX)
        DECLARE @remaining INT
		

        SELECT  @remaining = ( SELECT   COUNT([id])
                               FROM     [dbo].[EASY__HISTORY]
                               WHERE    [splitted] = 0
                                        AND ( ( LEN(ISNULL([History], N'')) <= ISNULL(@@maxnotelength,
                                                              0) )
                                              OR ( @@maxnotelength IS NULL )
                                            )
                             ) 

        SELECT  @xml = N'<info remaining="'
                + ISNULL(CAST(@remaining AS NVARCHAR(32)), N'') + N'" />'

        SELECT  CAST(@xml AS XML)
    
    END 
GO


IF ( OBJECT_ID('csp_easytopro_getoptionmappingxml') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_getoptionmappingxml
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_getoptionmappingxml] ( @@fieldmapping INT = NULL )
AS 
    BEGIN
		-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
	-- Declarations
		IF @@fieldmapping IS NULL
		-- Return full optionmapping
		BEGIN
			SELECT  *
			FROM    [dbo].[EASY__OPTIONMAPPING]
			FOR     XML AUTO
		END
		ELSE
		-- Only return current optionmapping
			SELECT  eo.[idoptionmapping] ,
					eo.[fieldmapping] ,
					eo.[easyvalue] ,
					eo.[idcategorylimepro] ,
					eo.[idstringlimepro] ,
					ISNULL(ef.[protable], N'') AS [protable] ,
					ISNULL(ef.[profieldname], N'') AS [profieldname]
			FROM    [dbo].[EASY__OPTIONMAPPING] AS eo
					INNER JOIN [dbo].[EASY__FIELDMAPPING] AS ef ON eo.[fieldmapping] = ef.[idfieldmapping]
			WHERE   [fieldmapping] = @@fieldmapping
			FOR     XML AUTO
        
        
    END 
GO


IF ( OBJECT_ID('csp_easytopro_history') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_history
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_history]
    @@xml AS NVARCHAR(MAX) ,
    @@rebuildtable AS BIT
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @iXML INT


        IF ( @@rebuildtable = 1 ) 
            BEGIN

                IF EXISTS ( SELECT  *
                            FROM    sys.objects
                            WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__HISTORY]')
                                    AND type IN ( N'U' ) ) 
                    DROP TABLE [dbo].[EASY__HISTORY] 

                CREATE TABLE [dbo].[EASY__HISTORY]
                    (
                      [id] INT IDENTITY(1, 1)
                               PRIMARY KEY ,
                      [Type] SMALLINT NOT NULL ,
                      [Key 1] INT NOT NULL ,
                      [Key 2] INT NOT NULL ,
                      [History] NVARCHAR(MAX) ,
                      [splitted] INT
                    )
            END
        EXEC sp_xml_preparedocument @iXML OUTPUT, @@xml

        INSERT  INTO [dbo].[EASY__HISTORY]
                ( [Type] ,
                  [Key 1] ,
                  [Key 2] ,
                  [History] ,
                  [splitted] 
                )
                SELECT  [type] ,
                        [key1] ,
                        [key2] ,
                        [history] ,
                        0
                FROM    OPENXML(@iXML, '/data/row')
	WITH (	
	[type] SMALLINT ,
                        [key1] INT ,
                        [key2] INT ,
                        [history] NVARCHAR(MAX) 
		) 
	

        EXECUTE sp_xml_removedocument @iXML
    END
GO


IF ( OBJECT_ID('csp_easytopro_include') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_include
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_include]
    @@xml AS NVARCHAR(MAX) ,
    @@rebuildtable AS BIT
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @iXML INT


        IF ( @@rebuildtable = 1 ) 
            BEGIN

                IF EXISTS ( SELECT  *
                            FROM    sys.objects
                            WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__INCLUDE]')
                                    AND type IN ( N'U' ) ) 
                    DROP TABLE [dbo].[EASY__INCLUDE] 

                CREATE TABLE [dbo].[EASY__INCLUDE]
                    (
                      [Project ID] INT NOT NULL ,
                      [Company ID] INT NOT NULL
                    )
            END

        EXEC sp_xml_preparedocument @iXML OUTPUT, @@xml

        INSERT  INTO [dbo].[EASY__INCLUDE]
                ( [Project ID] ,
                  [Company ID] 
                )
                SELECT  [projectid] ,
                        [companyid]
                FROM    OPENXML(@iXML, '/data/row')
	WITH (	
			[projectid] INT ,
			[companyid] INT
		  ) 
	

        EXECUTE sp_xml_removedocument @iXML
    END
GO


IF ( OBJECT_ID('csp_easytopro_inserteasyhistory') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_inserteasyhistory
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_inserteasyhistory]
    (
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
         
        
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @easytable NVARCHAR(64)
        DECLARE @sql NVARCHAR(MAX)
        DECLARE @fieldtype INT
        DECLARE @insert NVARCHAR(MAX)
        DECLARE @select NVARCHAR(MAX)
        DECLARE @protable NVARCHAR(64) 
        DECLARE @profield NVARCHAR(64) 
        DECLARE @relatedprotable NVARCHAR(64)
        DECLARE @relatedeasytable NVARCHAR(64)
        DECLARE @selectstatement NVARCHAR(2048)
        DECLARE @issuperfield INT
        DECLARE @proposedvalue NVARCHAR(128) 
        DECLARE @easyfieldname NVARCHAR(64)
        DECLARE @easyfieldid NVARCHAR(64)
        DECLARE @defaultvalue NVARCHAR(128) 
        DECLARE @isrequired NVARCHAR(1)

-- SET INITIAL VALUES
        SELECT  @easytable = N'HISTORY' 
        SELECT  @sql = N''
        SELECT  @select = N''
        SELECT  @insert = N''
            


        DECLARE row_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
            SELECT DISTINCT
                    e.[protable] ,
                    e2.[protable] ,
                    e.[easyfieldid] ,
                    e.[easyfieldname] ,
                    e.[relatedeasytable] ,
                    e.[profieldname] ,
                    CASE WHEN e.[relatedeasytable] = N'REFS'
                    THEN 
                     N'(SELECT TOP 1 [id' + e2.[protable] + N'] '
                    + N'FROM [dbo].' + QUOTENAME(e2.[protable]) + N' WHERE ['
                    + LOWER(e.[relatedeasytable]) + N'_limeeasyid] = h.['
                    + LOWER(e.[relatedeasytable])
                    + '_limeeasyid] ' 
                    + N' AND [contact_limeeasyid] = h.[contact_limeeasyid]'
                    + N' AND [status] = 0)'
                    ELSE
                    N'(SELECT TOP 1 [id' + e2.[protable] + N'] '
                    + N'FROM [dbo].' + QUOTENAME(e2.[protable]) + N' WHERE ['
                    + LOWER(e.[relatedeasytable]) + N'_limeeasyid] = h.['
                    + LOWER(e.[relatedeasytable])
                    + '_limeeasyid] AND [status] = 0)' END ,
                    e.[issuperfield] ,
                    CASE WHEN LEN(ISNULL(e.proposedvalue, N'')) > 0
                         THEN REPLACE(e.[proposedvalue], N'''', N'''''')
                         ELSE ( SELECT  CASE WHEN [isnullable] = 1
                                                  AND [defaultvalue] = N''
                                             THEN CAST(N'NULL' AS NVARCHAR(128))
                                             ELSE CAST([defaultvalue] AS NVARCHAR(128))
                                        END
                                FROM    [dbo].[fieldcache] f
                                        INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                              AND t.[name] = e.protable
                                WHERE   f.[name] = e.[profieldname]
                              )
                    END ,
                    CASE WHEN EXISTS ( SELECT   f.[idfield]
                                       FROM     [dbo].[fieldcache] f
                                                INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                INNER JOIN [dbo].[attributedata] a ON a.[idrecord] = f.[idfield]
                                                              AND a.[owner] = N'field'
                                                              AND a.[name] = N'required'
                                       WHERE    e.[profieldname] = f.[name]
                                                AND e.[protable] = t.[name] )
                         THEN 1
                         ELSE 0
                    END ,
                    ( SELECT TOP 1
                                CASE WHEN [isnullable] = 1
                                          AND [defaultvalue] = N''
                                     THEN CAST(N'NULL' AS NVARCHAR(128))
                                     ELSE CAST([defaultvalue] AS NVARCHAR(128))
                                END
                      FROM      [dbo].[fieldcache] f
                                INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                      WHERE     e.[profieldname] = f.[name]
                                AND e.[protable] = t.[name]
                    ) ,
                    e.[easyprofieldtype]
            FROM    [dbo].[EASY__FIELDMAPPING] e
                    LEFT JOIN [dbo].[EASY__FIELDMAPPING] e2 ON e2.[easytable] = e.[relatedeasytable]
                                                              AND e.[active] = 1
                                                              AND e2.[transfertable] = 1
            WHERE   e.[easytable] = @easytable
                    AND e.[issuperfield] IN ( 0, 2 )
                    AND LEN(e.[protable]) > 0
                    AND e.[transfertable] = 1
                    AND ( ( e2.[protable] IS NOT NULL )
                          OR ( [e].[issuperfield] = 0 )
                        )
                    AND ( ( e.[relatedeasytable] IS NOT NULL )
                          OR ( [e].[issuperfield] = 0 )
                        )



        OPEN row_cursor
        FETCH NEXT FROM row_cursor INTO @protable, @relatedprotable,
            @easyfieldid, @easyfieldname, @relatedeasytable, @profield,
            @selectstatement, @issuperfield, @proposedvalue, @isrequired,
            @defaultvalue, @fieldtype
        WHILE @@FETCH_STATUS = 0 
            BEGIN
    
                IF ( @easytable = N'HISTORY' ) 
                    BEGIN		
				
                        SELECT  @select = @select + CHAR(10) + N', '
                                + CASE WHEN @issuperfield = 2
                                       THEN @selectstatement
                                       WHEN @issuperfield = 0
                                            AND @easyfieldid = N'history_type'
                                       THEN N'ISNULL( (CASE WHEN 1 = '
                                            + @isrequired
                                            + N' THEN CASE WHEN '
                                            + N'ISNULL(( SELECT TOP 1
                                                              o.[idstringlimepro]
                                                            FROM
                                                              [dbo].[EASY__OPTIONMAPPING]
                                                              AS o
                                                            WHERE
                                                              o.[easystringid] = 3
                                                              AND o.[easyvalue] = h.[historytype]
                                                          ), 0) = '
                                            + ISNULL(@defaultvalue, N'0')
                                            + N' THEN '
                                            + ISNULL(@proposedvalue, N'')
                                            + N' ELSE '
                                            + N' ISNULL(( SELECT TOP 1
                                                              o.[idstringlimepro]
                                                            FROM
                                                              [dbo].[EASY__OPTIONMAPPING]
                                                              AS o
                                                            WHERE
                                                              o.[easystringid] = 3
                                                              AND o.[easyvalue] = h.[historytype]
                                                          ),' + ISNULL(@proposedvalue, N'') + N') ' + N' END '
                                            + CHAR(10) + N' ELSE '
                                            + N' ISNULL(( SELECT TOP 1
                                                              o.[idstringlimepro]
                                                            FROM
                                                              [dbo].[EASY__OPTIONMAPPING]
                                                              AS o
                                                            WHERE
                                                              o.[easystringid] = 3
                                                              AND o.[easyvalue] = h.[historytype]
                                                          ),' + ISNULL(@defaultvalue, N'') + N') ' + N' END '
                                            + N'), ' + ISNULL(@proposedvalue,
                                                              N'') + N')'
                                       ELSE N'ISNULL(' + N'(CASE WHEN 1 = '
                                            + @isrequired
                                            + N' THEN CASE WHEN ISNULL('
                                            + QUOTENAME(@easyfieldname) 
                                            + CASE WHEN @fieldtype IN ( 1, 12,
                                                              23 )
                                                   THEN N', ' + N'''''' +   N')=N'''
                                                        + ISNULL(@defaultvalue,
                                                              N'') + N''''
                                                   WHEN @fieldtype = 20
                                                   THEN N', ' + N'''''' +   N')=' + CASE WHEN LEN(ISNULL(@defaultvalue,
                                                              N'')) > 0
                                                             THEN N''';'
                                                              + ISNULL(@defaultvalue,
                                                              N'') + N';'')'
                                                             ELSE N'N'''' '
                                                        END
                                                   ELSE N', ' + N'''''' +   N')=' + ISNULL(@defaultvalue,
                                                              N'')
                                              END + N' THEN '
                                            + CASE WHEN @fieldtype IN ( 1, 12,
                                                              23 )
                                                   THEN N'N'''
                                                        + ISNULL(@proposedvalue,
                                                              N'') + N''''
                                                   WHEN @fieldtype = 20
                                                   THEN CASE WHEN LEN(ISNULL(@proposedvalue,
                                                              N'')) > 0
                                                             THEN N''';'
                                                              + ISNULL(@proposedvalue,
                                                              N'') + N';'')'
                                                             ELSE N'N'''' '
                                                        END
                                                   ELSE ISNULL(@proposedvalue,
                                                              N'')
                                              END + N' ELSE ISNULL('
                                            + QUOTENAME(@easyfieldname)
                                            + CASE WHEN @fieldtype IN ( 1, 12,
                                                              23 )
                                                   THEN N', N'''
                                                        + ISNULL(@proposedvalue,
                                                              N'') + N''''
                                                   WHEN @fieldtype = 20
                                                   THEN CASE WHEN LEN(ISNULL(@proposedvalue,
                                                              N'')) > 0
                                                             THEN N', '';'
                                                              + ISNULL(@proposedvalue,
                                                              N'') + N';'')'
                                                             ELSE N', N'''' '
                                                        END
                                                   ELSE N', ' + ISNULL(@proposedvalue,
                                                              N'')
                                              END + N') '
                                            + N' END ELSE ISNULL( '
                                            + QUOTENAME(@easyfieldname)
                                            + CASE WHEN @fieldtype IN ( 1, 12,
                                                              23 )
                                                   THEN N', N'''
                                                        + ISNULL(@defaultvalue,
                                                              N'') + N''''
                                                   WHEN @fieldtype = 20
                                                   THEN CASE WHEN LEN(ISNULL(@defaultvalue,
                                                              N'')) > 0
                                                             THEN N', '';'
                                                              + ISNULL(@defaultvalue,
                                                              N'') + N';'')'
                                                             ELSE N', N'''' '
                                                        END
                                                   ELSE N', ' + ISNULL(@defaultvalue,
                                                              N'')
                                              END + N') '
                                            + N' END ) ' + N', '
                                            + CASE WHEN @fieldtype IN ( 1, 12,
                                                              23 )
                                                   THEN N'N'''
                                                        + ISNULL(@proposedvalue,
                                                              N'') + N''''
                                                   WHEN @fieldtype = 20
                                                   THEN CASE WHEN LEN(ISNULL(@proposedvalue,
                                                              N'')) > 0
                                                             THEN N''';'
                                                              + ISNULL(@proposedvalue,
                                                              N'') + N';'')'
                                                             ELSE N'N'''')'
                                                        END
                                                   ELSE ISNULL(@proposedvalue,
                                                              N'')
                                              END + N')'
                                  END
                        SELECT  @insert = @insert + CHAR(10) + N', '
                                + QUOTENAME(@profield)
                
                
                    END
        
                        
		
                FETCH NEXT FROM row_cursor INTO @protable, @relatedprotable,
                    @easyfieldid, @easyfieldname, @relatedeasytable, @profield,
                    @selectstatement, @issuperfield, @proposedvalue,
                    @isrequired, @defaultvalue, @fieldtype
            END
				
        CLOSE row_cursor
        DEALLOCATE row_cursor    


        IF ( LEN(@select) > 0
             AND LEN(@insert) > 0
           ) 
            BEGIN
                SELECT  @sql = N'INSERT INTO [dbo].' + QUOTENAME(@protable)
                        + CHAR(10) + N' ([status], [createduser], [createdtime], [updateduser],[timestamp]' + @insert + N')' + CHAR(10)
                        + N'SELECT 0, 1, GETDATE(), 1, GETDATE() ' + @select + CHAR(10)
                        + N'FROM [dbo].[EASY__SPLITTEDHISTORY] h'
        
            END
    
        IF ( LEN(ISNULL(@sql, N'')) > 0 ) 
            BEGIN
                BEGIN TRY
                    --PRINT @sql
                    EXEC sp_executesql @sql
                    SET @@errormessage = N''
                END TRY
                BEGIN CATCH
                    SET @@errormessage = ERROR_MESSAGE()
                END CATCH
            END
                
                
        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''
    END
GO


IF ( OBJECT_ID('csp_easytopro_insertsplithistory') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_insertsplithistory
	END
GO


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
GO


IF ( OBJECT_ID('csp_easytopro_link_project_contact') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_link_project_contact
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_link_project_contact]
    (
      @@tablenamemiddleobject NVARCHAR(64) ,
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
        
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
            --DECLARATIONS
        DECLARE @projecttable NVARCHAR(64)
        DECLARE @contacttable NVARCHAR(64)
        DECLARE @field NVARCHAR(64)
        DECLARE @sql NVARCHAR(MAX)
            
        DECLARE @result INT
        DECLARE @transaction INT
    

	-- Set initial values
        SET @result = 0
        SET @transaction = 0
        SET @@errormessage = N''
		
		-- Begin transaction
        IF @@TRANCOUNT = 0 
            BEGIN
                BEGIN TRANSACTION tran_link_project_contact
                SELECT  @transaction = 1
            END
		
		
        SELECT  @field = e.[profieldname]
        FROM    [dbo].[EASY__FIELDMAPPING] e
        WHERE   e.[easytable] = N'PROJECT'
                AND [easyfieldid] = N'project_relation_contact'
                AND e.[transfertable] = 1
                AND e.[active] = 1
		
		
        SELECT DISTINCT
                @projecttable = e.[protable]
        FROM    [dbo].[EASY__FIELDMAPPING] e
        WHERE   e.[easytable] = N'PROJECT'
                AND e.[transfertable] = 1
        SELECT DISTINCT
                @contacttable = e.[protable]
        FROM    [dbo].[EASY__FIELDMAPPING] e
        WHERE   e.[easytable] = N'CONTACT'
                AND e.[transfertable] = 1


        IF ( LEN(ISNULL(@field, N'')) > 0
             AND LEN(ISNULL(@projecttable, N'')) > 0
             AND LEN(ISNULL(@contacttable, N'')) > 0
           ) 
            BEGIN
			-- ADD 1 TO MANY RELATION
                IF ( LEN(ISNULL(@field, N'')) > 0 ) 
                    BEGIN
				
                        SELECT  @sql = N'UPDATE  p SET ' + QUOTENAME(@field)
                                + N' = i.[contact] ' + CHAR(10)
                                + N'FROM [dbo].' + QUOTENAME(@projecttable)
                                + N' p ' + CHAR(10) + N'INNER JOIN ('
                                + CHAR(10) + REPLICATE(CHAR(9), 3)
                                + N'SELECT c.[id' + @contacttable
                                + '] AS [contact], p.[id' + @projecttable
                                + N'] AS [project] , ' + CHAR(10)
                                + REPLICATE(CHAR(9), 6)
                                + N'ROW_NUMBER() OVER ( PARTITION BY p.[project_limeeasyid] ORDER BY (c.[id'
                                + @contacttable + N']) ASC) AS [row] '
                                + CHAR(10) + REPLICATE(CHAR(9), 3)
                                + N'FROM [dbo].[EASY__INCLUDE] ei ' + CHAR(10)
                                + REPLICATE(CHAR(9), 3) + N'INNER JOIN [dbo].'
                                + QUOTENAME(@contacttable)
                                + N' c ON ( c.[contact_limeeasyid] = ei.[Company ID] ) '
                                + CHAR(10) + REPLICATE(CHAR(9), 3)
                                + N'INNER JOIN [dbo].'
                                + QUOTENAME(@projecttable)
                                + N' p ON ( p.[project_limeeasyid] = ei.[Project ID] )'
                                + CHAR(10) + REPLICATE(CHAR(9), 3)
                                + N'WHERE	c.[status] = 0 ' + CHAR(10)
                                + REPLICATE(CHAR(9), 5)
                                + N'AND p.[status] = 0 ' + CHAR(10)
                                + REPLICATE(CHAR(9), 5)
                                + N'AND c.[contact_limeeasyid] IS NOT NULL '
                                + CHAR(10) + REPLICATE(CHAR(9), 5)
                                + N'AND p.[project_limeeasyid] IS NOT NULL'
                                + CHAR(10) + REPLICATE(CHAR(9), 3)
                                + N') i ON i.[project] = p.[id'
                                + @projecttable + N']' + CHAR(10)
                                + N'WHERE   i.[row] = 1'

                        BEGIN TRY 
                            EXEC sp_executesql @sql
                            SET @@errormessage = N''
                            SET @result = 0
                        END TRY
                        BEGIN CATCH
                            SET @@errormessage = ERROR_MESSAGE()
                            SET @result = 1
                        END CATCH	
                    END
                        
					-- ADD MANY TO MANY
					-- ADD TABLE IF NOT EXIST
                IF ( ( NOT EXISTS ( SELECT  t.[idtable]
                                    FROM    [dbo].[table] t
                                    WHERE   t.[name] = @@tablenamemiddleobject )
                     )
                     AND LEN(ISNULL(@@errormessage, N'')) = 0
                   ) 
                    BEGIN
                        EXEC [dbo].[csp_easytopro_create_tableifneeded] @@tablename = @@tablenamemiddleobject,
                            @@errormessage = @@errormessage OUTPUT
					
                    END
                    -- ADD RELATION TO CONTACT
                IF ( ( NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@tablenamemiddleobject
                                            AND f.[name] = @contacttable )
                     )
                     AND LEN(ISNULL(@@errormessage, N'')) = 0
                   ) 
                    BEGIN
                                
                        EXECUTE [dbo].[csp_easytopro_addrelation] @@tablename = @@tablenamemiddleobject,
                            @@fieldname = @contacttable,
                            @@relatedtablename = @contacttable,
                            @@errormessage = @@errormessage OUTPUT 
                    END
                    -- ADD RELATION TO PROJECT
                IF ( ( NOT EXISTS ( SELECT  f.[idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                    WHERE   t.[name] = @@tablenamemiddleobject
                                            AND f.[name] = @projecttable )
                     )
                     AND LEN(ISNULL(@@errormessage, N'')) = 0
                   ) 
                    BEGIN
                                
                        EXECUTE [dbo].[csp_easytopro_addrelation] @@tablename = @@tablenamemiddleobject,
                            @@fieldname = @projecttable,
                            @@relatedtablename = @projecttable,
                            @@errormessage = @@errormessage OUTPUT 
                    END
					
					
                IF ( LEN(ISNULL(@@errormessage, N'')) = 0 ) 
                    BEGIN
                        SET @sql = N''
							
                        SELECT  @sql = N'INSERT  INTO [dbo].'
                                + QUOTENAME(@@tablenamemiddleobject) + CHAR(10)
                                + N'( ' + CHAR(10) + REPLICATE(CHAR(9), 2)
                                + N'[status] , ' + CHAR(10) + REPLICATE(CHAR(9),
                                                              2)
                                + N'[createduser] , ' + CHAR(10)
                                + REPLICATE(CHAR(9), 2) + N'[createdtime] , '
                                + CHAR(10) + REPLICATE(CHAR(9), 2)
                                + N'[updateduser] , ' + CHAR(10)
                                + REPLICATE(CHAR(9), 2) + N'[timestamp] , '
                                + CHAR(10) + REPLICATE(CHAR(9), 2)
                                + QUOTENAME(@contacttable) + N' , ' + CHAR(10)
                                + REPLICATE(CHAR(9), 2)
                                + QUOTENAME(@projecttable) + CHAR(10) + N')'
                                + CHAR(10) + N'SELECT  ' + CHAR(10)
                                + REPLICATE(CHAR(9), 2) + N'0 , ' + CHAR(10)
                                + REPLICATE(CHAR(9), 2) + N'1 , ' + CHAR(10)
                                + REPLICATE(CHAR(9), 2) + N'GETDATE() , '
                                + CHAR(10) + REPLICATE(CHAR(9), 2) + N' 1 , '
                                + CHAR(10) + REPLICATE(CHAR(9), 2)
                                + N'GETDATE() , ' + CHAR(10)
                                + REPLICATE(CHAR(9), 2) + N'c.[id'
                                + @contacttable + '] , ' + REPLICATE(CHAR(9),
                                                              2) + N'p.[id'
                                + @projecttable + N']  ' + CHAR(10)
                                + N'FROM [dbo].[EASY__INCLUDE] ei ' + CHAR(10)
                                + N'INNER JOIN [dbo].'
                                + QUOTENAME(@contacttable)
                                + N' c ON ( c.[contact_limeeasyid] = ei.[Company ID] ) '
                                + CHAR(10) + N'INNER JOIN [dbo].'
                                + QUOTENAME(@projecttable)
                                + N' p ON ( p.[project_limeeasyid] = ei.[Project ID] )'
                                + CHAR(10) + N'WHERE	c.[status] = 0 '
                                + CHAR(10) + N'AND p.[status] = 0 ' + CHAR(10)
                                + N'AND c.[contact_limeeasyid] IS NOT NULL '
                                + CHAR(10)
                                + N'AND p.[project_limeeasyid] IS NOT NULL'

                        BEGIN TRY 
                            EXEC sp_executesql @sql
                            SET @@errormessage = N''
                            SET @result = 0
                        END TRY
                        BEGIN CATCH
                            SET @@errormessage = ERROR_MESSAGE()
                            SET @result = 1
                        END CATCH
                    END
					
					
            END
        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''
        
        IF @result <> 0 
            BEGIN
                IF @transaction = 1 
                    ROLLBACK TRANSACTION tran_link_project_contact
            END

	-- Commit transaction
        IF ( @transaction = 1
             AND @result = 0
           ) 
            BEGIN
                COMMIT TRANSACTION tran_link_project_contact
            END
    END
GO


IF ( OBJECT_ID('csp_easytopro_mergeuser') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_mergeuser
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_mergeuser]
    (
      @@easytable NVARCHAR(64) ,
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
         
        
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
            --DECLARATIONS
        DECLARE @sql NVARCHAR(MAX)
        DECLARE @fieldtype INT
        DECLARE @insert NVARCHAR(MAX)
        DECLARE @select NVARCHAR(MAX)
        DECLARE @update NVARCHAR(MAX)
        DECLARE @values NVARCHAR(MAX)
        DECLARE @protable NVARCHAR(64) 
        DECLARE @profield NVARCHAR(64) 
        DECLARE @relatedprotable NVARCHAR(64)
        DECLARE @relatedeasytable NVARCHAR(64)
        DECLARE @selectstatement NVARCHAR(2048)
        DECLARE @issuperfield INT
        DECLARE @proposedvalue NVARCHAR(128) 
        DECLARE @easyfieldname NVARCHAR(64)
        DECLARE @defaultvalue NVARCHAR(128) 
        DECLARE @isrequired NVARCHAR(1)

-- SET INITIAL VALUES
        SELECT  @sql = N''
        SELECT  @select = N''
        SELECT  @insert = N''
        SELECT  @update = N''
        SELECT  @values = N''


        DECLARE row_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
            SELECT DISTINCT
                    e.[protable] ,
                    e.[easyfieldname] ,
                    e.[profieldname] ,
                    CASE WHEN LEN(ISNULL(e.proposedvalue, N'')) > 0
                         THEN REPLACE(e.[proposedvalue], N'''', N'''''')
                         ELSE ( SELECT  CASE WHEN [isnullable] = 1
                                                  AND [defaultvalue] = N''
                                             THEN CAST(N'NULL' AS NVARCHAR(128))
                                             ELSE CAST([defaultvalue] AS NVARCHAR(128))
                                        END
                                FROM    [dbo].[fieldcache] f
                                        INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                              AND t.[name] = e.protable
                                WHERE   f.[name] = e.[profieldname]
                              )
                    END ,
                    CASE WHEN EXISTS ( SELECT   f.[idfield]
                                       FROM     [dbo].[fieldcache] f
                                                INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                INNER JOIN [dbo].[attributedata] a ON a.[idrecord] = f.[idfield]
                                                              AND a.[owner] = N'field'
                                                              AND a.[name] = N'required'
                                       WHERE    e.[profieldname] = f.[name]
                                                AND e.[protable] = t.[name] )
                         THEN N'1'
                         ELSE N'0'
                    END ,
                    ( SELECT TOP 1
                                CASE WHEN [isnullable] = 1
                                          AND [defaultvalue] = N''
                                     THEN CAST(N'NULL' AS NVARCHAR(128))
                                     ELSE CAST([defaultvalue] AS NVARCHAR(128))
                                END
                      FROM      [dbo].[fieldcache] f
                                INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                      WHERE     e.[profieldname] = f.[name]
                                AND e.[protable] = t.[name]
                    ) ,
                    e.[easyprofieldtype] ,
                    e.[issuperfield]
            FROM    [dbo].[EASY__FIELDMAPPING] e
            WHERE   e.[easytable] = @@easytable
                    AND e.[issuperfield] = 0
                    AND LEN(e.[protable]) > 0
                    AND e.[transfertable] = 1
                    AND e.[active] = 1
           

        OPEN row_cursor
        FETCH NEXT FROM row_cursor INTO @protable, @easyfieldname, @profield,
            @proposedvalue, @isrequired, @defaultvalue, @fieldtype,
            @issuperfield
        WHILE @@FETCH_STATUS = 0 
            BEGIN
    
                IF ( @@easytable = N'USER' ) -- HISTORY AND USER IS HANDLED IN OTHER CSP
                    BEGIN		
                        
                        SELECT  @select = @select + CHAR(10) + N', ' + QUOTENAME(@easyfieldname) --+ N' AS ' + QUOTENAME(@profield)
                        SELECT @update = @update + CHAR(10) +   N', ' + QUOTENAME(@profield) + N' = ISNULL('
                                +  N'(CASE WHEN 1 = ' + @isrequired
                                            + N' THEN CASE WHEN '
                                            + N'SOURCE.' + QUOTENAME(@easyfieldname) + N'='
                                            + CASE WHEN @fieldtype IN ( 1, 12,
                                                              23 )
                                                   THEN N'N'''
                                                        + ISNULL(@defaultvalue,
                                                              N'') + N''''
                                                   WHEN @fieldtype = 20
                                                   THEN CASE WHEN LEN(ISNULL(@defaultvalue,
                                                              N'')) > 0
                                                             THEN N''';'
                                                              + ISNULL(@defaultvalue,
                                                              N'') + N';'')'
                                                             ELSE N'N'''' '
                                                        END
                                                   ELSE ISNULL(@defaultvalue,
                                                              N'')
                                              END + N' THEN '
                                            + CASE WHEN @fieldtype IN ( 1, 12,
                                                              23 )
                                                   THEN N'N'''
                                                        + ISNULL(@proposedvalue,
                                                              N'') + N''''
                                                   WHEN @fieldtype = 20
                                                   THEN CASE WHEN LEN(ISNULL(@proposedvalue,
                                                              N'')) > 0
                                                             THEN N''';'
                                                              + ISNULL(@proposedvalue,
                                                              N'') + N';'')'
                                                             ELSE N'N'''' '
                                                        END
                                                   ELSE ISNULL(@proposedvalue,
                                                              N'')
                                              END + N' ELSE '
                                            + N'SOURCE.' + QUOTENAME(@easyfieldname)
                                            + N' END ELSE '
                                            + N'SOURCE.' + QUOTENAME(@easyfieldname)
                                            + N' END ) '
                                   + N', '
                                + CASE WHEN @fieldtype IN ( 1, 12, 23 )
                                       THEN N'N''' + ISNULL(@proposedvalue,
                                                            N'') + N''''
                                       WHEN @fieldtype = 20
                                       THEN CASE WHEN LEN(ISNULL(@proposedvalue,
                                                              N'')) > 0
                                                 THEN N''';'
                                                      + ISNULL(@proposedvalue,
                                                              N'') + N';'')'
                                                 ELSE N'N'''')'
                                            END
                                       ELSE ISNULL(@proposedvalue, N'')
                                  END + N')' ,
                                  
                                @insert = @insert + CHAR(10) + N', '
                                + QUOTENAME(@profield) ,
                                
                                @values = @values + CHAR(10) + N', SOURCE.' + QUOTENAME(@easyfieldname) 
                
                
                    END
        
                        
		
                FETCH NEXT FROM row_cursor INTO @protable, @easyfieldname,
                    @profield, @proposedvalue, @isrequired, @defaultvalue,
                    @fieldtype, @issuperfield
            END
				
        CLOSE row_cursor
        DEALLOCATE row_cursor    

        IF ( LEN(@select) > 0
             AND LEN(@insert) > 0 AND LEN(@update) > 0 AND LEN(@values) > 0
           ) 
            BEGIN
                SELECT  @sql = N'MERGE [dbo].' + QUOTENAME(@protable) + N'AS TARGET' + CHAR(10) + N'USING' + CHAR(10)
						+ N' (SELECT [User ID] AS [user_limeeasyid], [Name] AS [easy_fullname]' + @select +
                        + CHAR(10)
                        + N' FROM [dbo].[EASY__'
                        + @@easytable + N']'
                        + N') AS SOURCE ( [user_limeeasyid], [easy_fullname]' + @select + N')'
                        + CHAR(10)
                        + N' ON ( TARGET.[user_limeeasyid] = SOURCE.[user_limeeasyid] AND TARGET.[status] = 0 )'
						+ CHAR(10)
						+ N'WHEN MATCHED '
						+ CHAR(10)
						+ N'THEN'
						+ CHAR(10)
						+ N'UPDATE SET' 
						+ CHAR(10)
						+ N'[user_limeeasyid] = SOURCE.[user_limeeasyid], [easy_fullname] = SOURCE.[easy_fullname]' + @update
						+ CHAR(10)
						+ N'WHEN NOT MATCHED BY TARGET 
                    THEN
				INSERT  (
                          [status] ,
                          [createduser] ,
                          [createdtime] ,
                          [updateduser] ,
                          [timestamp] ,[user_limeeasyid] , [easy_fullname]' + @insert
                          + CHAR(10)
                          + N')'
                          + CHAR(10)
                          + N'VALUES ( 0, 1, GETDATE(), 1, GETDATE() ,
							SOURCE.[user_limeeasyid], SOURCE.[easy_fullname]' + @values 
							+CHAR(10)
							+ N');'
                          
                       
        
            END
    
        IF ( LEN(ISNULL(@sql, N'')) > 0 ) 
            BEGIN
                BEGIN TRY
                    --PRINT @sql
                    EXEC sp_executesql @sql

                    SET @@errormessage = N''
                END TRY
                BEGIN CATCH
						--PRINT ERROR_MESSAGE()
                    SET @@errormessage = ERROR_MESSAGE()
                END CATCH
            END
                
        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''
    END
GO


IF ( OBJECT_ID('csp_easytopro_project') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_project
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_project]
    @@xml AS NVARCHAR(MAX) ,
    @@rebuildtable AS BIT
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @iXML INT


        IF ( @@rebuildtable = 1 ) 
            BEGIN

                IF EXISTS ( SELECT  *
                            FROM    sys.objects
                            WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__PROJECT]')
                                    AND type IN ( N'U' ) ) 
                    DROP TABLE [dbo].[EASY__PROJECT] 

                CREATE TABLE [dbo].[EASY__PROJECT]
                    (
                      [Project ID] INT NOT NULL ,
                      [Name] NVARCHAR(48) ,
                      [Description] NVARCHAR(255) ,
                      [Flags] SMALLINT ,
                      [Created date] DATETIME ,
                      [Created time] INT ,
                      [Created user ID] SMALLINT ,
                      [Updated date] DATETIME ,
                      [Updated time] INT ,
                      [Updated user ID] SMALLINT
                    )
            END	

        EXEC sp_xml_preparedocument @iXML OUTPUT, @@xml

        INSERT  INTO [dbo].[EASY__PROJECT]
                ( [Project ID] ,
                  [Name] ,
                  [Description] ,
                  [Flags] ,
                  [Created date] ,
                  [Created time] ,
                  [Created user ID] ,
                  [Updated date] ,
                  [Updated time] ,
                  [Updated user ID] 
                )
                SELECT  [projectid] ,
                        [name] ,
                        [description] ,
                        [flags] ,
                        CASE WHEN [createddate] = N'' THEN NULL ELSE CAST([createddate] AS DATETIME) END ,
                        [createdtime] ,
                        [createduserid] ,
                        CASE WHEN [updateddate] = N'' THEN NULL ELSE CAST([updateddate] AS DATETIME) END ,
                        [updatedtime] ,
                        [updateduserid]
                FROM    OPENXML(@iXML, '/data/row')
	WITH (	
			      [projectid] INT,  
			      [name] NVARCHAR(48),  
			      [description] NVARCHAR(255),  
			      [flags] SMALLINT,  
			      [createddate] NVARCHAR(32),  
			      [createdtime] INT,  
			      [createduserid] SMALLINT,  
			      [updateddate] NVARCHAR(32),  
			      [updatedtime] INT,  
			      [updateduserid] SMALLINT    
		  ) 
	

        EXECUTE sp_xml_removedocument @iXML
    END
GO


IF ( OBJECT_ID('csp_easytopro_rebuildsplithistory') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_rebuildsplithistory
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_rebuildsplithistory]
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
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
                          [time_limeeasyid] INT, 
						  [historyid] INT
                        )
		END
GO


IF ( OBJECT_ID('csp_easytopro_refs') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_refs
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_refs]
    @@xml AS NVARCHAR(MAX) ,
    @@rebuildtable AS BIT
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @iXML INT


        IF ( @@rebuildtable = 1 ) 
            BEGIN
                IF EXISTS ( SELECT  *
                            FROM    sys.objects
                            WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__REFS]')
                                    AND type IN ( N'U' ) ) 
                    DROP TABLE [dbo].[EASY__REFS] 

                CREATE TABLE [dbo].[EASY__REFS]
                    (
                      [Company ID] INT NOT NULL ,
                      [Reference ID] INT NOT NULL ,
                      [Name] NVARCHAR(48) ,
                      [firstname] NVARCHAR(48) ,
                      [lastname] NVARCHAR(48) ,
                      [Flags] SMALLINT ,
                      [Created date] DATETIME ,
                      [Created time] INT ,
                      [Created user ID] SMALLINT ,
                      [Updated date] DATETIME ,
                      [Updated time] INT ,
                      [Updated user ID] SMALLINT
                    )
            END

        EXEC sp_xml_preparedocument @iXML OUTPUT, @@xml

        INSERT  INTO [dbo].[EASY__REFS]
                ( [Company ID] ,
                  [Reference ID] ,
                  [Name] ,
                  [firstname] ,
                  [lastname] ,
                  [Flags] ,
                  [Created date] ,
                  [Created time] ,
                  [Created user ID] ,
                  [Updated date] ,
                  [Updated time] ,
                  [Updated user ID]
                )
                SELECT  [companyid] ,
                        [referenceid] ,
                        [name] ,
                        ISNULL(LTRIM(RTRIM(LEFT([name],
                                                COALESCE(NULLIF(CHARINDEX(N' ',
                                                              [name]), 0) - 1,
                                                         LEN([name]))))), N'') , -- [firstname] 
                        ISNULL(LTRIM(RTRIM(RIGHT([name],
                                                 LEN([name]) - LEN(LEFT([name],
                                                              COALESCE(NULLIF(CHARINDEX(N' ',
                                                              [name]), 0) - 1,
                                                              LEN([name]))))))),
                               N'') , -- [lastname] 
                        [flags] ,
                        CASE WHEN [createddate] = N'' THEN NULL ELSE CAST([createddate] AS DATETIME) END ,
                        [createdtime] ,
                        [createduserid] ,
                        CASE WHEN [updateddate] = N'' THEN NULL ELSE CAST([updateddate] AS DATETIME) END ,
                        [updatedtime] ,
                        [updateduserid]
                FROM    OPENXML(@iXML, '/data/row')
	WITH (	
			      [companyid] INT,  
			      [referenceid] INT,  
			      [name] NVARCHAR(48),  
			      [flags] SMALLINT, 
			      [createddate] NVARCHAR(32),  
			      [createdtime] INT,  
			      [createduserid] SMALLINT,  
			      [updateddate] NVARCHAR(32),  
			      [updatedtime] INT,  
			      [updateduserid] SMALLINT    
		  ) 
	

        EXECUTE sp_xml_removedocument @iXML
    END
GO


IF ( OBJECT_ID('csp_easytopro_replace_easy__fieldmapping') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_replace_easy__fieldmapping
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_replace_easy__fieldmapping] 
	(
      @@xml NVARCHAR(MAX),
      @@errormessage NVARCHAR(2048) OUTPUT
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;

        SET @@errormessage = N''
        
        IF EXISTS ( SELECT  *
                    FROM    sys.objects
                    WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__FIELDMAPPING]')
                            AND type IN ( N'U' ) ) 
            BEGIN
                BEGIN TRY
					declare @idoc int
					exec sp_xml_preparedocument @idoc output, @@xml
					
					TRUNCATE TABLE [dbo].[EASY__FIELDMAPPING]
					
					SET IDENTITY_INSERT EASY__FIELDMAPPING ON
					
					INSERT INTO [dbo].[EASY__FIELDMAPPING]
					(idfieldmapping, easytable, relatedeasytable, easyfieldname, issuperfield, easyfieldid, easyfieldorder, easyfieldtype, easydatatype, easydatatypedata, easydatatypetext, protable, transfertable, profieldname, localname_sv, localname_en_us, localname_no, localname_fi, localname_da, active, easyprofieldtype, proposedvalue)
					SELECT *
					FROM OPENXML (@idoc, 'data/fieldmapping')
					WITH(
					idfieldmapping INT,
					easytable NVARCHAR(64),
					relatedeasytable NVARCHAR(64),
					easyfieldname NVARCHAR(64),
					issuperfield INT,
					easyfieldid NVARCHAR(64),
					easyfieldorder INT,
					easyfieldtype INT,
					easydatatype INT,
					easydatatypedata INT,
					easydatatypetext NVARCHAR(64),
					protable NVARCHAR(64),
					transfertable INT,
					profieldname NVARCHAR(64),
					localname_sv NVARCHAR(64),
					localname_en_us NVARCHAR(64),
					localname_no NVARCHAR(64),
					localname_fi NVARCHAR(64),
					localname_da NVARCHAR(64),
					active INT,
					easyprofieldtype INT,
					proposedvalue NVARCHAR(64)
					)
					
					SET IDENTITY_INSERT EASY__FIELDMAPPING OFF
					
                END TRY
                BEGIN CATCH
                    SET @@errormessage = ERROR_MESSAGE()
                END CATCH
            END
        
    END
GO


IF ( OBJECT_ID('csp_easytopro_replace_easy__optionmapping') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_replace_easy__optionmapping
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_replace_easy__optionmapping] 
	(
      @@xml NVARCHAR(MAX),
      @@errormessage NVARCHAR(2048) OUTPUT
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;

        SET @@errormessage = N''
        
        IF EXISTS ( SELECT  *
                    FROM    sys.objects
                    WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__OPTIONMAPPING]')
                            AND type IN ( N'U' ) ) 
            BEGIN
                BEGIN TRY
					declare @idoc int
					exec sp_xml_preparedocument @idoc output, @@xml
					
					TRUNCATE TABLE [dbo].[EASY__OPTIONMAPPING]
					
					SET IDENTITY_INSERT EASY__OPTIONMAPPING ON
					
					INSERT INTO [dbo].[EASY__OPTIONMAPPING]
					(idoptionmapping, fieldmapping, easystringid, easyvalue, idcategorylimepro, idstringlimepro)
					SELECT *
					FROM OPENXML (@idoc, 'data/dbo.EASY__OPTIONMAPPING')
					WITH(
						idoptionmapping INT,
						fieldmapping INT,
						easystringid SMALLINT,
						easyvalue NVARCHAR(96),
						idcategorylimepro INT,
						idstringlimepro INT
					)
					
					SET IDENTITY_INSERT EASY__OPTIONMAPPING OFF
					
                END TRY
                BEGIN CATCH
                    SET @@errormessage = ERROR_MESSAGE()
                END CATCH
            END
        
    END
GO


IF ( OBJECT_ID('csp_easytopro_runsqlonupdate') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_runsqlonupdate
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_runsqlonupdate]
    (
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;

        DECLARE @sql NVARCHAR(MAX)

        SET @@errormessage = N''

        DECLARE table_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
            SELECT DISTINCT
                    [dbo].[lfn_getonsqlupdate](e.[protable], 1)
            FROM    [dbo].[EASY__FIELDMAPPING] e
            WHERE   e.[transfertable] = 1
		

        OPEN table_cursor
        FETCH NEXT FROM table_cursor INTO @sql      
        WHILE @@FETCH_STATUS = 0
            AND @@errormessage = N'' 
            BEGIN
                    
                BEGIN TRY
                    IF (LEN(ISNULL(@sql,N''))>0)
                        BEGIN
                            EXEC sp_executesql @sql	
                        END
                            
                END TRY
                BEGIN CATCH
                    SET @@errormessage = ERROR_MESSAGE()
                END CATCH
                FETCH NEXT FROM table_cursor INTO @sql
            END
				
        CLOSE table_cursor
        DEALLOCATE table_cursor    

        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''
                
    END
GO


IF ( OBJECT_ID('csp_easytopro_settings') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_settings
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_settings]
    @@xml AS NVARCHAR(MAX) ,
    @@rebuildtable AS BIT
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @iXML INT


        IF ( @@rebuildtable = 1 ) 
            BEGIN

        
       
      
                IF EXISTS ( SELECT  *
                            FROM    sys.objects
                            WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__SETTINGS]')
                                    AND type IN ( N'U' ) ) 
                    DROP TABLE [dbo].[EASY__SETTINGS] 

                CREATE TABLE [dbo].[EASY__SETTINGS]
                    (
                      [Item] NVARCHAR(50) NOT NULL ,
                      [Value] NVARCHAR(50)
                    )

            END

        EXEC sp_xml_preparedocument @iXML OUTPUT, @@xml

        INSERT  INTO [dbo].[EASY__SETTINGS]
                ( [Item] ,
                  [Value] 
                )
                SELECT  [item] ,
                        [value]
                FROM    OPENXML(@iXML, '/data/row')
	WITH ( 
			    [item] NVARCHAR(50),   
			    [value] NVARCHAR(50)        
		  ) 
	

        EXECUTE sp_xml_removedocument @iXML
    END
GO


IF ( OBJECT_ID('csp_easytopro_splithistory') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_splithistory
	END
GO


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
GO


IF ( OBJECT_ID('csp_easytopro_string') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_string
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_string]
    @@xml AS NVARCHAR(MAX) ,
    @@rebuildtable AS BIT
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @iXML INT


        IF ( @@rebuildtable = 1 ) 
            BEGIN

        
                IF EXISTS ( SELECT  *
                            FROM    sys.objects
                            WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__STRING]')
                                    AND type IN ( N'U' ) ) 
                    DROP TABLE [dbo].[EASY__STRING] 

                CREATE TABLE [dbo].[EASY__STRING]
                    (
                      [String ID] SMALLINT NOT NULL ,
                      [String] NVARCHAR(96) NOT NULL
                    )

            END
        EXEC sp_xml_preparedocument @iXML OUTPUT, @@xml

        INSERT  INTO [dbo].[EASY__STRING]
                ( [String ID] ,
                  [String] 
                )
                SELECT  [stringid] ,
                        [string]
                FROM    OPENXML(@iXML, '/data/row')
	WITH (	
			      [stringid] SMALLINT,  
			      [string] NVARCHAR(96) 
		  ) 
	

        EXECUTE sp_xml_removedocument @iXML
    END
GO


IF ( OBJECT_ID('csp_easytopro_time') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_time
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_time]
    @@xml AS NVARCHAR(MAX) ,
    @@rebuildtable AS BIT
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @iXML INT


        IF ( @@rebuildtable = 1 ) 
            BEGIN

        
                IF EXISTS ( SELECT  *
                            FROM    sys.objects
                            WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__TIME]')
                                    AND type IN ( N'U' ) ) 
                    DROP TABLE [dbo].[EASY__TIME] 

                CREATE TABLE [dbo].[EASY__TIME]
                    (
                      [Company ID] INT NOT NULL ,
                      [Time ID] INT NOT NULL ,
                      [Date] DATETIME ,
                      [Minutes] INT ,
                      [Done] SMALLINT ,
                      [Flags] SMALLINT ,
                      [Description] NVARCHAR(96) ,
                      [User ID] SMALLINT ,
                      [Type] NVARCHAR(48) ,
                      [Tax] FLOAT ,
                      [Actual minutes] INT ,
                      [Project] NVARCHAR(48) ,
                      [Amount] FLOAT
                    )
            END

        EXEC sp_xml_preparedocument @iXML OUTPUT, @@xml

        INSERT  INTO [dbo].[EASY__TIME]
                ( [Company ID] ,
                  [Time ID] ,
                  [Date] ,
                  [Minutes] ,
                  [Done] ,
                  [Flags] ,
                  [Description] ,
                  [User ID] ,
                  [Type] ,
                  [Tax] ,
                  [Actual minutes] ,
                  [Project] ,
                  [Amount]
                )
                SELECT  [companyid] ,
                        [timeid] ,
                        CASE WHEN [date] = N'' THEN NULL ELSE CAST([date] AS DATETIME) END ,
                        [minutes] ,
                        [done] ,
                        [flags] ,
                        [description] ,
                        [userid] ,
                        [type] ,
						CAST(REPLACE([tax], N',','.') AS FLOAT) ,
                        [actualminutes] ,
                        [project] ,
                        CAST(REPLACE([amount], N',','.') AS FLOAT)
                FROM    OPENXML(@iXML, '/data/row')
	WITH (	
			          [companyid] INT,  
			          [timeid] INT,  
			          [date] NVARCHAR(32),  
			          [minutes] INT,  
			          [done] SMALLINT,  
			          [flags] SMALLINT,  
			          [description] NVARCHAR(96),  
			          [userid] SMALLINT,  
			          [type] NVARCHAR(48),  
			          [tax] NVARCHAR(64),  
			          [actualminutes] INT,  
			          [project] NVARCHAR(48),  
			          [amount] NVARCHAR(64)  
		  ) 
	

        EXECUTE sp_xml_removedocument @iXML
    END
GO


IF ( OBJECT_ID('csp_easytopro_todo') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_todo
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_todo]
    @@xml AS NVARCHAR(MAX) ,
    @@rebuildtable AS BIT
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @iXML INT


        IF ( @@rebuildtable = 1 ) 
            BEGIN

        
       
                IF EXISTS ( SELECT  *
                            FROM    sys.objects
                            WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__TODO]')
                                    AND type IN ( N'U' ) ) 
                    DROP TABLE [dbo].[EASY__TODO] 

                CREATE TABLE [dbo].[EASY__TODO]
                    (
                      [Type] SMALLINT NOT NULL ,
                      [Key 1] INT NOT NULL ,
                      [Key 2] INT NOT NULL ,
                      [Description] NVARCHAR(255) ,
                      [Priority] SMALLINT ,
                      [Start date] DATETIME ,
                      [Start time] INT ,
                      [Stop date] DATETIME ,
                      [Stop time] INT ,
                      [User ID] SMALLINT ,
                      [Done date] DATETIME ,
                      [Done time] INT ,
                      [Done user ID] SMALLINT ,
                      [Timestamp date] DATETIME ,
                      [Timestamp time] INT
                    )
            END

        EXEC sp_xml_preparedocument @iXML OUTPUT, @@xml

        INSERT  INTO [dbo].[EASY__TODO]
                ( [Type] ,
                  [Key 1] ,
                  [Key 2] ,
                  [Description] ,
                  [Priority] ,
                  [Start date] ,
                  [Start time] ,
                  [Stop date] ,
                  [Stop time] ,
                  [User ID] ,
                  [Done date] ,
                  [Done time] ,
                  [Done user ID] ,
                  [Timestamp date] ,
                  [Timestamp time]
                )
                SELECT  [type] ,
                        [key1] ,
                        [key2] ,
                        [description] ,
                        [priority] ,
                        CASE WHEN [startdate] = N'' THEN NULL ELSE CAST([startdate] AS DATETIME) END ,
                        [starttime] ,
                        CASE WHEN [stopdate] = N'' THEN NULL ELSE CAST([stopdate] AS DATETIME) END ,
                        [stoptime] ,
                        [userid] ,
                        CASE WHEN [donedate] = N'' THEN NULL ELSE CAST([donedate] AS DATETIME) END ,
                        [donetime] ,
                        [doneuserid] ,
                        CASE WHEN [timestampdate] = N'' THEN NULL ELSE CAST([timestampdate] AS DATETIME) END ,
                        [timestamptime]
                FROM    OPENXML(@iXML, '/data/row')
	WITH (	
			            [type] SMALLINT,  
			            [key1] INT,  
			            [key2] INT,  
			            [description] NVARCHAR(255),  
			            [priority] SMALLINT,  
			            [startdate] NVARCHAR(32),  
			            [starttime] INT,  
			            [stopdate] NVARCHAR(32),  
			            [stoptime] INT,  
			            [userid] SMALLINT,  
			            [donedate] NVARCHAR(32),  
			            [donetime] INT,  
			            [doneuserid] SMALLINT,  
			            [timestampdate] NVARCHAR(32),  
			            [timestamptime] INT    
		  ) 
	

        EXECUTE sp_xml_removedocument @iXML
    END
GO


IF ( OBJECT_ID('csp_easytopro_truncatetransfertables') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_truncatetransfertables
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_truncatetransfertables]
    (
      @@linkprojecttocompanytable NVARCHAR(64) = NULL ,
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
         
        
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;

        DECLARE @protable NVARCHAR(64)
        DECLARE @easytable NVARCHAR(64)
        DECLARE @sql NVARCHAR(MAX)

        SET @@errormessage = N''

        DECLARE table_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
            SELECT DISTINCT
                    [protable] ,
                    [easytable]
            FROM    [dbo].[EASY__FIELDMAPPING]
            WHERE   [transfertable] = 1
                    AND LEN(ISNULL([protable], N'')) > 0
                    AND [easytable] != N'USER'
		

        OPEN table_cursor
        FETCH NEXT FROM table_cursor INTO @protable, @easytable      
        WHILE @@FETCH_STATUS = 0
            AND @@errormessage = N'' 
            BEGIN
                    
                BEGIN TRY
                    IF EXISTS ( SELECT  t.[idtable]
                                FROM    [dbo].[table] t
                                WHERE   t.[name] = @protable ) 
                        BEGIN
                            SELECT  @sql = N'TRUNCATE TABLE [dbo].'
                                    + QUOTENAME(@protable)
								
                            EXEC sp_executesql @sql
								
                            IF ( @easytable = N'PROJECT'
                                 AND ( LEN(ISNULL(@@linkprojecttocompanytable,
                                                  N'')) > 0 )
                               ) 
                                BEGIN
                                    IF EXISTS ( SELECT  t.[idtable]
                                                FROM    [dbo].[table] t
                                                WHERE   t.[name] = @@linkprojecttocompanytable ) 
                                        BEGIN
                                            SELECT  @sql = N'TRUNCATE TABLE [dbo].'
                                                    + QUOTENAME(@@linkprojecttocompanytable)
								
                                            EXEC sp_executesql @sql
                                        END
                                END
								
                            IF ( @easytable = N'ARCHIVE' ) 
                                BEGIN
                                    DELETE  FROM [dbo].[file]
                                    WHERE   [filetype] = 1
                                END
								
                        END
                            
                END TRY
                BEGIN CATCH
                    SET @@errormessage = ERROR_MESSAGE()
                END CATCH
                FETCH NEXT FROM table_cursor INTO @protable, @easytable
            END
				
        CLOSE table_cursor
        DEALLOCATE table_cursor    

        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''
                
    END
GO


IF ( OBJECT_ID('csp_easytopro_updatefixedrelationfields') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_updatefixedrelationfields
	END
GO


CREATE PROCEDURE  [dbo].[csp_easytopro_updatefixedrelationfields]
    (
      @@easytable NVARCHAR(64) ,
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
         
        
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
            --DECLARATIONS

        DECLARE @sql NVARCHAR(MAX)
        DECLARE @protable NVARCHAR(64) 
        DECLARE @profield NVARCHAR(64) 
        DECLARE @relatedprotable NVARCHAR(64)
        DECLARE @relatedeasytable NVARCHAR(64)
        SELECT  @sql = N''


		--NEW 2014-09-12
		--UPDATED 2015-03-02 JSP: use migration field easy_fullname for mapping todo, document etc
        DECLARE @name_person_field AS NVARCHAR(48)
        SET @name_person_field = 'easy_fullname'
		
        --SELECT  @name_person_field = [profieldname]
        --FROM    [dbo].[EASY__FIELDMAPPING]
        --WHERE   [easyfieldid] = N'person_name'
        --        AND [easytable] = N'REFS'
		
        --SET @name_person_field = ISNULL(@name_person_field, N'')
		
        DECLARE row_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
            SELECT DISTINCT
                    e.[protable] ,
                    e2.[protable] ,
                    e.[relatedeasytable] ,
                    e.[profieldname]
            FROM    [dbo].[EASY__FIELDMAPPING] e
                    LEFT JOIN [dbo].[EASY__FIELDMAPPING] e2 ON e2.[easytable] = e.[relatedeasytable]
                                                              AND e.[active] = 1
                                                              AND e2.[transfertable] = 1
            WHERE   e.[easytable] = @@easytable
                    AND e.[issuperfield] = 2
                    AND LEN(e.[protable]) > 0
                    AND e.[transfertable] = 1
                    AND e2.[protable] IS NOT NULL
                    AND e.[relatedeasytable] IS NOT NULL



        OPEN row_cursor
        FETCH NEXT FROM row_cursor INTO @protable, @relatedprotable,
            @relatedeasytable, @profield
        WHILE @@FETCH_STATUS = 0 
            BEGIN
    
                IF ( @@easytable = N'ARCHIVE' ) 
                    BEGIN			
                        SELECT  @sql = CASE @relatedeasytable
                                         WHEN N'CONTACT'
                                         THEN @sql + N', '
                                              + QUOTENAME(@profield)
                                              + N' = CASE WHEN e.[Type] = 0 THEN (SELECT TOP 1 l.[id'
                                              + @relatedprotable + N'] '
                                              + N'FROM [dbo].'
                                              + QUOTENAME(@relatedprotable)
                                              + N'AS l WHERE l.['
                                              + LOWER(@relatedeasytable)
                                              + N'_limeeasyid] = e.[Key 1] AND l.[status] = 0) ELSE NULL END'
                                              + CHAR(10)
                                         WHEN N'PROJECT'
                                         THEN @sql + N', '
                                              + QUOTENAME(@profield)
                                              + N' = CASE WHEN e.[Type] = 2 THEN (SELECT TOP 1 l.[id'
                                              + @relatedprotable + N'] '
                                              + N'FROM [dbo].'
                                              + QUOTENAME(@relatedprotable)
                                              + N'AS l WHERE l.['
                                              + LOWER(@relatedeasytable)
                                              + N'_limeeasyid] = e.[Key 1] AND l.[status] = 0) ELSE NULL END'
                                              + CHAR(10)
                                         WHEN N'USER'
                                         THEN @sql + N', '
                                              + QUOTENAME(@profield)
                                              + N' =  (SELECT TOP 1 l.[id'
                                              + @relatedprotable + N'] '
                                              + N'FROM [dbo].'
                                              + QUOTENAME(@relatedprotable)
                                              + N'AS l WHERE l.['
                                              + LOWER(@relatedeasytable)
                                              + N'_limeeasyid] = e.[User ID] AND l.[status] = 0)'
                                              + CHAR(10)
                                         WHEN N'REFS'
                                         THEN @sql
                                              + CASE WHEN LEN(@name_person_field) = 0
                                                     THEN N''
                                                     ELSE N', '
                                                          + QUOTENAME(@profield)
                                                          + N' = CASE WHEN e.[Type] = 0 THEN (SELECT TOP 1 l.[id'
                                                          + @relatedprotable
                                                          + N'] '
                                                          + N'FROM [dbo].'
                                                          + QUOTENAME(@relatedprotable)
                                                          + N'AS l WHERE l.[contact_limeeasyid] = e.[Key 1] AND  l.'
                                                          + QUOTENAME(@name_person_field)
                                                          + N' = e.[Reference] AND l.[status] = 0)'
                                                          + CHAR(10)
                                                          + N' ELSE NULL END'
                                                          + CHAR(10)
                                                END
                                         ELSE @sql
                                       END
                    END
                ELSE 
                    IF ( @@easytable = N'REFS' ) 
                        BEGIN
                            SELECT  @sql = CASE @relatedeasytable
                                             WHEN N'CONTACT'
                                             THEN @sql + N', '
                                                  + QUOTENAME(@profield)
                                                  + N' = (SELECT TOP 1 l.[id'
                                                  + @relatedprotable + N'] '
                                                  + N'FROM [dbo].'
                                                  + QUOTENAME(@relatedprotable)
                                                  + N'AS l WHERE l.['
                                                  + LOWER(@relatedeasytable)
                                                  + N'_limeeasyid] = e.[Company ID] AND l.[status] = 0)'
                                                  + CHAR(10)
                                             ELSE @sql
                                           END
                        END
                    ELSE 
                        IF ( @@easytable = N'TODO' ) 
                            BEGIN			
                                SELECT  @sql = CASE @relatedeasytable
                                                 WHEN N'CONTACT'
                                                 THEN @sql + N', '
                                                      + QUOTENAME(@profield)
                                                      + N' = CASE WHEN e.[Type] IN (0,8) THEN (SELECT TOP 1 l.[id'
                                                      + @relatedprotable
                                                      + N'] ' + N'FROM [dbo].'
                                                      + QUOTENAME(@relatedprotable)
                                                      + N'AS l WHERE l.['
                                                      + LOWER(@relatedeasytable)
                                                      + N'_limeeasyid] = e.[Key 1] AND l.[status] = 0) ELSE NULL END'
                                                      + CHAR(10)
                                                 WHEN N'PROJECT'
                                                 THEN @sql + N', '
                                                      + QUOTENAME(@profield)
                                                      + N' = CASE WHEN e.[Type] = 2 THEN (SELECT TOP 1 l.[id'
                                                      + @relatedprotable
                                                      + N'] ' + N'FROM [dbo].'
                                                      + QUOTENAME(@relatedprotable)
                                                      + N'AS l WHERE l.['
                                                      + LOWER(@relatedeasytable)
                                                      + N'_limeeasyid] = e.[Key 1] AND l.[status] = 0) ELSE NULL END'
                                                      + CHAR(10)
                                                 WHEN N'USER'
                                                 THEN @sql + N', '
                                                      + QUOTENAME(@profield)
                                                      + N' =  (SELECT TOP 1 l.[id'
                                                      + @relatedprotable
                                                      + N'] ' + N'FROM [dbo].'
                                                      + QUOTENAME(@relatedprotable)
                                                      + N'AS l WHERE l.['
                                                      + LOWER(@relatedeasytable)
                                                      + N'_limeeasyid] = e.[User ID] AND l.[status] = 0)'
                                                      + CHAR(10)
                                                 WHEN N'REFS'
                                                 THEN @sql
                                                      + CASE WHEN LEN(@name_person_field) = 0
                                                             THEN N''
                                                             ELSE N', '
                                                              + QUOTENAME(@profield)
                                                              + N' = CASE WHEN e.[Type] IN ( 0, 8 ) THEN (SELECT TOP 1 l.[id'
                                                              + @relatedprotable
                                                              + N'] '
                                                              + N'FROM [dbo].'
                                                              + QUOTENAME(@relatedprotable)
                                                              + N'AS l WHERE l.[contact_limeeasyid] = e.[Key 1] AND CHARINDEX(N''('' + l.'
                                                              + QUOTENAME(@name_person_field)
                                                              + N' + N'')'', e.[Description])>0 AND l.[status] = 0)'
                                                              + CHAR(10)
                                                              + N' ELSE NULL END'
                                                              + CHAR(10)
                                                        END
                                                 ELSE @sql
                                               END
                            END
                        ELSE 
                            IF ( @@easytable = N'TIME' ) 
                                BEGIN
                                    SELECT  @sql = CASE @relatedeasytable
                                                     WHEN N'CONTACT'
                                                     THEN @sql + N', '
                                                          + QUOTENAME(@profield)
                                                          + N' = (SELECT TOP 1 l.[id'
                                                          + @relatedprotable
                                                          + N'] '
                                                          + N'FROM [dbo].'
                                                          + QUOTENAME(@relatedprotable)
                                                          + N' AS l WHERE l.['
                                                          + LOWER(@relatedeasytable)
                                                          + N'_limeeasyid] = e.[Company ID] AND l.[status] = 0)'
                                                          + CHAR(10)
                                                     WHEN N'USER'
                                                     THEN @sql + N', '
                                                          + QUOTENAME(@profield)
                                                          + N' =  (SELECT TOP 1 l.[id'
                                                          + @relatedprotable
                                                          + N'] '
                                                          + N'FROM [dbo].'
                                                          + QUOTENAME(@relatedprotable)
                                                          + N' AS l WHERE l.['
                                                          + LOWER(@relatedeasytable)
                                                          + N'_limeeasyid] = e.[User ID] AND l.[status] = 0)'
                                                          + CHAR(10)
                                                     ELSE @sql
                                                   END
                                END
                        
		
                FETCH NEXT FROM row_cursor INTO @protable, @relatedprotable,
                    @relatedeasytable, @profield
            END
				
        CLOSE row_cursor
        DEALLOCATE row_cursor    

        IF ( LEN(@sql) > 0 ) 
            BEGIN
                SELECT  @sql = N'UPDATE pro SET ' + RIGHT(@sql, LEN(@sql) - 1)
                        + N'FROM [dbo].' + QUOTENAME(@protable) + N' AS pro '
                        + CHAR(10)
                        + CASE @@easytable
                            WHEN N'ARCHIVE'
                            THEN N'INNER JOIN [dbo].[EASY__ARCHIVE] e ON pro.[archive_easytype] = e.[Type] AND pro.[archive_easykey1] = e.[Key 1] AND pro.[archive_easykey2]=e.[Key 2] '
                                 + CHAR(10) + N'WHERE pro.[status] = 0'
                            WHEN N'REFS'
                            THEN N'INNER JOIN [dbo].[EASY__REFS] e ON pro.[contact_limeeasyid] = e.[Company ID] AND pro.[refs_limeeasyid] = e.[Reference ID] '
                                 + CHAR(10) + N'WHERE pro.[status] = 0'
                            WHEN N'TODO'
                            THEN N'INNER JOIN [dbo].[EASY__TODO] e ON pro.[todo_easytype] = e.[Type] AND pro.[todo_easykey1] = e.[Key 1] AND pro.[todo_easykey2]=e.[Key 2] '
                                 + CHAR(10) + N'WHERE pro.[status] = 0'
                            WHEN N'TIME'
                            THEN N'INNER JOIN [dbo].[EASY__TIME] e ON pro.[contact_limeeasyid] = e.[Company ID] AND pro.[time_limeeasyid] = e.[Time ID] '
                                 + CHAR(10) + N'WHERE pro.[status] = 0'
                            ELSE N''
                          END
                    
                BEGIN TRY
                    EXEC sp_executesql @sql
                    --PRINT @sql
                        
                    SET @@errormessage = N''
                END TRY
                BEGIN CATCH
						--PRINT ERROR_MESSAGE()
                    SET @@errormessage = ERROR_MESSAGE()
                END CATCH
                    
            END
        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''
    END
GO


IF ( OBJECT_ID('csp_easytopro_updatesuperfields') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_updatesuperfields
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_updatesuperfields]
    (
      @@easytable NVARCHAR(64) ,
      @@errormessage NVARCHAR(2048) = N'' OUTPUT
         
        
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
            --DECLARATIONS

        DECLARE @sql NVARCHAR(MAX)
        DECLARE @protable NVARCHAR(64) 
        DECLARE @profield NVARCHAR(64) 
        DECLARE @profieldtype INT
        DECLARE @idfieldmapping INT
        DECLARE @easyfieldid NVARCHAR(64)
        DECLARE @easyfieldtype INT
        DECLARE @proposedvalue NVARCHAR(128)
        DECLARE @relatedtable NVARCHAR(64)
        DECLARE @idcategory INT
        DECLARE @defaultvalue NVARCHAR(128) 
        DECLARE @isrequired NVARCHAR(1)
            --DECLARE @relatedeasytable NVARCHAR(64)
        SELECT  @sql = N''
        SET @@errormessage = N''
        SELECT TOP 1
                @relatedtable = [protable]
        FROM    [dbo].[EASY__FIELDMAPPING]
        WHERE   [easytable] = N'USER'
                AND LEN(ISNULL([protable], N'')) > 0
                AND [transfertable] = 1


        DECLARE row_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
            SELECT  e.[idfieldmapping] ,
                    e.[protable] ,
                    e.[profieldname] ,
                    e.[easyprofieldtype] ,
                    e.[easyfieldid] ,
                    CASE WHEN LEN(ISNULL(e.proposedvalue, N'')) > 0
                         THEN REPLACE(e.[proposedvalue], N'''', N'''''')
                         ELSE ( SELECT  CASE WHEN [isnullable] = 1
                                                  AND [defaultvalue] = N''
                                             THEN CAST(N'NULL' AS NVARCHAR(128))
                                             ELSE CAST([defaultvalue] AS NVARCHAR(128))
                                        END
                                FROM    [dbo].[fieldcache] f
                                        INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                              AND t.[name] = e.protable
                                WHERE   f.[name] = e.[profieldname]
                              )
                    END ,
                    CASE WHEN EXISTS ( SELECT   f.[idfield]
                                       FROM     [dbo].[fieldcache] f
                                                INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                INNER JOIN [dbo].[attributedata] a ON a.[idrecord] = f.[idfield]
                                                              AND a.[owner] = N'field'
                                                              AND a.[name] = N'required'
                                       WHERE    e.[profieldname] = f.[name]
                                                AND e.[protable] = t.[name] )
                         THEN N'1'
                         ELSE N'0'
                    END ,
                    ( SELECT TOP 1
                                CASE WHEN [isnullable] = 1
                                          AND [defaultvalue] = N''
                                     THEN CAST(N'NULL' AS NVARCHAR(128))
                                     ELSE CAST([defaultvalue] AS NVARCHAR(128))
                                END
                      FROM      [dbo].[fieldcache] f
                                INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                      WHERE     e.[profieldname] = f.[name]
                                AND e.[protable] = t.[name]
                    ) ,
                    e.[easyfieldtype] ,
                    ( SELECT TOP 1
                                CAST(a.[value] AS INT)
                      FROM      [dbo].[fieldcache] f
                                INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                              AND t.[name] = e.[protable]
                                INNER JOIN [dbo].[attributedata] a ON f.[idfield] = a.[idrecord]
                                                              AND a.[owner] = N'field'
                                                              AND a.[name] = 'idcategory'
                      WHERE     f.[name] = e.[profieldname]
                    )
            FROM    [dbo].[EASY__FIELDMAPPING] e
            WHERE   e.[easytable] = @@easytable
                    AND e.[issuperfield] = 1
                    AND LEN(e.[protable]) > 0
                    AND e.[transfertable] = 1
                    AND e.[active] = 1
                        


        OPEN row_cursor
        FETCH NEXT FROM row_cursor INTO @idfieldmapping, @protable, @profield,
            @profieldtype, @easyfieldid, @proposedvalue, @isrequired,
            @defaultvalue, @easyfieldtype, @idcategory
        WHILE @@FETCH_STATUS = 0
            AND @@errormessage = N'' 
            BEGIN
                        
                    -- GET DATA TO FIELD
                            --DECLARE @sql NVARCHAR(MAX)
                SELECT  @sql = N''
                    
                SELECT  @sql = CASE WHEN ISNULL(@profieldtype, -1) IN ( 1, 12,
                                                              23 ) 	-- text, link, formated text
                                         THEN
						-- START SQL FOR TEXT
                                         N' UPDATE  pro
							SET   pro.' + QUOTENAME(@profield) + N'= 
									ISNULL(
										( SELECT TOP 1 ' + N'(CASE WHEN 1 = '
                                         + @isrequired
                                         + N' THEN CASE WHEN ed.[Data] =N'''
                                         + ISNULL(@defaultvalue, N'')
                                         + N''' THEN N'''
                                         + ISNULL(@proposedvalue, N'') + N''''
                                         + N' ELSE ed.[Data]  END ELSE ed.[Data] END ) '
                                         + CHAR(10)
                                         + N'FROM   [dbo].[EASY__DATA] ed 
										WHERE  ed.[Field ID] = '
                                         + CAST(ISNULL(@easyfieldid, -999) AS NVARCHAR(32))

						-- ADD TYPE SPECIFIC CRITERIA
                                         + CASE WHEN ( @easyfieldtype = 0 ) -- CONTACT (company)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid] '
                                                WHEN ( @easyfieldtype = 1 ) -- REFS (person)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[refs_limeeasyid] '
                                                WHEN ( @easyfieldtype = 2 ) -- PROJECT (project)
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid] '
                                                WHEN ( @easyfieldtype = 6 ) -- ARCHIVE (document) // CONTACT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                                WHEN ( @easyfieldtype = 7 ) -- ARCHIVE (document) // PROJECT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                           END
						
						-- END SQL
                                         + N' 
										)
									  ,  N''' + ISNULL(@proposedvalue, N'')
                                         + N''')'
                                    WHEN ( ISNULL(@profieldtype, -1) = 7 ) -- time
                                         THEN
						-- START SQL FOR TIME
                                         N' UPDATE  pro
							SET   pro.' + QUOTENAME(@profield) + N'= 
									ISNULL(( SELECT TOP 1 ISNULL(ed.[Data] , '
                                         + ISNULL(@proposedvalue, N'') + N')'
                                         + CHAR(10)
                                         + N'FROM   [dbo].[EASY__DATA] ed 
										WHERE  ed.[Field ID] = '
                                         + CAST(ISNULL(@easyfieldid, -999) AS NVARCHAR(32))
						
						-- ADD TYPE SPECIFIC CRITERIA		
                                         + CASE WHEN ( @easyfieldtype = 0 ) -- CONTACT (company)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid] '
                                                WHEN ( @easyfieldtype = 1 ) -- REFS (person)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[refs_limeeasyid] '
                                                WHEN ( @easyfieldtype = 2 ) -- PROJECT (project)
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid] '
                                                WHEN ( @easyfieldtype = 6 ) -- ARCHIVE (document) // CONTACT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                                WHEN ( @easyfieldtype = 7 ) -- ARCHIVE (document) // PROJECT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                           END	
                                       
						-- END SQL / CHECK IS DATE
                                         + N' AND ISDATE(ed.[Data]) = 1
										),  ' + ISNULL(@proposedvalue, N'')
                                         + N')'
                                    WHEN ( ISNULL(@profieldtype, -1) = 3 ) -- int
                                         THEN
						-- START SQL FOR INT
                                         N' UPDATE  pro
							SET   pro.' + QUOTENAME(@profield) + N'= 
									ISNULL(( SELECT TOP 1 ISNULL(ed.[Data], '
                                         + ISNULL(@proposedvalue, N'') + N')'
                                         + CHAR(10)
                                         + N'FROM   [dbo].[EASY__DATA] ed 
										WHERE  ed.[Field ID] = '
                                         + CAST(ISNULL(@easyfieldid, -999) AS NVARCHAR(32)) 
						
						-- ADD TYPE SPECIFIC CRITERIA		
                                         + CASE WHEN ( @easyfieldtype = 0 ) -- CONTACT (company)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid] '
                                                WHEN ( @easyfieldtype = 1 ) -- REFS (person)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[refs_limeeasyid] '
                                                WHEN ( @easyfieldtype = 2 ) -- PROJECT (project)
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid] '
                                                WHEN ( @easyfieldtype = 6 ) -- ARCHIVE (document) // CONTACT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                                WHEN ( @easyfieldtype = 7 ) -- ARCHIVE (document) // PROJECT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                           END	
						
						-- END SQL / CHECK IS INT
                                         + N'AND PATINDEX(N''[^-]%[^0-9]%'', ed.[Data]) = 0 
										),  ' + ISNULL(@proposedvalue, N'')
                                         + N')'
                                    WHEN ( ISNULL(@profieldtype, -1) = 13 ) -- yes/no
                                         THEN
						-- START SQL FOR YES/NO
                                         N' UPDATE  pro
							SET   pro.' + QUOTENAME(@profield) + N'= 
									ISNULL(
										( SELECT TOP 1 ISNULL(ed.[Data], '
                                         + ISNULL(@proposedvalue, N'') + N')'
                                         + CHAR(10)
                                         + N'FROM   [dbo].[EASY__DATA] ed 
										WHERE  ed.[Field ID] = '
                                         + CAST(ISNULL(@easyfieldid, -999) AS NVARCHAR(32))
						
						-- ADD TYPE SPECIFIC CRITERIA		
                                         + CASE WHEN ( @easyfieldtype = 0 ) -- CONTACT (company)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid] '
                                                WHEN ( @easyfieldtype = 1 ) -- REFS (person)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[refs_limeeasyid] '
                                                WHEN ( @easyfieldtype = 2 ) -- PROJECT (project)
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid] '
                                                WHEN ( @easyfieldtype = 6 ) -- ARCHIVE (document) // CONTACT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                                WHEN ( @easyfieldtype = 7 ) -- ARCHIVE (document) // PROJECT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                           END	
						-- END SQL
                                         + N'),  ' + ISNULL(@proposedvalue,
                                                            N'') + N')'
                                    WHEN ( ( ISNULL(@profieldtype, -1) = 16 )
                                           AND ( LEN(ISNULL(@relatedtable, N'')) > 0 )
                                         ) -- relation
                                         THEN
						-- START SQL FOR RELATION
                                         N' UPDATE  pro
							SET   pro.' + QUOTENAME(@profield) + N'= 
									( SELECT TOP 1 c.[id' + @relatedtable
                                         + N'] ' + CHAR(10)
                                         + N'FROM   [dbo].[EASY__DATA] ed 
										INNER JOIN [dbo].'
                                         + QUOTENAME(@relatedtable)
                                         + N' c ON (CAST(c.[user_limeeasyid] AS NVARCHAR(32)) = ed.[Data] AND c.[status] = 0)
										WHERE  ed.[Field ID] = '
                                         + CAST(ISNULL(@easyfieldid, -999) AS NVARCHAR(32)) 
						
						-- ADD TYPE SPECIFIC CRITERIA		
                                         + CASE WHEN ( @easyfieldtype = 0 ) -- CONTACT (company)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid] '
                                                WHEN ( @easyfieldtype = 1 ) -- REFS (person)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[refs_limeeasyid] '
                                                WHEN ( @easyfieldtype = 2 ) -- PROJECT (project)
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid] '
                                                WHEN ( @easyfieldtype = 6 ) -- ARCHIVE (document) // CONTACT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                                WHEN ( @easyfieldtype = 7 ) -- ARCHIVE (document) // PROJECT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                           END	
						
						-- END SQL / CHECK IS INT
                                         + N')'
                                    WHEN ( ISNULL(@profieldtype, -1) = 21 ) -- option
                                         THEN
						-- START SQL FOR OPTION
                                         N' UPDATE  pro
							SET   pro.' + QUOTENAME(@profield) + N'=   
									
										ISNULL( CAST( 
										
										
										
										( SELECT TOP 1 (CASE WHEN 1 = '
                                         + @isrequired + N' THEN CASE WHEN '
                                         + N' ISNULL([idstringlimepro],0) = '
                                         + ISNULL(@defaultvalue, N'0')
                                         + N' THEN ' + ISNULL(@proposedvalue,
                                                              N'NULL')
                                         + N' ELSE [idstringlimepro]  END ELSE [idstringlimepro] END ) 
     										FROM [dbo].[EASY__DATA] ed 
										INNER JOIN [dbo].[EASY__OPTIONMAPPING] o ON ed.[Data] = o.[easyvalue] AND o.[idcategorylimepro] = '
                                         + CAST(@idcategory AS NVARCHAR(32))
                                         + CHAR(10)
                                         + N'WHERE  ed.[Field ID] =  '
                                         + CAST(ISNULL(@easyfieldid, -999) AS NVARCHAR(32))
                                            
										
						-- ADD TYPE SPECIFIC CRITERIA		
                                         + CASE WHEN ( @easyfieldtype = 0 ) -- CONTACT (company)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid] '
                                                WHEN ( @easyfieldtype = 1 ) -- REFS (person)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[refs_limeeasyid] '
                                                WHEN ( @easyfieldtype = 2 ) -- PROJECT (project)
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid] '
                                                WHEN ( @easyfieldtype = 6 ) -- ARCHIVE (document) // CONTACT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                                WHEN ( @easyfieldtype = 7 ) -- ARCHIVE (document) // PROJECT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                           END	
						-- END SQL
                                         + N' ) AS NVARCHAR(32))' + N',  '
                                         + ISNULL(@proposedvalue, N'') + N')'
                                    WHEN ( ISNULL(@profieldtype, -1) = 20 ) -- set
                                         THEN N' UPDATE  pro
							SET   pro.' + QUOTENAME(@profield) + N'= 
									ISNULL(' + N'(CASE WHEN 1 = '
                                         + @isrequired + N' THEN CASE WHEN '
                                         + N'( SELECT CAST('';'' + CAST(o.[idstringlimepro] AS NVARCHAR(32)) AS NVARCHAR(MAX))
										FROM   [dbo].[EASY__DATA] ed 
										INNER JOIN [dbo].[EASY__OPTIONMAPPING] o ON o.[easyvalue] = ed.[Data] AND o.[idcategorylimepro] = '
                                         + CAST(@idcategory AS NVARCHAR(32))
                                         + CHAR(10)
                                         + N' WHERE  ed.[Field ID] = '
                                         + CAST(ISNULL(@easyfieldid, -999) AS NVARCHAR(32))
										
									-- ADD TYPE SPECIFIC CRITERIA		
                                         + CASE WHEN ( @easyfieldtype = 0 ) -- CONTACT (company)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid] '
                                                WHEN ( @easyfieldtype = 1 ) -- REFS (person)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[refs_limeeasyid] '
                                                WHEN ( @easyfieldtype = 2 ) -- PROJECT (project)
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid] '
                                                WHEN ( @easyfieldtype = 6 ) -- ARCHIVE (document) // CONTACT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                                WHEN ( @easyfieldtype = 7 ) -- ARCHIVE (document) // PROJECT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                           END	
						-- END SQL
                                         + CHAR(10)
                                         + N'ORDER BY o.[idstringlimepro]
										FOR XML PATH('''')
										) + N'';''' + N'='
                                         + CASE WHEN LEN(ISNULL(@defaultvalue,
                                                              N'')) > 0
                                                THEN N''';'
                                                     + ISNULL(@defaultvalue,
                                                              N'') + N';'')'
                                                ELSE N'N'''' '
                                           END + N' THEN '
                                         + CASE WHEN LEN(ISNULL(@proposedvalue,
                                                              N'')) > 0
                                                THEN N''';'
                                                     + ISNULL(@proposedvalue,
                                                              N'') + N';'')'
                                                ELSE N'N'''' '
                                           END + N' ELSE '
                                         + N'( SELECT CAST('';'' + CAST(o.[idstringlimepro] AS NVARCHAR(32)) AS NVARCHAR(MAX))
										FROM   [dbo].[EASY__DATA] ed 
										INNER JOIN [dbo].[EASY__OPTIONMAPPING] o ON o.[easyvalue] = ed.[Data] AND o.[idcategorylimepro] = '
                                         + CAST(@idcategory AS NVARCHAR(32))
                                         + CHAR(10)
                                         + N' WHERE  ed.[Field ID] = '
                                         + CAST(ISNULL(@easyfieldid, -999) AS NVARCHAR(32))
										
									-- ADD TYPE SPECIFIC CRITERIA		
                                         + CASE WHEN ( @easyfieldtype = 0 ) -- CONTACT (company)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid] '
                                                WHEN ( @easyfieldtype = 1 ) -- REFS (person)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[refs_limeeasyid] '
                                                WHEN ( @easyfieldtype = 2 ) -- PROJECT (project)
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid] '
                                                WHEN ( @easyfieldtype = 6 ) -- ARCHIVE (document) // CONTACT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                                WHEN ( @easyfieldtype = 7 ) -- ARCHIVE (document) // PROJECT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                           END	
						-- END SQL
                                         + CHAR(10)
                                         + N'ORDER BY o.[idstringlimepro]
										FOR XML PATH('''')
										) + N'';''' + N' END ELSE '
                                         + N'( SELECT CAST('';'' + CAST(o.[idstringlimepro] AS NVARCHAR(32)) AS NVARCHAR(MAX))
										FROM   [dbo].[EASY__DATA] ed 
										INNER JOIN [dbo].[EASY__OPTIONMAPPING] o ON o.[easyvalue] = ed.[Data] AND o.[idcategorylimepro] = '
                                         + CAST(@idcategory AS NVARCHAR(32))
                                         + CHAR(10)
                                         + N' WHERE  ed.[Field ID] = '
                                         + CAST(ISNULL(@easyfieldid, -999) AS NVARCHAR(32))
										
									-- ADD TYPE SPECIFIC CRITERIA		
                                         + CASE WHEN ( @easyfieldtype = 0 ) -- CONTACT (company)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid] '
                                                WHEN ( @easyfieldtype = 1 ) -- REFS (person)
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[refs_limeeasyid] '
                                                WHEN ( @easyfieldtype = 2 ) -- PROJECT (project)
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid] '
                                                WHEN ( @easyfieldtype = 6 ) -- ARCHIVE (document) // CONTACT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[contact_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                                WHEN ( @easyfieldtype = 7 ) -- ARCHIVE (document) // PROJECT ARCHIVE
                                                     THEN N' AND ed.[Key 1] = pro.[project_limeeasyid]
										AND ed.[Key 2] = pro.[archive_limeeasyid] '
                                           END	
						-- END SQL
                                         + CHAR(10)
                                         + N'ORDER BY o.[idstringlimepro]
										FOR XML PATH('''')
										) + N'';''' + N' END ) ' + N', '
                                         + CASE WHEN LEN(ISNULL(@proposedvalue,
                                                              N'')) > 0
                                                THEN N''';'
                                                     + ISNULL(@proposedvalue,
                                                              N'') + N';'')'
                                                ELSE N'N'''')'
                                           END
                               END
                    
                IF ( LEN(ISNULL(@sql, N'')) > 0 ) 
                    BEGIN
                        SELECT  @sql = @sql + N' FROM [dbo].'
                                + QUOTENAME(@protable) + N' AS pro 
								WHERE [status] = 0'
                                + CASE WHEN ( @easyfieldtype = 0 ) -- CONTACT (company)
                                            THEN CHAR(10)
                                            + N'AND  pro.[contact_limeeasyid] IS NOT NULL '
                                       WHEN ( @easyfieldtype = 1 ) -- REFS (person)
                                            THEN CHAR(10)
                                            + N'AND pro.[contact_limeeasyid] IS NOT NULL
										AND pro.[refs_limeeasyid] IS NOT NULL'
                                       WHEN ( @easyfieldtype = 2 ) -- PROJECT (project)
                                            THEN N'AND pro.[project_limeeasyid] IS NOT NULL'
                                       WHEN ( @easyfieldtype = 6 ) -- ARCHIVE (document) // CONTACT ARCHIVE
                                            THEN CHAR(10)
                                            + N'AND pro.[contact_limeeasyid] IS NOT NULL
										AND pro.[archive_limeeasyid] IS NOT NULL '
                                       WHEN ( @easyfieldtype = 7 ) -- ARCHIVE (document) // PROJECT ARCHIVE
                                            THEN CHAR(10)
                                            + N'AND pro.[project_limeeasyid] IS NOT NULL
										AND pro.[archive_limeeasyid] IS NOT NULL '
                                  END
                    END
								
                            
                BEGIN TRY
                    EXEC sp_executesql @sql
                        
                        --PRINT @sql + CHAR(10) + REPLICATE(N'-', 20) + CHAR(10)
                        
                    SET @@errormessage = N''
                END TRY
                BEGIN CATCH
                        --PRINT ERROR_MESSAGE()
                    SET @@errormessage = ERROR_MESSAGE()
                END CATCH
                    
                    
                        
		
                FETCH NEXT FROM row_cursor INTO @idfieldmapping, @protable,
                    @profield, @profieldtype, @easyfieldid, @proposedvalue,
                    @isrequired, @defaultvalue, @easyfieldtype, @idcategory
            END
				
        CLOSE row_cursor
        DEALLOCATE row_cursor    

                    

        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''
    END
GO


IF ( OBJECT_ID('csp_easytopro_update_easy__fieldmapping') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_update_easy__fieldmapping
	END
GO


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
GO


IF ( OBJECT_ID('csp_easytopro_update_easy__optionmapping') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_update_easy__optionmapping
	END
GO


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
GO


IF ( OBJECT_ID('csp_easytopro_user') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_user
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_user]
    @@xml AS NVARCHAR(MAX) ,
    @@rebuildtable AS BIT
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @iXML INT


        IF ( @@rebuildtable = 1 ) 
            BEGIN
       
                IF EXISTS ( SELECT  *
                            FROM    sys.objects
                            WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__USER]')
                                    AND type IN ( N'U' ) ) 
                    DROP TABLE [dbo].[EASY__USER] 

                CREATE TABLE [dbo].[EASY__USER]
                    (
                      [User ID] SMALLINT NOT NULL ,
                      [Name] NVARCHAR(48) ,
                      [firstname] NVARCHAR(32) ,
                      [lastname] NVARCHAR(50) ,
                      [Active] SMALLINT ,
                      [Signature] NVARCHAR(8)
                    )
            END

        EXEC sp_xml_preparedocument @iXML OUTPUT, @@xml

        INSERT  INTO [dbo].[EASY__USER]
                ( [User ID] ,
                  [Name] ,
                  [firstname] ,
                  [lastname] ,
                  [Active] ,
                  [Signature]
                )
                SELECT  [userid] ,
                        [name] ,
                        ISNULL(LTRIM(RTRIM(LEFT([name],
                                                COALESCE(NULLIF(CHARINDEX(N' ',
                                                              [name]), 0) - 1,
                                                         LEN([name]))))), N'') , -- [firstname] 
                        ISNULL(LTRIM(RTRIM(RIGHT([name],
                                                 LEN([name]) - LEN(LEFT([name],
                                                              COALESCE(NULLIF(CHARINDEX(N' ',
                                                              [name]), 0) - 1,
                                                              LEN([name]))))))),
                               N'') , -- [lastname] 
                        [active] ,
                        [signature]
                FROM    OPENXML(@iXML, '/data/row')
	WITH (	
			    [userid] SMALLINT,  
			    [name] NVARCHAR(48),  
			    [active] SMALLINT,  
			    [signature] NVARCHAR(8)        
		  ) 
	

        EXECUTE sp_xml_removedocument @iXML
    END
GO


IF ( OBJECT_ID('csp_easytopro_validatetable') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_validatetable
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_validatetable]
   (
      @@tablename NVARCHAR(64) ,
      @@message NVARCHAR(2048) = N'' OUTPUT ,
      @@validationerror INT = 0 OUTPUT
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;


        DECLARE @status INT

        SET @@message = N''

        SELECT  @status = [status]
        FROM    [dbo].[tableview]
        WHERE   [name] = @@tablename

        IF ( @status IS NULL ) 
            BEGIN 
                SET @@message = N'New table will be created'
                SET @@validationerror = NULL
            END
        ELSE 
            IF ( @status = 2 ) 
                BEGIN
                    SET @@message = N'Existing table'
                    SET @@validationerror = 0
                END
            ELSE 
                BEGIN
                    SET @@message = N'ERROR: Tablename is already used by a system table'
                    SET @@validationerror = 1
                END

        IF (@@validationerror IS NULL) 
            BEGIN
                BEGIN TRY
                    EXECUTE [dbo].[lsp_verifytablename] @@name = @@tablename -- nvarchar(64)
                    SET @@validationerror = 0
                END TRY
                BEGIN CATCH
                    SET @@message = ERROR_MESSAGE()
                    SET @@validationerror = 1
                END CATCH	
            END

    END
GO


IF ( OBJECT_ID('csp_easytopro_validate_easydata') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_validate_easydata
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_validate_easydata]
    (

      @@errormessage NVARCHAR(2048) OUTPUT
        
    )
AS 
    BEGIN
    -- FLAG_EXTERNALACCESS --
    SET @@errormessage = N''
    
    DECLARE @data NVARCHAR(255)
    DECLARE @fieldname NVARCHAR(48)
    DECLARE @datatype INT
    DECLARE @datatypedata INT
    DECLARE @fieldid INT
    DECLARE @key1 INT
    DECLARE @key2 INT
    
    
    --Begin: Validate integers and date fields
    DECLARE data_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
        SELECT e.Data, f.[Field name], f.[Data type], f.[Data type data]
			FROM EASY__DATA e INNER JOIN EASY__FIELD f 
				ON e.[Field ID]=f.[Field ID] 
			WHERE f.[Data type data] = 32 --Textfield with integers
				OR f.[Data type data] = 16 --Textfield with date
				
	OPEN data_cursor
        FETCH NEXT FROM data_cursor INTO @data, @fieldname, @datatype, @datatypedata
        WHILE @@FETCH_STATUS = 0
			AND @@errormessage = N'' 
            BEGIN
				IF @datatypedata = 32 --Textfield with integers
				BEGIN
					-- Verify data is an integer
					IF ISNULL(PATINDEX(N'[^-]%[^0-9]%', @data),0) > 0
						SET @@errormessage = N'Integer field ''' + @fieldname + ''' contains data that is not an integer.'
				END
				ELSE IF @datatypedata = 16 --Textfield with date
				BEGIN
					IF ISDATE(@data) = 0
						SET @@errormessage = N'Date field ''' + @fieldname + ''' contains data that is not a valid date.'
				END
				
                FETCH NEXT FROM data_cursor INTO @data, @fieldname, @datatype, @datatypedata
            END
        CLOSE data_cursor
        DEALLOCATE data_cursor
	--End: Validate integers and date fields      
        
    --Begin: Validate set fields for company and project    
    DECLARE data_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
        SELECT DISTINCT e.[Field ID], e.[Key 1]
			FROM EASY__DATA e INNER JOIN EASY__FIELD f 
				ON e.[Field ID]=f.[Field ID] 
			WHERE f.[Data type] = 5 --Set fields
				AND (f.[Field type] = 0 OR f.[Field type] = 2) --Field on company or project cards

	OPEN data_cursor
        FETCH NEXT FROM data_cursor INTO @fieldid, @key1
        WHILE @@FETCH_STATUS = 0
			AND @@errormessage = N''
            BEGIN
				--Check if more than 23 options are selected
				IF (SELECT COUNT(Data) FROM EASY__DATA WHERE [Field ID] = @fieldid AND [Key 1] = @key1) > 23
				BEGIN
					SET @@errormessage =  N'Set field ''' + (SELECT [Field name] FROM EASY__FIELD WHERE [Field ID] = @fieldid) + ''' has more than 23 options selected, which is not allowed in LIME Pro.'
				END
                FETCH NEXT FROM data_cursor INTO @fieldid, @key1
            END
        CLOSE data_cursor
        DEALLOCATE data_cursor
    --End: Validate set fields for company and project
    
    --Begin: Validate set fields for person and documents
    DECLARE data_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
        SELECT DISTINCT e.[Field ID], e.[Key 1], e.[Key 2]
			FROM EASY__DATA e INNER JOIN EASY__FIELD f 
				ON e.[Field ID]=f.[Field ID] 
			WHERE f.[Data type] = 5 --Set fields
				AND (f.[Field type] = 1 OR f.[Field type] = 6 OR f.[Field type] = 7) --Field on person or document cards

	OPEN data_cursor
        FETCH NEXT FROM data_cursor INTO @fieldid, @key1, @key2
        WHILE @@FETCH_STATUS = 0
			AND @@errormessage = N''
            BEGIN
				--Check if more than 23 options are selected
				IF (SELECT COUNT(Data) FROM EASY__DATA WHERE [Field ID] = @fieldid AND [Key 1] = @key1) > 23
				BEGIN
					SET @@errormessage =  N'Set field ''' + (SELECT [Field name] FROM EASY__FIELD WHERE [Field ID] = @fieldid) + ''' has more than 23 options selected, which is not allowed in LIME Pro.'
				END
                FETCH NEXT FROM data_cursor INTO @fieldid, @key1, @key2
            END
        CLOSE data_cursor
        DEALLOCATE data_cursor
    --End: Validate set fields for person and documents
    
       
    END
GO


IF ( OBJECT_ID('csp_easytopro_validate_field') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_validate_field
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_validate_field]
    (
      @@idfieldmapping INT = NULL 
    )
AS 
    BEGIN
		-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
	-- Declarations



        DECLARE @tempwarnings TABLE
            (
              [idfieldmapping] INT ,
              [easytable] NVARCHAR(64) ,
              [easyfieldname] NVARCHAR(64) ,
              [protable] NVARCHAR(64) ,
              [issuperfield] INT ,
              [easyfieldid] NVARCHAR(64) ,
              [profieldname] NVARCHAR(64) ,
              [easyprofieldtype] INT ,
              [active] INT ,
              [duplicatefieldname] NVARCHAR(512) ,
              [duplicateeasyfieldid] NVARCHAR(512) ,
              [invalidcharactersfieldname] NVARCHAR(512) ,
              [invalidcharacterslocalname] NVARCHAR(512) ,
              [validatesystemfields] NVARCHAR(512) ,
              [proposedvalueforrequired] NVARCHAR(512) ,
              [validate_sv] NVARCHAR(512) ,
              [validate_en_us] NVARCHAR(512) ,
              [validate_no] NVARCHAR(512) ,
              [validate_fi] NVARCHAR(512) ,
              [validate_da] NVARCHAR(512) ,
              [validatefieldtype] NVARCHAR(512) ,
              [validatefieldlength] NVARCHAR(512)
            )
							
        INSERT  INTO @tempwarnings
                ( [idfieldmapping] ,
                  [easytable] ,
                  [easyfieldname] ,
                  [protable] ,
                  [issuperfield] ,
                  [easyfieldid] ,
                  [profieldname] ,
                  [easyprofieldtype] ,
                  [active] ,
                  duplicatefieldname ,
                  duplicateeasyfieldid ,
                  invalidcharactersfieldname ,
                  invalidcharacterslocalname ,
                  validatesystemfields ,
                  proposedvalueforrequired ,
                  validate_sv ,
                  validate_en_us ,
                  validate_no ,
                  validate_fi ,
                  validate_da ,
                  validatefieldtype ,
                  [validatefieldlength]
									 
                )
                SELECT  e.[idfieldmapping] ,
                        e.[easytable] ,
                        e.[easyfieldname] ,
                        e.[protable] ,
                        e.[issuperfield] ,
                        e.[easyfieldid] ,
                        e.[profieldname] ,
                        e.[easyprofieldtype] ,
                        e.[active] ,
                        CASE WHEN EXISTS ( SELECT   e2.[profieldname]
                                           FROM     [dbo].[EASY__FIELDMAPPING] e2
                                           WHERE    e2.[protable] = e.[protable]
                                                    AND e2.[profieldname] = e.[profieldname]
                                                    AND e2.[protable] = e.[protable]
                                                    AND e2.[idfieldmapping] != e.[idfieldmapping]
                                                    AND e2.[active] = 1
                                                    AND l.[fieldname] IS NULL )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Duplicate of Pro Field name for non existing fields.',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             WHEN EXISTS ( SELECT   e2.[profieldname]
                                           FROM     [dbo].[EASY__FIELDMAPPING] e2
                                           WHERE    e2.[protable] = e.[protable]
                                                    AND e2.[profieldname] = e.[profieldname]
                                                    AND e2.[protable] = e.[protable]
                                                    AND e2.[idfieldmapping] != e.[idfieldmapping]
                                                    AND e2.[active] = 1
                                                    AND l.[fieldname] IS NOT NULL
                                                    AND ((e.[easyfieldtype] <> 6
                                                    AND e.[easyfieldtype] <> 7 )
                                                    OR e.[easyfieldtype] = e2.[easyfieldtype]))
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Existing Pro Field mapped more than once.',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             ELSE N''
                        END AS [duplicatefieldname] ,
                        CASE WHEN EXISTS ( SELECT   e2.[easyfieldid]
                                           FROM     [dbo].[EASY__FIELDMAPPING] e2
                                           WHERE    e2.[easyfieldid] = e.[easyfieldid]
                                                    AND e2.[idfieldmapping] != e.[idfieldmapping]
                                                    AND e2.[active] = 1 )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Duplicate in Easy Field ID.',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             ELSE N''
                        END AS [duplicateeasyfieldid] ,
                        --CASE WHEN ( PATINDEX('%[^abcdefghijklmnopqrstuvwxyz0-9_]%',
                        --                     ( e.[profieldname] COLLATE Finnish_Swedish_CS_AS )) > 0 )
                        --     THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Pro Field name can only contain characters a-z, 0-9 and _.', N'#1#',e.[protable]),N'#2#',e.[profieldname])
                        --     ELSE N''
                        --END AS [invalidcharactersfieldname] ,
                        N'' AS [invalidcharactersfieldname] ,
                        CASE WHEN ( CHARINDEX(N'.',
                                              e.[localname_sv]
                                              + e.[localname_en_us]
                                              + e.[localname_no]
                                              + e.[localname_fi]
                                              + e.[localname_da]) > 0 )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Local name canÂ´t contain character ''.''',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             ELSE N''
                        END AS [invalidcharacterslocalname] ,
                        CASE WHEN e.[profieldname] IN ( N'id' + e.[protable],
                                                        N'status',
                                                        N'createduser',
                                                        N'createdtime',
                                                        N'updateduser',
                                                        'timestamp',
                                                        N'rowguid' )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': The name is already taken by a system field',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             ELSE N''
                        END AS [validatesystemfields] ,
                        CASE WHEN LEN(ISNULL(e.[proposedvalue], N'')) > 0
                                  AND l.[fieldname] IS NULL
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Proposed value is only allowed when matching existing field',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             
                             WHEN ISNULL(e.[proposedvalue], N'') != N''
                                  AND NOT EXISTS ( SELECT   a.[idattributedata]
                                                   FROM     [dbo].[attributedata] a
                                                            INNER JOIN [dbo].[fieldcache] f ON f.[idfield] = a.[idrecord]
                                                              AND f.[name] = e.[profieldname]
                                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                              AND t.[name] = e.[protable]
                                                   WHERE    a.[owner] = N'field'
                                                            AND a.[name] = 'required' )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Proposed value is only allowed for required fields.',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             
                             WHEN ISNULL(e.[proposedvalue], N'') = N''
                                  AND EXISTS ( SELECT   a.[idattributedata]
                                               FROM     [dbo].[attributedata] a
                                                        INNER JOIN [dbo].[fieldcache] f ON f.[idfield] = a.[idrecord]
                                                              AND f.[name] = e.[profieldname]
                                                        INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                              AND t.[name] = e.[protable]
                                               WHERE    a.[owner] = N'field'
                                                        AND a.[name] = 'required' )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Mapped to required existing field and a proposed value is not supplied.',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             
                             WHEN ISNULL(e.[proposedvalue], N'') != N''
                                  AND PATINDEX(N'%[^0-9]%',
                                               ISNULL(e.[proposedvalue], N'')) > 0
                                  AND e.[easyprofieldtype] IN ( 20, 21 )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Mapped to required existing option or set field and proposed value is not numeric.',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                                          
                             WHEN ISNULL(e.[proposedvalue], N'') != N''
                                  AND PATINDEX(N'%[^0-9]%',
                                               ISNULL(e.[proposedvalue], N'')) = 0
                                  AND e.[easyprofieldtype] IN ( 20, 21 )
                                  AND NOT EXISTS ( SELECT   [idstring]
                                                   FROM     [dbo].[string]
                                                   WHERE    [idcategory] = ( SELECT TOP 1
                                                              CAST([value] AS INT)
                                                              FROM
                                                              [dbo].[attributedata] a
                                                              INNER JOIN [dbo].[fieldcache] f ON f.[idfield] = a.[idrecord]
                                                              AND f.[name] = e.[profieldname]
                                                              INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                              AND t.[name] = e.[protable]
                                                              WHERE
                                                              a.[owner] = N'field'
                                                              AND a.[name] = 'idcategory'
                                                              )
                                                            AND CAST([idstring] AS NVARCHAR(32)) = ISNULL(e.[proposedvalue],
                                                              N'') )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Proposed value is not a valid idstring',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             
                             WHEN ISNULL(e.[proposedvalue], N'') != N''
                                  AND PATINDEX(N'%[^0-9]%',
                                               ISNULL(e.[proposedvalue], N'')) = 0
                                  AND e.[easyprofieldtype] IN ( 20, 21 )
                                  AND  EXISTS ( SELECT   f.[idfield]
                                       FROM     [dbo].[fieldcache] f
                                                INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                INNER JOIN [dbo].[attributedata] a ON a.[idrecord] = f.[idfield]
                                                              AND a.[owner] = N'field'
                                                              AND a.[name] = N'required'
                                       WHERE    e.[profieldname] = f.[name]
                                                AND e.[protable] = t.[name]
                                                AND f.[defaultvalue] = e.[proposedvalue] )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Proposed value is default value for a required field',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             
                             WHEN e.[easyprofieldtype] IN ( 3, 7, 13 )
                                  AND LEN(e.[proposedvalue]) > 0
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Proposed value is not allowed for fieldtypes int, date and yes/no',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             ELSE N''
                        END AS [proposedvalueforrequired] ,
                        CASE WHEN ( ( e.localname_sv IN (
                                      SELECT    s.[sv]
                                      FROM      [dbo].[fieldcache] f
                                                INNER JOIN dbo.[table] t ON t.idtable = f.idtable
                                                INNER JOIN [dbo].[string] s ON s.[idstring] = f.[localname]
                                      WHERE     t.[name] = e.protable
                                                AND f.[name] != e.[profieldname] ) )
                                    AND l.[fieldname] IS NULL
                                  )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Localname_SV is already used by another field',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             ELSE N''
                        END AS [validate_sv] ,
                        CASE WHEN ( ( e.localname_en_us IN (
                                      SELECT    s.[en_us]
                                      FROM      [dbo].[fieldcache] f
                                                INNER JOIN dbo.[table] t ON t.idtable = f.idtable
                                                INNER JOIN [dbo].[string] s ON s.[idstring] = f.[localname]
                                      WHERE     t.[name] = e.protable
                                                AND f.[name] != e.[profieldname] ) )
                                    AND l.[fieldname] IS NULL
                                  )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Localname_EN_US is already used by another field',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             ELSE N''
                        END AS [validate_en_us] ,
                        CASE WHEN ( ( e.localname_no IN (
                                      SELECT    s.[no]
                                      FROM      [dbo].[fieldcache] f
                                                INNER JOIN dbo.[table] t ON t.idtable = f.idtable
                                                INNER JOIN [dbo].[string] s ON s.[idstring] = f.[localname]
                                      WHERE     t.[name] = e.protable
                                                AND f.[name] != e.[profieldname] ) )
                                    AND l.[fieldname] IS NULL
                                  )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Localname_NO is already used by another field',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             ELSE N''
                        END AS [validate_no] ,
                        CASE WHEN ( ( e.localname_fi IN (
                                      SELECT    s.[fi]
                                      FROM      [dbo].[fieldcache] f
                                                INNER JOIN dbo.[table] t ON t.idtable = f.idtable
                                                INNER JOIN [dbo].[string] s ON s.[idstring] = f.[localname]
                                      WHERE     t.[name] = e.protable
                                                AND f.[name] != e.[profieldname] ) )
                                    AND l.[fieldname] IS NULL
                                  )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Localname_FI is already used by another field',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             ELSE N''
                        END AS [validate_fi] ,
                        CASE WHEN ( ( e.localname_da IN (
                                      SELECT    s.[da]
                                      FROM      [dbo].[fieldcache] f
                                                INNER JOIN dbo.[table] t ON t.idtable = f.idtable
                                                INNER JOIN [dbo].[string] s ON s.[idstring] = f.[localname]
                                      WHERE     t.[name] = e.protable
                                                AND f.[name] != e.[profieldname] ) )
                                    AND l.[fieldname] IS NULL
                                  )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Localname_DA is already used by another field',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             ELSE N''
                        END AS [validate_da] ,
                        CASE WHEN l.[fieldtype] IS NULL THEN N''
                             WHEN e.[easyprofieldtype] IN ( 1, 12, 23 )
                                  AND l.[fieldtype] NOT IN ( 1, 12, 23 )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Text field in Easy. Needs to be mapped to a Field of type: Text, Link or Formatted text field',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             WHEN e.[easyprofieldtype] = 3
                                  AND l.[fieldtype] NOT IN ( 3, 4 )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Integer field in Easy. Needs to be mapped to a Field of type: Integer or Decimal(FLOAT)',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             WHEN e.[easyprofieldtype] != l.[fieldtype]
                                  AND NOT ( ( e.[easyprofieldtype] IN ( 1, 12,
                                                              23 )
                                              AND l.[fieldtype] IN ( 1, 12, 23 )
                                            )
                                            OR ( e.[easyprofieldtype] = 3
                                                 AND l.[fieldtype] IN ( 3, 4 )
                                               )
                                          )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Missmatch in Fieldtype',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             WHEN e.[easyprofieldtype] = 16
                                  AND e.[issuperfield] = 1
                                  AND N'coworker' != ( SELECT TOP 1
                                                              [relatedtable]
                                                       FROM   [dbo].[relationfieldview]
                                                       WHERE  [idfield] = l.[idfield]
                                                     )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Only relations to coworker-table are allowed',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             WHEN e.[easyprofieldtype] = 16
                                  AND e.[issuperfield] = 2
                                  AND ISNULL(( SELECT TOP 1
                                                        e2.[protable]
                                               FROM     [dbo].[EASY__FIELDMAPPING] e2
                                               WHERE    e2.[easytable] = e.[relatedeasytable]
                                                        AND LEN(e2.[protable]) > 0
                                               ORDER BY e2.[idfieldmapping]
                                             ), N'') != ( SELECT TOP 1
                                                              [relatedtable]
                                                          FROM
                                                              [dbo].[relationfieldview]
                                                          WHERE
                                                              [idfield] = l.[idfield]
                                                        )
                             THEN REPLACE(REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Only relations to ''#3#-table'' are allowed',
                                                          N'#1#', e.[protable]),
                                                  N'#2#', e.[profieldname]),
                                          N'#3#',
                                          ISNULL(( SELECT TOP 1
                                                            e2.[protable]
                                                   FROM     [dbo].[EASY__FIELDMAPPING] e2
                                                   WHERE    e2.[easytable] = e.[relatedeasytable]
                                                            AND LEN(e2.[protable]) > 0
                                                   ORDER BY e2.[idfieldmapping]
                                                 ), N''))
                             ELSE N''
                        END AS [validatefieldtype] ,
                        N'' AS [validatefieldlength]
                FROM    [dbo].[EASY__FIELDMAPPING] e
                        LEFT JOIN ( SELECT  f.[name] AS [fieldname] ,
                                            t.[name] AS [tablename] ,
                                            f.[fieldtype] AS [fieldtype] ,
                                            f.[idfield] AS [idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                  ) l ON l.[fieldname] = e.[profieldname]
                                         AND l.[tablename] = e.[protable]
                WHERE   e.[active] = 1
                        AND e.[transfertable] = 1
                        AND ( ( e.[idfieldmapping] = @@idfieldmapping )
                              OR ( @@idfieldmapping IS NULL )
                            )
                       

        DECLARE @idfieldmapping INT
        DECLARE @easyfieldid NVARCHAR(64)
        DECLARE @easyprofieldtype INT
        DECLARE @easytable NVARCHAR(64)
        DECLARE @easyfieldname NVARCHAR(64) 
        DECLARE @protable NVARCHAR(64)
        DECLARE @profield NVARCHAR(64)
        DECLARE @issuperfield INT
        DECLARE @easymaxlen INT
        DECLARE @sql NVARCHAR(MAX)
        DECLARE @messagefieldlength NVARCHAR(512)
        DECLARE @invalidcharactersfieldname NVARCHAR(512)
                       
        DECLARE row_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
            SELECT  [idfieldmapping] ,
                    [easyfieldid] ,
                    [easytable] ,
                    [easyfieldname] ,
                    [easyprofieldtype] ,
                    [issuperfield] ,
                    [protable] ,
                    [profieldname]
            FROM    @tempwarnings
		

        OPEN row_cursor
        FETCH NEXT FROM row_cursor INTO @idfieldmapping, @easyfieldid,
            @easytable, @easyfieldname, @easyprofieldtype, @issuperfield,
            @protable, @profield
        WHILE @@FETCH_STATUS = 0 
            BEGIN
				
                SET @messagefieldlength = N''
                SET @invalidcharactersfieldname = N''
				
                IF ( @easyprofieldtype IN ( 1, 12, 23 )
                     AND @easytable != N'HISTORY'
                   ) 
                    BEGIN
				
                        IF ( @issuperfield = 0 ) 
                            BEGIN
						
                                SET @sql = N'SELECT  @easymaxlenOUT = MAX(LEN('
                                    + QUOTENAME(@easyfieldname) + N')) 
											 FROM [dbo].[EASY__' + @easytable
                                    + N']'
							
                            END
                        ELSE 
                            BEGIN
						
                                SET @sql = N'SELECT @easymaxlenOUT =
                                                            MAX(LEN([Data]))
                                                            FROM [dbo].[EASY__DATA]
                                                            WHERE [Field ID] ='
                                    + @easyfieldid
							
                            END
				
           
                        BEGIN TRY
                            EXEC sp_executesql @sql,
                                N'@easymaxlenOUT INT OUTPUT',
                                @easymaxlenOUT = @easymaxlen OUTPUT
				
				
						 
				
                            SELECT  @messagefieldlength = CASE
                                                              WHEN ( @easymaxlen > f.[length] )
                                                              THEN REPLACE(REPLACE(REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Length of field in LIME is #3# and Easy contains data of length #4#',
                                                              N'#1#',
                                                              @protable),
                                                              N'#2#',
                                                              @profield),
                                                              N'#3#',
                                                              f.[length]),
                                                              N'#4#',
                                                              @easymaxlen)
                                                              ELSE N''
                                                          END
                            FROM    [dbo].[fieldcache] f
                                    INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                            WHERE   f.[name] = @profield
                                    AND t.[name] = @protable
                                            
                        END TRY
                        BEGIN CATCH
                            SET @messagefieldlength = LEFT(ERROR_MESSAGE(),
                                                           512)
                        END CATCH
						
                    END
                ELSE 
                    IF ( @easyprofieldtype IN ( 1, 12, 23 )
                         AND @easytable = N'HISTORY'
                         AND @easyfieldid = N'history_note'
                       ) 
                        BEGIN
                            SELECT  @messagefieldlength = [dbo].[cfn_easytopro_validatehistorylength](@protable,
                                                              @profield)
                                                              
                        END
                    
                BEGIN TRY
                    EXEC [dbo].[lsp_verifyname] @@name = @profield
                    SET @invalidcharactersfieldname = N''
                END TRY
                BEGIN CATCH
                    SET @invalidcharactersfieldname = ERROR_MESSAGE()
                END CATCH
						
                IF ( ( LEN(ISNULL(@messagefieldlength, N'')) ) > 0
                     OR ( LEN(ISNULL(@invalidcharactersfieldname, N'')) > 0 )
                   ) 
                    BEGIN
                        UPDATE  @tempwarnings
                        SET     [validatefieldlength] = ISNULL(@messagefieldlength,
                                                              N'') ,
                                [invalidcharactersfieldname] = ISNULL(@invalidcharactersfieldname,
                                                              N'')
                        WHERE   [idfieldmapping] = @idfieldmapping
                    END
		
		
                FETCH NEXT FROM row_cursor INTO @idfieldmapping, @easyfieldid,
                    @easytable, @easyfieldname, @easyprofieldtype,
                    @issuperfield, @protable, @profield
            END
				
        CLOSE row_cursor
        DEALLOCATE row_cursor    
                       
         --SELECT  @xmltext = N'<warnings>'
         --       + CAST (ISNULL((    
        SELECT  *
        FROM    @tempwarnings AS [warning]
        ORDER BY [protable] ,
                [profieldname]
        FOR     XML AUTO
        --), N'') AS NVARCHAR(MAX)) + N'</warnings>'          
                
        --SELECT CAST(@xmltext AS XML)       
                       
    END
GO


IF ( OBJECT_ID('csp_easytopro_validate_option') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_validate_option
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_validate_option]
    (
      @@idfieldmapping INT = NULL 
    )
AS 
    BEGIN
		-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
	-- Declarations

         
        SELECT  eo.[fieldmapping] ,
                eo.[idoptionmapping] ,
                REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': LIME Easy option ''#3#'' is linked to non existing LIME Pro option. idcategorylime: #4#, idstring: #5#',
                                                        N'#1#',
                                                        ISNULL(ef.[protable],
                                                              N'')), N'#2#',
                                                ISNULL(ef.[profieldname], N'')),
                                        N'#3#', ISNULL(eo.[easyvalue], N'')),
                                N'#4#',
                                ISNULL(CAST(eo.[idcategorylimepro] AS NVARCHAR(32)),
                                       N'')), N'#5#',
                        ISNULL(CAST(eo.[idstringlimepro] AS NVARCHAR(32)), N'')) AS [validationmessage]
        FROM    [dbo].[EASY__OPTIONMAPPING] eo
                LEFT JOIN [dbo].[EASY__FIELDMAPPING] ef ON ef.[idfieldmapping] = eo.[fieldmapping]
                LEFT JOIN ( SELECT  f.[name] AS [fieldname] ,
                                    t.[name] AS [tablename] ,
                                    a.[value] AS [idcategory] ,
                                    s.[idstring] AS [idstring]
                            FROM    [dbo].[fieldcache] f
                                    INNER JOIN [dbo].[table] t ON f.[idtable] = t.[idtable]
                                    INNER JOIN [dbo].[attributedata] a ON a.[idrecord] = f.[idfield]
                                                              AND a.[owner] = N'field'
                                                              AND a.[name] = N'idcategory'
                                    INNER JOIN [dbo].[string] s ON s.[idcategory] = a.[value]
                          ) m ON m.[fieldname] = ISNULL(ef.[profieldname], N'')
                                 AND m.[tablename] = ISNULL(ef.[protable], N'')
                                 AND m.[idcategory] = ISNULL(eo.[idcategorylimepro],
                                                             0)
                                 AND ISNULL(eo.[idstringlimepro], 0) = m.[idstring]
        WHERE   ISNULL(eo.[idstringlimepro], 0) > 0
                AND m.[idstring] IS NULL
                AND ( ( eo.[fieldmapping] = @@idfieldmapping )
                      OR ( @@idfieldmapping IS NULL )
                    )
        FOR     XML AUTO
        
        
    END 
GO


IF ( OBJECT_ID('csp_easytopro_validate_requiredfields') > 0 )
	BEGIN
		DROP PROCEDURE csp_easytopro_validate_requiredfields
	END
GO


CREATE PROCEDURE [dbo].[csp_easytopro_validate_requiredfields]
    (
      @@easytable NVARCHAR(64) = NULL 
    )
AS 
    BEGIN
		-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
	-- Declarations


        SELECT  ISNULL(t.[name], N'') AS [tablename] ,
                ISNULL(f.[name], N'') AS [fieldname]
        FROM    [dbo].[fieldcache] f
                INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                INNER JOIN [dbo].[attributedata] a ON a.[idrecord] = f.[idfield]
                                                      AND a.[owner] = N'field'
                                                      AND a.[name] = N'required'
                LEFT JOIN [dbo].[EASY__FIELDMAPPING] e ON ( e.[profieldname] = f.[name]
                                                            AND e.[protable] = t.[name]
                                                            AND LEN(ISNULL([proposedvalue],
                                                              N'')) > 0
                                                            AND e.[active] = 1
                                                          )
        WHERE   t.[name] IN ( SELECT DISTINCT
                                        [protable]
                              FROM      [dbo].[EASY__FIELDMAPPING]
                              WHERE     [transfertable] = 1
                                        AND ( ( [easytable] = @@easytable )
                                              OR ( @@easytable IS NULL )
                                            ) )
                AND e.[idfieldmapping] IS NULL
        FOR     XML AUTO
        
    END
GO


