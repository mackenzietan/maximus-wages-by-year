--create function mtfn_WagesByBatch

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[mtfn_WagesByBatch] (
    @Year VARCHAR(4) = NULL
)
RETURNS @WagesByBatch TABLE (
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
AS
BEGIN

    DECLARE @Jan1Long VARCHAR(30)
    DECLARE @Dec31Long VARCHAR(30)
    DECLARE @Jan1DT DATETIME
    DECLARE @Dec31DT DATETIME

    SET @Jan1Long = @Year + '-01-01 00:00:00.000'
    SET @Jan1DT = CONVERT(DATETIME, @Jan1Long)
    SET @Dec31Long = @Year + '-12-31 23:59:59.999'
    SET @Dec31DT = CONVERT(DATETIME, @Dec31Long)

INSERT INTO @WagesByBatch
    SELECT 
        vei.DepartmentId
        ,vei.EmployeeNumber
        ,pj.PayBatchID
        
        ,CONCAT(gla.GLAccountDelimiter,' ',gla.GLAccountDescription) AS 'GLAccount'
        
        ,vei.EmployeeName
        ,pj.TransactionAmount
        ,pj.PayrollTypeID
        ,pbd.BatchNumber
        
        ,pj.GLAccountID
    FROM NWSLogosLive.dbo.PayrollJournal 
        AS pj
    JOIN NWSLogosLive.dbo.fn_GLAccountWithDescription (NULL, NULL, NULL) --pull function for GL Account info
        AS gla 
        ON pj.GLAccountID = gla.GLAccountID
    JOIN NWSLogosLive.HR.vwEmployeeInformation --pull for Employee Name info
        AS vei 
        ON vei.EmployeeId = pj.EmployeeID
    JOIN dbo.PayBatchDefinition
        AS pbd
        ON pbd.PayBatchID = pj.PayBatchID
    WHERE pj.PayBatchID = @Year --specify pay batches within target year
        AND pj.OrgSetID IN (102,157,158,164,176,177,494) --specify organization set ids for target departments, see info above
        AND pj.PayrollTypeID = 1 --type 1 is wages
        AND vei.DepartmentId = 104 --this only gives us current department ids, so anyone who changed departments since then will not show in the pay batch by department
    ORDER BY vei.EmployeeName DESC

RETURN
END
GO
