--create function mtfn_BatchesWithHangingDates
--queries paybatchdefinition and utility calendar to pull dates within 20xx pay batches
--  that "hang" over the 20xx work days dates (0101 and 1231)

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[mtfn_BatchesWithHangingDates] (
    @TargetYear INT = NULL
)
RETURNS @BatchesWithHangingDates TABLE (
    PayBatchID INT PRIMARY KEY
    ,BatchNumber INT
    ,PayYear INT
    ,StartDate DATETIME
    ,EndDate DATETIME
    ,WorkDate DATETIME
)
AS
BEGIN
    DECLARE @YearPlusOne INT
    DECLARE @StartDateVC VARCHAR(30)
    DECLARE @EndDateVC VARCHAR(30)
    DECLARE @EndDateVC2 VARCHAR(30)
    DECLARE @StartDateDT DATETIME
    DECLARE @EndDateDT DATETIME
    DECLARE @EndDateDT2 DATETIME

    SET @YearPlusOne = @TargetYear+1

    SET @StartDateVC = CONVERT(VARCHAR(4), @TargetYear) + '-01-01 00:00:00.000'
    SET @EndDateVC = CONVERT(VARCHAR(4), @TargetYear) + '-12-31 23:59:59.999'
    SET @EndDateVC2 = CONVERT(VARCHAR(4), @YearPlusOne) + '-01-14 00:00:00.000'

    SET @StartDateDT = CONVERT(DATETIME, @StartDateVC)
    SET @EndDateDT = CONVERT(DATETIME, @EndDateVC)
    SET @EndDateDT2 = CONVERT(DATETIME, @EndDateVC2)
    BEGIN
        INSERT INTO @BatchesWithHangingDates --lists pay batches with hanging dates at the beginning of the year
        SELECT 
            PayBatchID 
            ,BatchNumber
            ,PayYear 
            ,StartDate
            ,EndDate
            ,uc.UTDate
        FROM dbo.PayBatchDefinition AS pbd
        JOIN dbo.UtilityCalendar AS uc ON (uc.UTDate BETWEEN pbd.StartDate AND pbd.EndDate)
        WHERE PayYear = @TargetYear         --selects any pay batch in 20xx...
            AND StartDate < @StartDateDT    -- where the start date is before 20xx-01-01
            AND BatchNumber > 19999999      --only gives us batches/dates in the 20xxmmdd format
    END 
    BEGIN
        INSERT INTO @BatchesWithHangingDates --lists pay batches with hanging dates at the end of the year
        SELECT 
            PayBatchID 
            ,BatchNumber
            ,PayYear 
            ,StartDate
            ,EndDate
            ,uc.UTDate
        FROM dbo.PayBatchDefinition AS pbd
        JOIN dbo.UtilityCalendar AS uc ON (uc.UTDate BETWEEN pbd.StartDate AND pbd.EndDate)
        WHERE PayYear IN (@TargetYear,@YearPlusOne)     --selects any pay batch in 20xx and 20xx+1...
            AND EndDate > @EndDateDT                    -- where the end date is after 20xx/12/31...
            AND EndDate <= @EndDateDT2                  -- and before 20xx+1/01/14 <---if not, this will select all 20xx+1 batches
            AND BatchNumber > 19999999                  --only gives us batches/dates in the 20xxmmdd format
    END 
RETURN
END
GO