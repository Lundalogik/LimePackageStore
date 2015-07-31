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