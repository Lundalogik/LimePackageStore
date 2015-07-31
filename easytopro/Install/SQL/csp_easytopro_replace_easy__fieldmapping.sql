CREATE PROCEDURE [dbo].[csp_easytopro_replace_easy__fieldmapping] 
	(
      @@xml NVARCHAR(MAX),
      @@errormessage NVARCHAR(2048) OUTPUT
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;

        SET @@errormessage = N''
        
        IF EXISTS ( SELECT  *
                    FROM    sys.objects
                    WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__FIELDMAPPING]')
                            AND type IN ( N'U' ) ) 
            BEGIN
                BEGIN TRY
					declare @idoc int
					exec sp_xml_preparedocument @idoc output, @@xml
					
					TRUNCATE TABLE [dbo].[EASY__FIELDMAPPING]
					
					SET IDENTITY_INSERT EASY__FIELDMAPPING ON
					
					INSERT INTO [dbo].[EASY__FIELDMAPPING]
					(idfieldmapping, easytable, relatedeasytable, easyfieldname, issuperfield, easyfieldid, easyfieldorder, easyfieldtype, easydatatype, easydatatypedata, easydatatypetext, protable, transfertable, profieldname, localname_sv, localname_en_us, localname_no, localname_fi, localname_da, active, easyprofieldtype, proposedvalue)
					SELECT *
					FROM OPENXML (@idoc, 'data/fieldmapping')
					WITH(
					idfieldmapping INT,
					easytable NVARCHAR(64),
					relatedeasytable NVARCHAR(64),
					easyfieldname NVARCHAR(64),
					issuperfield INT,
					easyfieldid NVARCHAR(64),
					easyfieldorder INT,
					easyfieldtype INT,
					easydatatype INT,
					easydatatypedata INT,
					easydatatypetext NVARCHAR(64),
					protable NVARCHAR(64),
					transfertable INT,
					profieldname NVARCHAR(64),
					localname_sv NVARCHAR(64),
					localname_en_us NVARCHAR(64),
					localname_no NVARCHAR(64),
					localname_fi NVARCHAR(64),
					localname_da NVARCHAR(64),
					active INT,
					easyprofieldtype INT,
					proposedvalue NVARCHAR(64)
					)
					
					SET IDENTITY_INSERT EASY__FIELDMAPPING OFF
					
                END TRY
                BEGIN CATCH
                    SET @@errormessage = ERROR_MESSAGE()
                END CATCH
            END
        
    END