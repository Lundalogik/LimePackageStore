CREATE PROCEDURE [dbo].[csp_easytopro_history]
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
                            WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__HISTORY]')
                                    AND type IN ( N'U' ) ) 
                    DROP TABLE [dbo].[EASY__HISTORY] 

                CREATE TABLE [dbo].[EASY__HISTORY]
                    (
                      [id] INT IDENTITY(1, 1)
                               PRIMARY KEY ,
                      [Type] SMALLINT NOT NULL ,
                      [Key 1] INT NOT NULL ,
                      [Key 2] INT NOT NULL ,
                      [History] NVARCHAR(MAX) ,
                      [splitted] INT
                    )
            END
        EXEC sp_xml_preparedocument @iXML OUTPUT, @@xml

        INSERT  INTO [dbo].[EASY__HISTORY]
                ( [Type] ,
                  [Key 1] ,
                  [Key 2] ,
                  [History] ,
                  [splitted] 
                )
                SELECT  [type] ,
                        [key1] ,
                        [key2] ,
                        [history] ,
                        0
                FROM    OPENXML(@iXML, '/data/row')
	WITH (	
	[type] SMALLINT ,
                        [key1] INT ,
                        [key2] INT ,
                        [history] NVARCHAR(MAX) 
		) 
	

        EXECUTE sp_xml_removedocument @iXML
    END