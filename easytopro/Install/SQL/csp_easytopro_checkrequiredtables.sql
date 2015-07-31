CREATE PROCEDURE [dbo].[csp_easytopro_checkrequiredtables]
    (
      @@errormessage NVARCHAR(2048) OUTPUT
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @errormessage NVARCHAR(2048)
        SET @errormessage = N''
        
        IF NOT EXISTS ( SELECT  *
                        FROM    sys.objects
                        WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__FIELDMAPPING]')
                                AND type IN ( N'U' ) ) 
            BEGIN
                SET @errormessage = N' - The table [dbo].[EASY__FIELDMAPPING] is missing'
            END
        IF NOT EXISTS ( SELECT  *
                        FROM    sys.objects
                        WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__OPTIONMAPPING]')
                                AND type IN ( N'U' ) ) 
            BEGIN
                IF ( LEN(@errormessage) > 0 ) 
                    SET @errormessage = @errormessage + CHAR(10)
            	
                SET @errormessage = @errormessage
                    + N' - The table [dbo].[EASY__OPTIONMAPPING] is missing'
            END
        SET @@errormessage = ISNULL(@errormessage, N'')
    END