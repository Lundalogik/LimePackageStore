CREATE PROCEDURE [dbo].[csp_easytopro_contact]
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
                            WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__CONTACT]')
                                    AND type IN ( N'U' ) ) 
                    DROP TABLE [dbo].[EASY__CONTACT] 


                CREATE TABLE [dbo].[EASY__CONTACT]
                    (
                      [Company ID] INT NOT NULL ,
                      [Company name] NVARCHAR(64) ,
                      [Suffix] NVARCHAR(48) ,
                      [Address] NVARCHAR(255) ,
                      [Telephone] NVARCHAR(48) ,
                      [Fax] NVARCHAR(48) ,
                      [Created date] DATETIME ,
                      [Created time] INT ,
                      [Created user ID] SMALLINT ,
                      [Updated date] DATETIME ,
                      [Updated time] INT ,
                      [Updated user ID] SMALLINT ,
                      [addresslinesbeforezip1] NVARCHAR(255) ,
                      [addresslinesbeforezip2] NVARCHAR(255) ,
                      [addresslinesbeforezip3] NVARCHAR(255) ,
                      [zipcode] NVARCHAR(255) ,
                      [city] NVARCHAR(255) ,
                      [addresslinesafterzip1] NVARCHAR(255) ,
                      [addresslinesafterzip2] NVARCHAR(255)
                    )
            END

        EXEC sp_xml_preparedocument @iXML OUTPUT, @@xml

        INSERT  INTO [dbo].[EASY__CONTACT]
                ( [Company ID] ,
                  [Company name] ,
                  [Suffix] ,
                  [Address] ,
                  [Telephone] ,
                  [Fax] ,
                  [Created date] ,
                  [Created time] ,
                  [Created user ID] ,
                  [Updated date] ,
                  [Updated time] ,
                  [Updated user ID] ,
                  [addresslinesbeforezip1] ,
                  [addresslinesbeforezip2] ,
                  [addresslinesbeforezip3] ,
                  [zipcode] ,
                  [city] ,
                  [addresslinesafterzip1] ,
                  [addresslinesafterzip2]
                )
                SELECT  [companyid] ,
                        [companyname] ,
                        [suffix] ,
                        [address] ,
                        [telephone] ,
                        [fax] ,
                        CASE WHEN [createddate] = N'' THEN NULL ELSE CAST([createddate] AS DATETIME) END ,
                        [createdtime] ,
                        [createduserid] ,
                        CASE WHEN [updateddate] = N'' THEN NULL ELSE CAST([updateddate] AS DATETIME) END ,
                        [updatedtime] ,
                        [updateduserid] ,
                        [addresslinesbeforezip1] ,
                        [addresslinesbeforezip2] ,
                        [addresslinesbeforezip3] ,
                        [zipcode] ,
                        [city] ,
                        [addresslinesafterzip1] ,
                        [addresslinesafterzip2]
                FROM    OPENXML(@iXML, '/data/row')
	WITH (	[companyid] INT, 
			[companyname] NVARCHAR(64), 
			[suffix] NVARCHAR(48),
			[address] NVARCHAR(255),
			[telephone] NVARCHAR(48),
			[fax] NVARCHAR(48),
			[createddate] NVARCHAR(32),
			[createdtime] INT ,
			[createduserid] SMALLINT,
			[updateddate] NVARCHAR(32) ,
			[updatedtime] INT,
			[updateduserid] SMALLINT ,
			[addresslinesbeforezip1] NVARCHAR(255),
			[addresslinesbeforezip2] NVARCHAR(255),
			[addresslinesbeforezip3] NVARCHAR(255),
			[zipcode] NVARCHAR(255),
			[city] NVARCHAR(255),
			[addresslinesafterzip1] NVARCHAR(255),
			[addresslinesafterzip2] NVARCHAR(255) 
		) 
	

        EXECUTE sp_xml_removedocument @iXML
    END