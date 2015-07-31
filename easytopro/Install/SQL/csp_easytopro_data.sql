CREATE PROCEDURE [dbo].[csp_easytopro_data]
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
                            WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__DATA]')
                                    AND type IN ( N'U' ) ) 
                    DROP TABLE [dbo].[EASY__DATA] 


                CREATE TABLE [dbo].[EASY__DATA]
                    (
                      [Field ID] SMALLINT NOT NULL ,
                      [Key 1] INT NOT NULL ,
                      [Key 2] INT NOT NULL ,
                      [Key 3] INT NOT NULL ,
                      [Data] NVARCHAR(255)
                    )
            END

        EXEC sp_xml_preparedocument @iXML OUTPUT, @@xml

        INSERT  INTO [dbo].[EASY__DATA]
                ( [Field ID] ,
                  [Key 1] ,
                  [Key 2] ,
                  [Key 3] ,
                  [Data]
                )
                SELECT  [fieldid] ,
                        [key1] ,
                        [key2] ,
                        [key3] ,
                        [data]
                FROM    OPENXML(@iXML, '/data/row')
	WITH (	
	[fieldid] SMALLINT,
                  [key1] INT ,
                  [key2] INT,
                  [key3] INT,
                  [data]NVARCHAR(255)
		) 
	

        EXECUTE sp_xml_removedocument @iXML
    END