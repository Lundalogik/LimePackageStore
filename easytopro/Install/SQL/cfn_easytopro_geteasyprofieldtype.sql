CREATE FUNCTION [dbo].[cfn_easytopro_geteasyprofieldtype]
    (
      @datatype INT ,
      @datatypedata INT
    )
RETURNS INT
AS 
    BEGIN

        DECLARE @result INT

        SELECT  @result = CASE @datatype
                            WHEN 0 THEN CASE @datatypedata
                                          WHEN 0 THEN 1 --N'TEXT'
                                          WHEN 1 THEN 23 --N'PHONE(TEXT)'
                                          WHEN 2 THEN 12 -- N'EMAIL'
                                          WHEN 4 THEN 23 --N'FAX(TEXT)'
                                          WHEN 8 THEN 12 --N'WWW'
                                          WHEN 16 THEN 7 -- N'DATE'
                                          WHEN 32 THEN 3 --N'INT'
                                          WHEN 64 THEN 1 --N'SKYPE'
                                          ELSE 1 --N'TEXT'
                                        END
                            WHEN 1 THEN 13 --N'YES/NO'
                            WHEN 2 THEN 21 --N'OPTION'
                            WHEN 3 THEN 1 --N'TEXT OPTION'
                            WHEN 4 THEN 16 --N'COWORKER'
                            WHEN 5 THEN 20 --N'SET' 
                          END 
                            
        RETURN ISNULL(@result, -1)
    END