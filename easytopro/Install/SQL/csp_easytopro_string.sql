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