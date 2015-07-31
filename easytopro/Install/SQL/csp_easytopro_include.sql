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