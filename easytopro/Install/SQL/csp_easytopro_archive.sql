CREATE PROCEDURE [dbo].[csp_easytopro_archive]
    @@xml AS NVARCHAR(MAX) ,
    @@rebuildtable AS BIT
    --@@documentpath AS NVARCHAR(MAX) = ''
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @iXML INT
        
  --      -- Delete spaces and add backslash to documentpath
  --      SET @@documentpath = LTRIM(RTRIM(@@documentpath))
		--IF(RIGHT(@@documentpath,1) <> '\' AND @@documentpath <> '')
		--BEGIN
		--	SET @@documentpath = @@documentpath + '\'
		--END

        IF ( @@rebuildtable = 1 ) 
            BEGIN


                IF EXISTS ( SELECT  *
                            FROM    sys.objects
                            WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__ARCHIVE]')
                                    AND type IN ( N'U' ) ) 
                    DROP TABLE [dbo].[EASY__ARCHIVE]


                CREATE TABLE [dbo].[EASY__ARCHIVE]
                    (
                      [Type] SMALLINT NOT NULL ,
                      [Key 1] INT NOT NULL ,
                      [Key 2] INT NOT NULL ,
                      [Path] NVARCHAR(128) ,
                      [Date] DATETIME ,
                      [Time] INT ,
                      [Comment] NVARCHAR(96) ,
                      [User ID] SMALLINT ,
                      [Reference] NVARCHAR(48)
                    )

            END

        EXEC sp_xml_preparedocument @iXML OUTPUT, @@xml

        INSERT  INTO [dbo].[EASY__ARCHIVE]
                ( [Type] ,
                  [Key 1] ,
                  [Key 2] ,
                  [Path] ,
                  [Date] ,
                  [Time] ,
                  [Comment] ,
                  [User ID] ,
                  [Reference]
                )
                SELECT  [type] ,
                        [key1] ,
                        [key2] ,
                        ---- Only add documentpath if filename is missing path
                        --CASE WHEN [path] LIKE '%:\%' OR [path] LIKE '%\\%' THEN [path] ELSE @@documentpath + [path] END ,
                        [path] ,
                        CASE WHEN [date] = N'' THEN NULL ELSE CAST([date] AS DATETIME) END ,
                        [time] ,
                        [comment] ,
                        [userid] ,
                        [reference]
                FROM    OPENXML(@iXML, '/data/row')
	WITH (	
	[type] SMALLINT,
                  [key1] INT ,
                  [key2] INT,
                  [path] NVARCHAR(128),
                  [date] NVARCHAR(32),
                  [time] INT,
                  [comment] NVARCHAR(96),
                  [userid] SMALLINT,
                  [reference]NVARCHAR(48)
		) 
	

        EXECUTE sp_xml_removedocument @iXML
    END