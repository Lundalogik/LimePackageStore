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