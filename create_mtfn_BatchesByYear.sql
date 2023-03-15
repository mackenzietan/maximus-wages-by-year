--function for pull pay batches

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[mtfn_BatchesByYear] (
    @SpecifiedYear varchar(4) = NULL
)
RETURNS @BatchesInYear TABLE (
    PayBatchID INT PRIMARY KEY
    ,BatchNumber INT
    ,StartDate DATETIME
    ,EndDate DATETIME
)
AS
BEGIN
    DECLARE @StartDateVC varchar(30)
    DECLARE @EndDateVC varchar(30)
    DECLARE @StartDateDT DATETIME
    DECLARE @EndDateDT DATETIME

    SET @StartDateVC = CONVERT(varchar(4), @SpecifiedYear) + '-01-01 00:00:00.000'
    SET @EndDateVC = CONVERT(varchar(4), @SpecifiedYear) + '-12-31 23:59:59.999'

    SET @StartDateDT = CONVERT(datetime, @StartDateVC)
    SET @EndDateDT = CONVERT(datetime, @EndDateVC)

    INSERT INTO @BatchesInYear
    SELECT 
        PayBatchID
        ,BatchNumber
        ,StartDate
        ,EndDate
    FROM dbo.PayBatchDefinition
    WHERE StartDate > @StartDateDT
        AND EndDate < @EndDateDT
        AND BatchNumber > 9999


RETURN
END
GO