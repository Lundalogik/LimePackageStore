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