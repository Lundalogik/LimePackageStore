CREATE PROCEDURE [dbo].[csp_easytopro_settings]
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
                            WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__SETTINGS]')
                                    AND type IN ( N'U' ) ) 
                    DROP TABLE [dbo].[EASY__SETTINGS] 

                CREATE TABLE [dbo].[EASY__SETTINGS]
                    (
                      [Item] NVARCHAR(50) NOT NULL ,
                      [Value] NVARCHAR(50)
                    )

            END

        EXEC sp_xml_preparedocument @iXML OUTPUT, @@xml

        INSERT  INTO [dbo].[EASY__SETTINGS]
                ( [Item] ,
                  [Value] 
                )
                SELECT  [item] ,
                        [value]
                FROM    OPENXML(@iXML, '/data/row')
	WITH ( 
			    [item] NVARCHAR(50),   
			    [value] NVARCHAR(50)        
		  ) 
	

        EXECUTE sp_xml_removedocument @iXML
    END