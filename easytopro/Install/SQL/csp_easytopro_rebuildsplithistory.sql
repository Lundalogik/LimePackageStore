CREATE PROCEDURE [dbo].[csp_easytopro_rebuildsplithistory]
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
 IF EXISTS ( SELECT  *
                                FROM    sys.objects
                                WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__SPLITTEDHISTORY]')
                                        AND type IN ( N'U' ) ) 
                        DROP TABLE [dbo].EASY__SPLITTEDHISTORY 

                    CREATE TABLE [dbo].EASY__SPLITTEDHISTORY
                        (
                          [Type] SMALLINT NOT NULL ,
                          [Key 1] INT NOT NULL ,
                          [Key 2] INT NOT NULL ,
                          [date] DATETIME ,
                          [historytype] NVARCHAR(96) ,
                          [note] NVARCHAR(MAX) ,
                          [user_limeeasyid] INT ,
                          [refs_limeeasyid] INT ,
                          [contact_limeeasyid] INT ,
                          [project_limeeasyid] INT ,
                          [time_limeeasyid] INT, 
						  [historyid] INT
                        )
		END