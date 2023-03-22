--create function mtfn_WagesByBatch

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[mtfn_WagesByBatch] (
    @Year VARCHAR(4) = NULL
)
RETURNS @WagesByBatch TABLE (
                                Account VARCHAR(MAX)
                                ,EmployeeNumber INT
                                ,EmployeeName VARCHAR(MAX)
                                ,TransactionAmount INT
                                ,PayrollTypeID INT
                                ,BatchNumber INT
                                ,PayBatchID INT
                                ,GLAccountID INT
                                ,DepartmentId INT
                                ,StartDate DATETIME
                                ,EndDate DATETIME
)
AS
BEGIN

INSERT INTO @WagesByBatch
    SELECT 
        concat(gla.GLAccountDelimiter,' ',gla.GLAccountDescription) as 'Account'
        ,vei.EmployeeNumber
        ,vei.EmployeeName
        ,pj.TransactionAmount
        ,pj.PayrollTypeID
        ,pbd.BatchNumber
        ,pj.PayBatchID
        ,pj.GLAccountID
        ,vei.DepartmentId
        ,pbd.StartDate
        ,pbd.EndDate
    FROM dbo.PayrollJournal                                 AS pj
    JOIN dbo.fn_GLAccountWithDescription (NULL, NULL, NULL) AS gla     ON pj.GLAccountID = gla.GLAccountID
    JOIN HR.vwEmployeeInformation                           AS vei     ON vei.EmployeeId = pj.EmployeeID
    JOIN dbo.PayBatchDefinition                             AS pbd     ON pbd.PayBatchID = pj.PayBatchID
    WHERE pj.PayBatchID = @Year --specify pay batches within target year
        AND pj.OrgSetID IN (102,157,158,164,176,177,494) --specify organization set ids for target departments, see info above
        AND pj.PayrollTypeID = 1 --type 1 is wages
        AND vei.DepartmentId = 104 --this only gives us current department ids, so anyone who changed departments since then will not show in the pay batch by department
    ORDER BY vei.EmployeeName DESC

RETURN
END
GO
