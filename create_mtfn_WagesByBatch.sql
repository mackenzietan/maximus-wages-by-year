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

    DECLARE @EmployeeHours TABLE (
                                    Department VARCHAR(MAX)
                                    ,EmployeeNumber INT
                                    ,PayBatchID INT
                                    ,SeparateCheckID INT
                                    ,WorkDate DATETIME
                                    ,HoursWorked INT
                                    ,GLAccount VARCHAR(MAX)
                                    ,GLAccountID INT
                                    ,TransactionAmount INT

    )

    INSERT INTO @EmployeeHours
    SELECT 
        CONCAT(og.OrgGroupCode,' - ',og.OrgGroupCodeDesc) AS 'Department'
        ,e.EmployeeNumber
        ,pjed.PayBatchID
        ,pjed.SeparateCheckID
        ,ph.WorkDate
        ,ph.HoursWorked
        ,CONCAT(gla.Org1Code,'.',gla.Org2Code,'.',a.AccountCode,' - ',a.AccountDescription) AS 'GLAccount'
        ,pjed.GLAccountID
        ,pjed.TransactionAmount
    FROM HR.PayrollJournal_EarningDetail AS pjed
        INNER JOIN dbo.PayrollHours   AS ph   ON ph.PayrollHoursID=pjed.PayrollID
        INNER JOIN dbo.OrgStructure   AS os   ON os.OrgStructureID=ph.OrgStructureID
        INNER JOIN dbo.OrgGroup       AS og   ON og.OrgGroupID=os.Level1ID
        INNER JOIN HR.Employee        AS e    ON e.EmployeeId=pjed.EmployeeID
        INNER JOIN dbo.GLAccount      AS gla  ON gla.GLAccountID=pjed.GLAccountID
        INNER JOIN dbo.Account        AS a    ON a.AccountID=gla.AccountID
    WHERE ph.VoidedFlag = 'False'
        AND ph.WorkDate BETWEEN @Jan1DT AND @Dec31DT
    ORDER BY pjed.PayBatchID

    INSERT INTO @WagesByBatch
    SELECT 
        Department
	    ,EmployeeNumber
	    ,PayBatchID
	    ,SeparateCheckID
	    ,MIN(WorkDate) AS CheckStart
	    ,MAX(WorkDate) AS CheckEnd
        ,WorkDate
	    ,GLAccount
	    ,SUM(HoursWorked) AS SumHoursWorked
	    ,SUM(TransactionAmount) AS SumTransactionAmount
    FROM @EmployeeHours
    GROUP BY Department
		    ,EmployeeNumber
		    ,PayBatchID
		    ,SeparateCheckID
		    ,GLAccount
            ,WorkDate
    ORDER BY Department
		    ,EmployeeNumber
		    ,PayBatchID
		    ,GLAccount

RETURN
END
GO
