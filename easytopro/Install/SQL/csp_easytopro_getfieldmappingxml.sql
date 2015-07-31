CREATE PROCEDURE [dbo].[csp_easytopro_getfieldmappingxml]
    (
      @@easytable NVARCHAR(64) = NULL
    )
AS 
    BEGIN
		-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
	-- Declarations
        IF EXISTS ( SELECT  *
                    FROM    sys.objects
                    WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__FIELDMAPPING]')
                            AND type IN ( N'U' ) ) 
            BEGIN
				IF @@easytable IS NULL
				-- Return complete fieldmapping
				BEGIN
					SELECT  *
					FROM    [dbo].[EASY__FIELDMAPPING] [fieldmapping]
					FOR     XML AUTO
				END
				ELSE
				-- Only return fieldmapping for current table
                SELECT  [idfieldmapping] ,
                        [easytable] ,
                        [easyfieldname] ,
                        [issuperfield] ,
                        [easyfieldid] ,
                        [easyfieldorder] ,
                        [easyfieldtype] ,
                        [easydatatype] ,
                        [easydatatypedata] ,
                        [easydatatypetext] ,
                        [protable] ,
                        [transfertable] ,
                        [profieldname] ,
                        [localname_sv] ,
                        [localname_en_us] ,
                        [localname_no] ,
                        [localname_fi] ,
                        [localname_da] ,
                        [active] ,
                        CASE WHEN EXISTS ( SELECT   *
                                           FROM     [dbo].[fieldcache] f
                                                    INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                           WHERE    f.[name] = [profieldname]
                                                    AND t.[name] = [protable]
                                                    AND LEN([profieldname]) > 0 )
                             THEN 1
                             ELSE 0
                        END AS [existingfield] ,
                        [easyprofieldtype] ,
                        [proposedvalue]
                FROM    [dbo].[EASY__FIELDMAPPING] [fieldmapping]
                WHERE   [easytable] = @@easytable
                FOR     XML AUTO
        
            END
    END