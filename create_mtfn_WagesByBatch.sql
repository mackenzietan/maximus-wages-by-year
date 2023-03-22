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
                                ,Department VARCHAR(MAX)
                                ,StartDate DATETIME
                                ,EndDate DATETIME
)
AS
BEGIN

DECLARE @Jan1VC VARCHAR(30)
    DECLARE @Dec31VC VARCHAR(30)
    DECLARE @Jan1DT DATETIME
    DECLARE @Dec31DT DATETIME

    SET @Jan1VC = CONVERT(VARCHAR(4), @Year) + '0101'
    SET @Dec31VC = CONVERT(VARCHAR(4), @Year) + '1231'

    SET @Jan1DT = CONVERT(DATETIME, @Jan1VC)
    SET @Dec31DT = CONVERT(DATETIME, @Dec31VC)

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
        ,CONCAT(og.OrgGroupCode,' - ',og.OrgGroupCodeDesc) AS 'Department'
        ,pbd.StartDate
        ,pbd.EndDate
    FROM dbo.PayrollJournal                                 AS pj
    JOIN dbo.fn_GLAccountWithDescription (NULL, NULL, NULL) AS gla     ON pj.GLAccountID = gla.GLAccountID
    JOIN HR.vwEmployeeInformation                           AS vei     ON vei.EmployeeId = pj.EmployeeID
    JOIN dbo.PayBatchDefinition                             AS pbd     ON pbd.PayBatchID = pj.PayBatchID
    JOIN HR.PayrollJournal_EarningDetail                    AS pjed    ON pjed.EmployeeID = pj.EmployeeID
    JOIN dbo.PayrollHours                                   AS ph      ON ph.PayrollHoursID = pjed.PayrollID
    JOIN dbo.OrgStructure                                   AS os      ON os.OrgStructureID = ph.OrgStructureID
    JOIN dbo.OrgGroup                                       AS og      ON og.OrgGroupID = os.Level1ID
    WHERE pbd.CheckDate BETWEEN @Jan1DT AND @Dec31DT  --specify pay batches within target year
        AND pj.OrgSetID IN (102,157,158,164,176,177,494) --specify organization set ids for target departments, see info above
        AND pj.PayrollTypeID = 1 --type 1 is wages
        AND vei.DepartmentId = 104 --this only gives us current department ids, so anyone who changed departments since then will not show in the pay batch by department
    ORDER BY vei.EmployeeName DESC

RETURN
END
GO
