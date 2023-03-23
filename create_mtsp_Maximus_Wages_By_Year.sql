--create stored procedure mtsp_Maximus_ParkPolice
--calls our created functions and further specifies the returned data based on
--  the user's department and year specifications
--should return a report that is appropriate to send to Maximus for their yearly request

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE mtsp_Maximus_ParkPolice @SpecifiedYear VARCHAR(4)

AS
SET NOCOUNT ON 
SET ANSI_NULLS ON 
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET NUMERIC_ROUNDABORT OFF 

BEGIN
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

    --batches list
DECLARE @Batches VARCHAR(MAX)

    --Tables
CREATE TABLE #BatchesInYear (
                                PayBatchID INT
                                ,BatchNumber INT
                                ,StartDate DATETIME
                                ,EndDate DATETIME
)

CREATE TABLE #HangingDates (
                                PayBatchID INT
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
                                    EmployeeID INT
                                    ,EmployeeNumber INT
                                    ,EmployeeFullName VARCHAR(100)
                                    ,EmploymentStatus VARCHAR(10)
                                    ,Department VARCHAR(100)
                                    ,EmployeeJobID INT
                                    ,EmployeeJobTitle VARCHAR(100)
)

CREATE TABLE #WagesByHangingDates (
                                    Department VARCHAR(MAX)
                                    ,EmployeeNumber INT
                                    ,EmployeeName VARCHAR(MAX)
                                    ,PayBatchID INT
                                    ,SeparateCheckID INT
                                    ,CheckStart DATETIME
                                    ,CheckEnd DATETIME
                                    ,WorkDate DATETIME
                                    ,GLAccount VARCHAR(MAX)
                                    ,SumHoursWorked INT
                                    ,SumTransactionAmount INT
)

CREATE TABLE #BatchesOnly (
                            PayBatchID INT
)

CREATE TABLE #WagesByBatchWithGL (
                                    Account VARCHAR(MAX)
                                    ,EmployeeNumber INT
                                    ,EmployeeName VARCHAR(MAX)
                                    ,TransactionAmount INT
                                    ,PayrollTypeID INT
                                    ,BatchNumber INT
                                    ,PayBatchID INT
                                    ,GLAccountID INT
                                    ,DepartmentId INT
                                    ,Department VARCHAR(MAX)
                                    ,StartDate DATETIME
                                    ,EndDate DATETIME
)

--step 2: call function to get whole batches by @year
INSERT INTO #BatchesInYear 
SELECT * 
FROM dbo.mtfn_BatchesByYear(@SpecifiedYear)

--step 3: take @year and calculate partial batches and hanging dates
INSERT INTO #HangingDates 
SELECT 
    PayBatchID
FROM dbo.mtfn_BatchesWithHangingDates(@SpecifiedYear)
    WHERE WorkDate >= @Jan1DT
    AND WorkDate <= @Dec31DT

--step 4: get transaction amounts and gl accounts for the above batches and days
    --step 4.1 - by workdate (hanging dates)
    --convert workdate col from #hangingdates into its own single-column table
INSERT INTO #HangingDatesWorkDateOnly
SELECT WorkDate 
FROM #HangingDates
    SET @HangingDates = (
                        SELECT COALESCE(@HangingDates + ',','') 
                        FROM #HangingDatesWorkDateOnly
                        )

INSERT INTO #WagesByHangingDates 
SELECT * 
FROM dbo.mtfn_WagesByWorkDay(@SpecifiedYear) 
WHERE Department IN (
    '2010 - Park Police'
    ,'2011 - Park Police/WCCC'
    ,'2013 - Park Police/Airport'
    )
    AND WorkDate IN (@HangingDates) --and work day is equal to all the hanging days from the previous step

    --step 4.2 - by batch
INSERT INTO #BatchesOnly
SELECT PayBatchID 
FROM #BatchesInYear
    SET @Batches = (
                    SELECT COALESCE(@Batches + ',','')
                    FROM #BatchesOnly
                   )

INSERT INTO #WagesByBatchWithGL
SELECT *
FROM dbo.mtfn_WagesByBatch(@SpecifiedYear)
WHERE Department IN (
    '2010 - Park Police'
    ,'2011 - Park Police/WCCC'
    ,'2013 - Park Police/Airport'
    )
    AND PayBatchID IN (@Batches)

--creating the final report
SELECT 
    GLAccount AS Account
    ,EmployeeNumber
    ,EmployeeName
    ,SumTransactionAmount AS Wages
    ,CONCAT(CheckStart,' - ',CheckEnd) AS PayPeriod
FROM #WagesByHangingDates
UNION ALL
SELECT
    Account
    ,EmployeeNumber
    ,EmployeeName 
    ,TransactionAmount AS Wages
    ,CONCAT(StartDate,' - ',EndDate) AS PayPeriod
FROM #WagesByBatchWithGL

END

GO