CREATE FUNCTION [dbo].[cfn_easytopro_formathistorydate]
    (
      @historydate NVARCHAR(16) ,
      @historydateformat NVARCHAR(10)
    )
RETURNS DATETIME
AS 
    BEGIN
        DECLARE @result NVARCHAR(16)
        DECLARE @date DATETIME
    
        SELECT  @result = SUBSTRING(@historydate,
                                    CHARINDEX(N'yyyy', @historydateformat), 4)
                + N'-' + SUBSTRING(@historydate,
                                   CHARINDEX(N'MM', @historydateformat), 2)
                + N'-' + SUBSTRING(@historydate,
                                   CHARINDEX(N'dd', @historydateformat), 2)
                + N' ' + SUBSTRING(@historydate, 12, 6)

        IF ( ISDATE(@result) = 0 ) 
            BEGIN
                SELECT  @date = [dbo].[lfn_formatfieldtime](GETDATE(), 0)
            END
        ELSE 
            BEGIN
                SELECT  @date = CAST(@result AS DATETIME)
            END
	
        RETURN @date
	
    END