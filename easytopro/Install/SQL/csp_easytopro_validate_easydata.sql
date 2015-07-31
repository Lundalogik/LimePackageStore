CREATE PROCEDURE [dbo].[csp_easytopro_validate_easydata]
    (

      @@errormessage NVARCHAR(2048) OUTPUT
        
    )
AS 
    BEGIN
    -- FLAG_EXTERNALACCESS --
    SET @@errormessage = N''
    
    DECLARE @data NVARCHAR(255)
    DECLARE @fieldname NVARCHAR(48)
    DECLARE @datatype INT
    DECLARE @datatypedata INT
    DECLARE @fieldid INT
    DECLARE @key1 INT
    DECLARE @key2 INT
    
    
    --Begin: Validate integers and date fields
    DECLARE data_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
        SELECT e.Data, f.[Field name], f.[Data type], f.[Data type data]
			FROM EASY__DATA e INNER JOIN EASY__FIELD f 
				ON e.[Field ID]=f.[Field ID] 
			WHERE f.[Data type data] = 32 --Textfield with integers
				OR f.[Data type data] = 16 --Textfield with date
				
	OPEN data_cursor
        FETCH NEXT FROM data_cursor INTO @data, @fieldname, @datatype, @datatypedata
        WHILE @@FETCH_STATUS = 0
			AND @@errormessage = N'' 
            BEGIN
				IF @datatypedata = 32 --Textfield with integers
				BEGIN
					-- Verify data is an integer
					IF ISNULL(PATINDEX(N'[^-]%[^0-9]%', @data),0) > 0
						SET @@errormessage = N'Integer field ''' + @fieldname + ''' contains data that is not an integer.'
				END
				ELSE IF @datatypedata = 16 --Textfield with date
				BEGIN
					IF ISDATE(@data) = 0
						SET @@errormessage = N'Date field ''' + @fieldname + ''' contains data that is not a valid date.'
				END
				
                FETCH NEXT FROM data_cursor INTO @data, @fieldname, @datatype, @datatypedata
            END
        CLOSE data_cursor
        DEALLOCATE data_cursor
	--End: Validate integers and date fields      
        
    --Begin: Validate set fields for company and project    
    DECLARE data_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
        SELECT DISTINCT e.[Field ID], e.[Key 1]
			FROM EASY__DATA e INNER JOIN EASY__FIELD f 
				ON e.[Field ID]=f.[Field ID] 
			WHERE f.[Data type] = 5 --Set fields
				AND (f.[Field type] = 0 OR f.[Field type] = 2) --Field on company or project cards

	OPEN data_cursor
        FETCH NEXT FROM data_cursor INTO @fieldid, @key1
        WHILE @@FETCH_STATUS = 0
			AND @@errormessage = N''
            BEGIN
				--Check if more than 23 options are selected
				IF (SELECT COUNT(Data) FROM EASY__DATA WHERE [Field ID] = @fieldid AND [Key 1] = @key1) > 23
				BEGIN
					SET @@errormessage =  N'Set field ''' + (SELECT [Field name] FROM EASY__FIELD WHERE [Field ID] = @fieldid) + ''' has more than 23 options selected, which is not allowed in LIME Pro.'
				END
                FETCH NEXT FROM data_cursor INTO @fieldid, @key1
            END
        CLOSE data_cursor
        DEALLOCATE data_cursor
    --End: Validate set fields for company and project
    
    --Begin: Validate set fields for person and documents
    DECLARE data_cursor CURSOR READ_ONLY STATIC FORWARD_ONLY LOCAL
        FOR
        SELECT DISTINCT e.[Field ID], e.[Key 1], e.[Key 2]
			FROM EASY__DATA e INNER JOIN EASY__FIELD f 
				ON e.[Field ID]=f.[Field ID] 
			WHERE f.[Data type] = 5 --Set fields
				AND (f.[Field type] = 1 OR f.[Field type] = 6 OR f.[Field type] = 7) --Field on person or document cards

	OPEN data_cursor
        FETCH NEXT FROM data_cursor INTO @fieldid, @key1, @key2
        WHILE @@FETCH_STATUS = 0
			AND @@errormessage = N''
            BEGIN
				--Check if more than 23 options are selected
				IF (SELECT COUNT(Data) FROM EASY__DATA WHERE [Field ID] = @fieldid AND [Key 1] = @key1) > 23
				BEGIN
					SET @@errormessage =  N'Set field ''' + (SELECT [Field name] FROM EASY__FIELD WHERE [Field ID] = @fieldid) + ''' has more than 23 options selected, which is not allowed in LIME Pro.'
				END
                FETCH NEXT FROM data_cursor INTO @fieldid, @key1, @key2
            END
        CLOSE data_cursor
        DEALLOCATE data_cursor
    --End: Validate set fields for person and documents
    
       
    END