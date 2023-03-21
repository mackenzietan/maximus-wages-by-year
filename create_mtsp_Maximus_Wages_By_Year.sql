--create stored procedure mtsp_Maximus_ParkPolice
--calls our created functions and further specifies the returned data based on
--  the user's department and year specifications
--should return a report that is appropriate to send to Maximus for their yearly request

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE mtsp_Maximus_ParkPolice @SpecifiedYear VARCHAR(4)

AS
SET NOCOUNT ON 
SET ANSI_NULLS ON 
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET NUMERIC_ROUNDABORT OFF 


BEGIN TRY
--step 1: Declare vars and tables
    --current date
DECLARE @CurrentDate DATETIME
SELECT @CurrentDate = GETDATE()

    --date conversions
DECLARE @Jan1Long VARCHAR(30)
DECLARE @Dec31Long VARCHAR(30)
DECLARE @Jan1DT DATETIME
DECLARE @Dec31DT DATETIME
SET @Jan1Long = @SpecifiedYear + '-01-01 00:00:00.000'
SET @Jan1DT = CONVERT(DATETIME, @Jan1Long)
SET @Dec31Long = @SpecifiedYear + '-12-31 23:59:59.999'
SET @Dec31DT = CONVERT(DATETIME, @Dec31Long)

    --hanging dates list
DECLARE @HangingDates VARCHAR(MAX)


CREATE TABLE #BatchesInYear (
                                PayBatchID INT PRIMARY KEY
                                ,BatchNumber INT
                                ,StartDate DATETIME
                                ,EndDate DATETIME
)

CREATE TABLE #HangingDates (
                                PayBatchID INT PRIMARY KEY
                                ,BatchNumber INT
                                ,PayYear INT
                                ,StartDate DATETIME
                                ,EndDate DATETIME
                                ,WorkDate DATETIME
)

CREATE TABLE #HangingDatesWorkDateOnly (
                                WorkDate DATETIME
)

CREATE TABLE #AllActiveEmployees (
                                    EmployeeID int PRIMARY KEY
                                    ,EmployeeNumber int
                                    ,EmployeeFullName varchar(100)
                                    ,EmploymentStatus varchar(10)
                                    ,Department varchar(100)
                                    ,EmployeeJobID int
                                    ,EmployeeJobTitle varchar(100)
)

CREATE TABLE #WagesByHangingDates (
                                    Department VARCHAR(MAX)
                                    ,EmployeeNumber INT
                                    ,PayBatchID INT
                                    ,SeparateCheckID INT
                                    ,CheckStart DATETIME
                                    ,CheckEnd DATETIME
                                    ,WorkDate DATETIME
                                    ,GLAccount VARCHAR(MAX)
                                    ,SumHoursWorked INT
                                    ,SumTransactionAmount INT
)

CREATE TABLE #WagesByBatchWithGL (
                                    Department VARCHAR(MAX)
                                    ,EmployeeNumber INT
                                    ,PayBatchID INT
                                    ,SeparateCheckID INT
                                    ,CheckStart DATETIME
                                    ,CheckEnd DATETIME
                                    ,WorkDate DATETIME
                                    ,GLAccount VARCHAR(MAX)
                                    ,SumHoursWorked INT
                                    ,SumTransactionAmount INT
)

--step 2: call function to get whole batches by @year
SELECT * 
INTO #BatchesInYear 
FROM dbo.mtfn_BatchesByYear(@SpecifiedYear)

--step 3: take @year and calculate partial batches and hanging dates
SELECT * 
INTO #HangingDates 
FROM dbo.mtfn_BatchesWithHangingDates(@SpecifiedYear)
WHERE WorkDate >= @Jan1DT
    AND WorkDate <= @Dec31DT

--step 4: get transaction amounts and gl accounts for the above batches and days
--step 4.1 - by workdate (hanging dates)
    --convert workdate col from #hangingdates into its own single-column table
SELECT WorkDate 
INTO #HangingDatesWorkDateOnly
FROM #HangingDates
    SELECT @HangingDates = COALESCE(@HangingDates + ',','') 
    FROM #HangingDatesWorkDateOnly

SELECT * 
INTO #WagesByHangingDates 
FROM dbo.mtfn_WagesByWorkDay(@SpecifiedYear) 
WHERE Department IN (
    '2010 - Park Police'
    ,'2011 - Park Police/WCCC'
    ,'2013 - Park Police/Airport'
)
    AND WorkDate IN (@HangingDates) --and work day is equal to all the hanging days from the previous step

--step 4.2 - by batch
--we want to call a function that will return the same columns as #WagesByHangingDates but for the batch numbers in #BatchesInYear
--same coalesce statement as above?

SELECT *
INTO #WagesByBatchWithGL
FROM dbo.mtfn_WagesByBatch()


END TRY

BEGIN CATCH

END CATCH