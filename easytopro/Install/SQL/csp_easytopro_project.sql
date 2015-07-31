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