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