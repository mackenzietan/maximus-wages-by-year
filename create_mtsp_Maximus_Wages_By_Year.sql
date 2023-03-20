--create stored procedure mtsp_Maximus
--calls our created functions and further specifies the returned data based on
--  the user's department and year specifications
--should return a report that is appropriate to send to Maximus for their yearly request

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE mtsp_Maximus @Department VARCHAR(30), @SpecifiedYear VARCHAR(4)

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
DECLARE @CurrentDate DATETIME
SELECT @CurrentDate = GETDATE()

DECLARE @Jan1Long VARCHAR(30)
DECLARE @Dec31Long VARCHAR(30)
DECLARE @Jan1DT DATETIME
DECLARE @Dec31DT DATETIME

SET @Jan1Long = @SpecifiedYear + '-01-01 00:00:00.000'
SET @Jan1DT = CONVERT(DATETIME, @Jan1Long)

SET @Dec31Long = @SpecifiedYear + '-12-31 23:59:59.999'
SET @Dec31DT = CONVERT(DATETIME, @Dec31Long)

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

CREATE TABLE #AllActiveEmployees (
                                    EmployeeID int PRIMARY KEY
                                    ,EmployeeNumber int
                                    ,EmployeeFullName varchar(100)
                                    ,EmploymentStatus varchar(10)
                                    ,Department varchar(100)
                                    ,EmployeeJobID int
                                    ,EmployeeJobTitle varchar(100)
)

CREATE TABLE #WagesByBatchWithGL (

)

CREATE TABLE #WagesByHangingDatesPP (

)

CREATE TABLE #WagesByHangingDatesPW (

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
CASE
WHEN @Department = 'Park Police' THEN
    SELECT * 
    INTO #WagesByHangingDatesPP 
    FROM dbo.mtfn_WagesByWorkDay(@SpecifiedYear) 
    WHERE Department IN (
        '2010 - Park Police'
        ,'2011 - Park Police/WCCC'
        ,'2013 - Park Police/Airport'
    )
WHEN @Department = 'Public Works' THEN
    SELECT * 
    INTO #WagesByHangingDatesPW
    FROM dbo.mtfn_WagesByWorkDay(@SpecifiedYear) 
    WHERE Department = 'Public Works'
END

--department is park police or public works 
--and work day is equal to all the hanging days from the previous step




--end try
END TRY

--catch
BEGIN CATCH

END CATCH