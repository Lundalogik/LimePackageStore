CREATE FUNCTION [dbo].[cfn_easytopro_geteasydatatypetext]
    (
      @datatype INT ,
      @datatypedata INT
    )
RETURNS NVARCHAR(64)
AS 
    BEGIN

        DECLARE @result NVARCHAR(64)

        SELECT  @result = CASE @datatype
                            WHEN 0 THEN CASE @datatypedata
                                          WHEN 0 THEN N'TEXT'
                                          WHEN 1 THEN N'PHONE(TEXT)'
                                          WHEN 2 THEN N'EMAIL'
                                          WHEN 4 THEN N'FAX(TEXT)'
                                          WHEN 8 THEN N'WWW'
                                          WHEN 16 THEN N'DATE'
                                          WHEN 32 THEN N'INT'
                                          WHEN 64 THEN N'SKYPE'
                                          ELSE N'TEXT'
                                        END
                            WHEN 1 THEN N'YES/NO'
                            WHEN 2 THEN N'OPTION'
                            WHEN 3 THEN N'TEXT OPTION'
                            WHEN 4 THEN N'COWORKER'
                            WHEN 5 THEN N'SET'
                          END 
                            
        RETURN ISNULL(@result, N'UNKNOWN')
    END