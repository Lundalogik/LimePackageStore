CREATE PROCEDURE [dbo].[csp_easytopro_field]
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
                            WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__FIELD]')
                                    AND type IN ( N'U' ) ) 
                    DROP TABLE [dbo].[EASY__FIELD] 

                CREATE TABLE [dbo].[EASY__FIELD]
                    (
                      [Field ID] SMALLINT NOT NULL ,
                      [Field name] NVARCHAR(48) ,
                      [Field type] SMALLINT ,
                      [Order] SMALLINT ,
                      [Symbol] SMALLINT ,
                      [Field width] SMALLINT ,
                      [Data type] SMALLINT ,
                      [Data type data] INT
                    )
            END

        EXEC sp_xml_preparedocument @iXML OUTPUT, @@xml

        INSERT  INTO [dbo].[EASY__FIELD]
                ( [Field ID] ,
                  [Field name] ,
                  [Field type] ,
                  [Order] ,
                  [Symbol] ,
                  [Field width] ,
                  [Data type] ,
                  [Data type data]
                )
                SELECT  [fieldid] ,
                        [fieldname] ,
                        [fieldtype] ,
                        [order] ,
                        [symbol] ,
                        [fieldwidth] ,
                        [datatype] ,
                        [datatypedata]
                FROM    OPENXML(@iXML, '/data/row')
	WITH (	
	[fieldid] SMALLINT,
                  [fieldname] NVARCHAR(48) ,
                  [fieldtype] SMALLINT,
                  [order] SMALLINT ,
                  [symbol] SMALLINT,
                  [fieldwidth]SMALLINT,
                  [datatype] SMALLINT,
                  [datatypedata] INT
		) 
	

        EXECUTE sp_xml_removedocument @iXML
    END