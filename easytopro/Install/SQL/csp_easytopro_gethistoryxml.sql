CREATE PROCEDURE [dbo].[csp_easytopro_gethistoryxml]
	(
		@@maxnotelength INT = NULL
	)
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @xml NVARCHAR(MAX)
        DECLARE @remaining INT
		

        SELECT  @remaining = ( SELECT   COUNT([id])
                               FROM     [dbo].[EASY__HISTORY]
                               WHERE    [splitted] = 0
                                        AND ( ( LEN(ISNULL([History], N'')) <= ISNULL(@@maxnotelength,
                                                              0) )
                                              OR ( @@maxnotelength IS NULL )
                                            )
                             ) 

        SELECT  @xml = N'<info remaining="'
                + ISNULL(CAST(@remaining AS NVARCHAR(32)), N'') + N'" />'

        SELECT  CAST(@xml AS XML)
    
    END 