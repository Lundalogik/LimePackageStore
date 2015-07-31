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