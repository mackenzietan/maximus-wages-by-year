--function, check to see if the dates within a batch fall within the given year, if it does, add it, if it doesn't, calcualte what days do fall within the year
--pull pay batches for year 20xx
    --case dates of batch between 010120xx and 123120xx, keep it
    --case start date less than 010120xx, pull start date and calc days within 20xx
    --case end date greater than 123120xx, pull end date and calc days within 20xx

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER FUNCTION [dbo].[mtfn_BatchesWithHangingDates] (
    @TargetYear int = NULL
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
    DECLARE @StartDateVC varchar(30)
    DECLARE @EndDateVC varchar(30)
    DECLARE @EndDateVC2 varchar(30)
    DECLARE @StartDateDT DATETIME
    DECLARE @EndDateDT DATETIME
    DECLARE @EndDateDT2 DATETIME

    SET @StartDateVC = CONVERT(varchar(4), @TargetYear) + '-01-01 00:00:00.000'
    SET @EndDateVC = CONVERT(varchar(4), @TargetYear) + '-12-31 23:59:59.999'
    SET @EndDateVC2 = CONVERT(varchar(4), @TargetYear+1) + '-01-14 00:00:00.000'

    SET @StartDateDT = CONVERT(datetime, @StartDateVC)
    SET @EndDateDT = CONVERT(datetime, @EndDateVC)
    SET @EndDateDT2 = CONVERT(datetime, @EndDateVC2)
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
        JOIN dbo.UtilityCalendar AS uc ON (uc.UTDate between pbd.StartDate and pbd.EndDate)
        WHERE PayYear = @TargetYear         --selects any pay batch in 20xx...
            AND StartDate < @StartDateDT    -- where the start date is before 20xx-01-01
            AND BatchNumber > 19999999
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
        JOIN dbo.UtilityCalendar AS uc ON (uc.UTDate between pbd.StartDate and pbd.EndDate)
        WHERE PayYear IN (@TargetYear,@TargetYear+1)    --selects any pay batch in 20xx and 20xx+1...
            AND EndDate > @EndDateDT                    -- where the end date is after 20xx/12/31...
            AND EndDate <= @EndDateDT2                  -- and before 20xx+1/01/14 <---if not, this will select all 20xx+1 batches
            AND BatchNumber > 19999999
    END 
RETURN
END
GO