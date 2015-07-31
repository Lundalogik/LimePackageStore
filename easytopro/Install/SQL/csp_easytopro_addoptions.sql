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