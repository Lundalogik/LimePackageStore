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