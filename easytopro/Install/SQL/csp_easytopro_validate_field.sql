CREATE PROCEDURE [dbo].[csp_easytopro_validate_field]
    (
      @@idfieldmapping INT = NULL 
    )
AS 
    BEGIN
		-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
	-- Declarations



        DECLARE @tempwarnings TABLE
            (
              [idfieldmapping] INT ,
              [easytable] NVARCHAR(64) ,
              [easyfieldname] NVARCHAR(64) ,
              [protable] NVARCHAR(64) ,
              [issuperfield] INT ,
              [easyfieldid] NVARCHAR(64) ,
              [profieldname] NVARCHAR(64) ,
              [easyprofieldtype] INT ,
              [active] INT ,
              [duplicatefieldname] NVARCHAR(512) ,
              [duplicateeasyfieldid] NVARCHAR(512) ,
              [invalidcharactersfieldname] NVARCHAR(512) ,
              [invalidcharacterslocalname] NVARCHAR(512) ,
              [validatesystemfields] NVARCHAR(512) ,
              [proposedvalueforrequired] NVARCHAR(512) ,
              [validate_sv] NVARCHAR(512) ,
              [validate_en_us] NVARCHAR(512) ,
              [validate_no] NVARCHAR(512) ,
              [validate_fi] NVARCHAR(512) ,
              [validate_da] NVARCHAR(512) ,
              [validatefieldtype] NVARCHAR(512) ,
              [validatefieldlength] NVARCHAR(512)
            )
							
        INSERT  INTO @tempwarnings
                ( [idfieldmapping] ,
                  [easytable] ,
                  [easyfieldname] ,
                  [protable] ,
                  [issuperfield] ,
                  [easyfieldid] ,
                  [profieldname] ,
                  [easyprofieldtype] ,
                  [active] ,
                  duplicatefieldname ,
                  duplicateeasyfieldid ,
                  invalidcharactersfieldname ,
                  invalidcharacterslocalname ,
                  validatesystemfields ,
                  proposedvalueforrequired ,
                  validate_sv ,
                  validate_en_us ,
                  validate_no ,
                  validate_fi ,
                  validate_da ,
                  validatefieldtype ,
                  [validatefieldlength]
									 
                )
                SELECT  e.[idfieldmapping] ,
                        e.[easytable] ,
                        e.[easyfieldname] ,
                        e.[protable] ,
                        e.[issuperfield] ,
                        e.[easyfieldid] ,
                        e.[profieldname] ,
                        e.[easyprofieldtype] ,
                        e.[active] ,
                        CASE WHEN EXISTS ( SELECT   e2.[profieldname]
                                           FROM     [dbo].[EASY__FIELDMAPPING] e2
                                           WHERE    e2.[protable] = e.[protable]
                                                    AND e2.[profieldname] = e.[profieldname]
                                                    AND e2.[protable] = e.[protable]
                                                    AND e2.[idfieldmapping] != e.[idfieldmapping]
                                                    AND e2.[active] = 1
                                                    AND l.[fieldname] IS NULL )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Duplicate of Pro Field name for non existing fields.',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             WHEN EXISTS ( SELECT   e2.[profieldname]
                                           FROM     [dbo].[EASY__FIELDMAPPING] e2
                                           WHERE    e2.[protable] = e.[protable]
                                                    AND e2.[profieldname] = e.[profieldname]
                                                    AND e2.[protable] = e.[protable]
                                                    AND e2.[idfieldmapping] != e.[idfieldmapping]
                                                    AND e2.[active] = 1
                                                    AND l.[fieldname] IS NOT NULL
                                                    AND e.[easyfieldtype] <> 6
                                                    AND e.[easyfieldtype] <> 7 
                                                    AND e.[easyfieldtype] = e2.[easyfieldtype])
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Existing Pro Field mapped more than once.',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             ELSE N''
                        END AS [duplicatefieldname] ,
                        CASE WHEN EXISTS ( SELECT   e2.[easyfieldid]
                                           FROM     [dbo].[EASY__FIELDMAPPING] e2
                                           WHERE    e2.[easyfieldid] = e.[easyfieldid]
                                                    AND e2.[idfieldmapping] != e.[idfieldmapping]
                                                    AND e2.[active] = 1 )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Duplicate in Easy Field ID.',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             ELSE N''
                        END AS [duplicateeasyfieldid] ,
                        --CASE WHEN ( PATINDEX('%[^abcdefghijklmnopqrstuvwxyz0-9_]%',
                        --                     ( e.[profieldname] COLLATE Finnish_Swedish_CS_AS )) > 0 )
                        --     THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Pro Field name can only contain characters a-z, 0-9 and _.', N'#1#',e.[protable]),N'#2#',e.[profieldname])
                        --     ELSE N''
                        --END AS [invalidcharactersfieldname] ,
                        N'' AS [invalidcharactersfieldname] ,
                        CASE WHEN ( CHARINDEX(N'.',
                                              e.[localname_sv]
                                              + e.[localname_en_us]
                                              + e.[localname_no]
                                              + e.[localname_fi]
                                              + e.[localname_da]) > 0 )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Local name can´t contain character ''.''',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             ELSE N''
                        END AS [invalidcharacterslocalname] ,
                        CASE WHEN e.[profieldname] IN ( N'id' + e.[protable],
                                                        N'status',
                                                        N'createduser',
                                                        N'createdtime',
                                                        N'updateduser',
                                                        'timestamp',
                                                        N'rowguid' )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': The name is already taken by a system field',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             ELSE N''
                        END AS [validatesystemfields] ,
                        CASE WHEN LEN(ISNULL(e.[proposedvalue], N'')) > 0
                                  AND l.[fieldname] IS NULL
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Proposed value is only allowed when matching existing field',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             
                             WHEN ISNULL(e.[proposedvalue], N'') != N''
                                  AND NOT EXISTS ( SELECT   a.[idattributedata]
                                                   FROM     [dbo].[attributedata] a
                                                            INNER JOIN [dbo].[fieldcache] f ON f.[idfield] = a.[idrecord]
                                                              AND f.[name] = e.[profieldname]
                                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                              AND t.[name] = e.[protable]
                                                   WHERE    a.[owner] = N'field'
                                                            AND a.[name] = 'required' )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Proposed value is only allowed for required fields.',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             
                             WHEN ISNULL(e.[proposedvalue], N'') = N''
                                  AND EXISTS ( SELECT   a.[idattributedata]
                                               FROM     [dbo].[attributedata] a
                                                        INNER JOIN [dbo].[fieldcache] f ON f.[idfield] = a.[idrecord]
                                                              AND f.[name] = e.[profieldname]
                                                        INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                              AND t.[name] = e.[protable]
                                               WHERE    a.[owner] = N'field'
                                                        AND a.[name] = 'required' )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Mapped to required existing field and a proposed value is not supplied.',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             
                             WHEN ISNULL(e.[proposedvalue], N'') != N''
                                  AND PATINDEX(N'%[^0-9]%',
                                               ISNULL(e.[proposedvalue], N'')) > 0
                                  AND e.[easyprofieldtype] IN ( 20, 21 )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Mapped to required existing option or set field and proposed value is not numeric.',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                                          
                             WHEN ISNULL(e.[proposedvalue], N'') != N''
                                  AND PATINDEX(N'%[^0-9]%',
                                               ISNULL(e.[proposedvalue], N'')) = 0
                                  AND e.[easyprofieldtype] IN ( 20, 21 )
                                  AND NOT EXISTS ( SELECT   [idstring]
                                                   FROM     [dbo].[string]
                                                   WHERE    [idcategory] = ( SELECT TOP 1
                                                              CAST([value] AS INT)
                                                              FROM
                                                              [dbo].[attributedata] a
                                                              INNER JOIN [dbo].[fieldcache] f ON f.[idfield] = a.[idrecord]
                                                              AND f.[name] = e.[profieldname]
                                                              INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                              AND t.[name] = e.[protable]
                                                              WHERE
                                                              a.[owner] = N'field'
                                                              AND a.[name] = 'idcategory'
                                                              )
                                                            AND CAST([idstring] AS NVARCHAR(32)) = ISNULL(e.[proposedvalue],
                                                              N'') )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Proposed value is not a valid idstring',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             
                             WHEN ISNULL(e.[proposedvalue], N'') != N''
                                  AND PATINDEX(N'%[^0-9]%',
                                               ISNULL(e.[proposedvalue], N'')) = 0
                                  AND e.[easyprofieldtype] IN ( 20, 21 )
                                  AND  EXISTS ( SELECT   f.[idfield]
                                       FROM     [dbo].[fieldcache] f
                                                INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                                INNER JOIN [dbo].[attributedata] a ON a.[idrecord] = f.[idfield]
                                                              AND a.[owner] = N'field'
                                                              AND a.[name] = N'required'
                                       WHERE    e.[profieldname] = f.[name]
                                                AND e.[protable] = t.[name]
                                                AND f.[defaultvalue] = e.[proposedvalue] )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Proposed value is default value for a required field',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             
                             WHEN e.[easyprofieldtype] IN ( 3, 7, 13 )
                                  AND LEN(e.[proposedvalue]) > 0
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Proposed value is not allowed for fieldtypes int, date and yes/no',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             ELSE N''
                        END AS [proposedvalueforrequired] ,
                        CASE WHEN ( ( e.localname_sv IN (
                                      SELECT    s.[sv]
                                      FROM      [dbo].[fieldcache] f
                                                INNER JOIN dbo.[table] t ON t.idtable = f.idtable
                                                INNER JOIN [dbo].[string] s ON s.[idstring] = f.[localname]
                                      WHERE     t.[name] = e.protable
                                                AND f.[name] != e.[profieldname] ) )
                                    AND l.[fieldname] IS NULL
                                  )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Localname_SV is already used by another field',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             ELSE N''
                        END AS [validate_sv] ,
                        CASE WHEN ( ( e.localname_en_us IN (
                                      SELECT    s.[en_us]
                                      FROM      [dbo].[fieldcache] f
                                                INNER JOIN dbo.[table] t ON t.idtable = f.idtable
                                                INNER JOIN [dbo].[string] s ON s.[idstring] = f.[localname]
                                      WHERE     t.[name] = e.protable
                                                AND f.[name] != e.[profieldname] ) )
                                    AND l.[fieldname] IS NULL
                                  )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Localname_EN_US is already used by another field',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             ELSE N''
                        END AS [validate_en_us] ,
                        CASE WHEN ( ( e.localname_no IN (
                                      SELECT    s.[no]
                                      FROM      [dbo].[fieldcache] f
                                                INNER JOIN dbo.[table] t ON t.idtable = f.idtable
                                                INNER JOIN [dbo].[string] s ON s.[idstring] = f.[localname]
                                      WHERE     t.[name] = e.protable
                                                AND f.[name] != e.[profieldname] ) )
                                    AND l.[fieldname] IS NULL
                                  )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Localname_NO is already used by another field',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             ELSE N''
                        END AS [validate_no] ,
                        CASE WHEN ( ( e.localname_fi IN (
                                      SELECT    s.[fi]
                                      FROM      [dbo].[fieldcache] f
                                                INNER JOIN dbo.[table] t ON t.idtable = f.idtable
                                                INNER JOIN [dbo].[string] s ON s.[idstring] = f.[localname]
                                      WHERE     t.[name] = e.protable
                                                AND f.[name] != e.[profieldname] ) )
                                    AND l.[fieldname] IS NULL
                                  )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Localname_FI is already used by another field',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             ELSE N''
                        END AS [validate_fi] ,
                        CASE WHEN ( ( e.localname_da IN (
                                      SELECT    s.[da]
                                      FROM      [dbo].[fieldcache] f
                                                INNER JOIN dbo.[table] t ON t.idtable = f.idtable
                                                INNER JOIN [dbo].[string] s ON s.[idstring] = f.[localname]
                                      WHERE     t.[name] = e.protable
                                                AND f.[name] != e.[profieldname] ) )
                                    AND l.[fieldname] IS NULL
                                  )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Localname_DA is already used by another field',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             ELSE N''
                        END AS [validate_da] ,
                        CASE WHEN l.[fieldtype] IS NULL THEN N''
                             WHEN e.[easyprofieldtype] IN ( 1, 12, 23 )
                                  AND l.[fieldtype] NOT IN ( 1, 12, 23 )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Text field in Easy. Needs to be mapped to a Field of type: Text, Link or Formatted text field',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             WHEN e.[easyprofieldtype] = 3
                                  AND l.[fieldtype] NOT IN ( 3, 4 )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Integer field in Easy. Needs to be mapped to a Field of type: Integer or Decimal(FLOAT)',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             WHEN e.[easyprofieldtype] != l.[fieldtype]
                                  AND NOT ( ( e.[easyprofieldtype] IN ( 1, 12,
                                                              23 )
                                              AND l.[fieldtype] IN ( 1, 12, 23 )
                                            )
                                            OR ( e.[easyprofieldtype] = 3
                                                 AND l.[fieldtype] IN ( 3, 4 )
                                               )
                                          )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Missmatch in Fieldtype',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             WHEN e.[easyprofieldtype] = 16
                                  AND e.[issuperfield] = 1
                                  AND N'coworker' != ( SELECT TOP 1
                                                              [relatedtable]
                                                       FROM   [dbo].[relationfieldview]
                                                       WHERE  [idfield] = l.[idfield]
                                                     )
                             THEN REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Only relations to coworker-table are allowed',
                                                  N'#1#', e.[protable]),
                                          N'#2#', e.[profieldname])
                             WHEN e.[easyprofieldtype] = 16
                                  AND e.[issuperfield] = 2
                                  AND ISNULL(( SELECT TOP 1
                                                        e2.[protable]
                                               FROM     [dbo].[EASY__FIELDMAPPING] e2
                                               WHERE    e2.[easytable] = e.[relatedeasytable]
                                                        AND LEN(e2.[protable]) > 0
                                               ORDER BY e2.[idfieldmapping]
                                             ), N'') != ( SELECT TOP 1
                                                              [relatedtable]
                                                          FROM
                                                              [dbo].[relationfieldview]
                                                          WHERE
                                                              [idfield] = l.[idfield]
                                                        )
                             THEN REPLACE(REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Only relations to ''#3#-table'' are allowed',
                                                          N'#1#', e.[protable]),
                                                  N'#2#', e.[profieldname]),
                                          N'#3#',
                                          ISNULL(( SELECT TOP 1
                                                            e2.[protable]
                                                   FROM     [dbo].[EASY__FIELDMAPPING] e2
                                                   WHERE    e2.[easytable] = e.[relatedeasytable]
                                                            AND LEN(e2.[protable]) > 0
                                                   ORDER BY e2.[idfieldmapping]
                                                 ), N''))
                             ELSE N''
                        END AS [validatefieldtype] ,
                        N'' AS [validatefieldlength]
                FROM    [dbo].[EASY__FIELDMAPPING] e
                        LEFT JOIN ( SELECT  f.[name] AS [fieldname] ,
                                            t.[name] AS [tablename] ,
                                            f.[fieldtype] AS [fieldtype] ,
                                            f.[idfield] AS [idfield]
                                    FROM    [dbo].[fieldcache] f
                                            INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                                  ) l ON l.[fieldname] = e.[profieldname]
                                         AND l.[tablename] = e.[protable]
                WHERE   e.[active] = 1
                        AND e.[transfertable] = 1
                        AND ( ( e.[idfieldmapping] = @@idfieldmapping )
                              OR ( @@idfieldmapping IS NULL )
                            )
                       

        DECLARE @idfieldmapping INT
        DECLARE @easyfieldid NVARCHAR(64)
        DECLARE @easyprofieldtype INT
        DECLARE @easytable NVARCHAR(64)
        DECLARE @easyfieldname NVARCHAR(64) 
        DECLARE @protable NVARCHAR(64)
        DECLARE @profield NVARCHAR(64)
        DECLARE @issuperfield INT
        DECLARE @easymaxlen INT
        DECLARE @sql NVARCHAR(MAX)
        DECLARE @messagefieldlength NVARCHAR(512)
        DECLARE @invalidcharactersfieldname NVARCHAR(512)
                       
        DECLARE row_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
            SELECT  [idfieldmapping] ,
                    [easyfieldid] ,
                    [easytable] ,
                    [easyfieldname] ,
                    [easyprofieldtype] ,
                    [issuperfield] ,
                    [protable] ,
                    [profieldname]
            FROM    @tempwarnings
		

        OPEN row_cursor
        FETCH NEXT FROM row_cursor INTO @idfieldmapping, @easyfieldid,
            @easytable, @easyfieldname, @easyprofieldtype, @issuperfield,
            @protable, @profield
        WHILE @@FETCH_STATUS = 0 
            BEGIN
				
                SET @messagefieldlength = N''
                SET @invalidcharactersfieldname = N''
				
                IF ( @easyprofieldtype IN ( 1, 12, 23 )
                     AND @easytable != N'HISTORY'
                   ) 
                    BEGIN
				
                        IF ( @issuperfield = 0 ) 
                            BEGIN
						
                                SET @sql = N'SELECT  @easymaxlenOUT = MAX(LEN('
                                    + QUOTENAME(@easyfieldname) + N')) 
											 FROM [dbo].[EASY__' + @easytable
                                    + N']'
							
                            END
                        ELSE 
                            BEGIN
						
                                SET @sql = N'SELECT @easymaxlenOUT =
                                                            MAX(LEN([Data]))
                                                            FROM [dbo].[EASY__DATA]
                                                            WHERE [Field ID] ='
                                    + @easyfieldid
							
                            END
				
           
                        BEGIN TRY
                            EXEC sp_executesql @sql,
                                N'@easymaxlenOUT INT OUTPUT',
                                @easymaxlenOUT = @easymaxlen OUTPUT
				
				
						 
				
                            SELECT  @messagefieldlength = CASE
                                                              WHEN ( @easymaxlen > f.[length] )
                                                              THEN REPLACE(REPLACE(REPLACE(REPLACE(N'LIME Pro table ''#1#'', field ''#2#'': Length of field in LIME is #3# and Easy contains data of length #4#',
                                                              N'#1#',
                                                              @protable),
                                                              N'#2#',
                                                              @profield),
                                                              N'#3#',
                                                              f.[length]),
                                                              N'#4#',
                                                              @easymaxlen)
                                                              ELSE N''
                                                          END
                            FROM    [dbo].[fieldcache] f
                                    INNER JOIN [dbo].[table] t ON t.[idtable] = f.[idtable]
                            WHERE   f.[name] = @profield
                                    AND t.[name] = @protable
                                            
                        END TRY
                        BEGIN CATCH
                            SET @messagefieldlength = LEFT(ERROR_MESSAGE(),
                                                           512)
                        END CATCH
						
                    END
                ELSE 
                    IF ( @easyprofieldtype IN ( 1, 12, 23 )
                         AND @easytable = N'HISTORY'
                         AND @easyfieldid = N'history_note'
                       ) 
                        BEGIN
                            SELECT  @messagefieldlength = [dbo].[cfn_easytopro_validatehistorylength](@protable,
                                                              @profield)
                                                              
                        END
                    
                BEGIN TRY
                    EXEC [dbo].[lsp_verifyname] @@name = @profield
                    SET @invalidcharactersfieldname = N''
                END TRY
                BEGIN CATCH
                    SET @invalidcharactersfieldname = ERROR_MESSAGE()
                END CATCH
						
                IF ( ( LEN(ISNULL(@messagefieldlength, N'')) ) > 0
                     OR ( LEN(ISNULL(@invalidcharactersfieldname, N'')) > 0 )
                   ) 
                    BEGIN
                        UPDATE  @tempwarnings
                        SET     [validatefieldlength] = ISNULL(@messagefieldlength,
                                                              N'') ,
                                [invalidcharactersfieldname] = ISNULL(@invalidcharactersfieldname,
                                                              N'')
                        WHERE   [idfieldmapping] = @idfieldmapping
                    END
		
		
                FETCH NEXT FROM row_cursor INTO @idfieldmapping, @easyfieldid,
                    @easytable, @easyfieldname, @easyprofieldtype,
                    @issuperfield, @protable, @profield
            END
				
        CLOSE row_cursor
        DEALLOCATE row_cursor    
                       
         --SELECT  @xmltext = N'<warnings>'
         --       + CAST (ISNULL((    
        SELECT  *
        FROM    @tempwarnings AS [warning]
        ORDER BY [protable] ,
                [profieldname]
        FOR     XML AUTO
        --), N'') AS NVARCHAR(MAX)) + N'</warnings>'          
                
        --SELECT CAST(@xmltext AS XML)       
                       
    END
