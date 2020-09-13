WITH cte1
AS (SELECT *
    FROM OPENQUERY
         (NBLIVE,
          'SELECT username,ceil((total_money_notpaid+total_money_paid+total_bonus)-total_usage) as remained_credit,status_id,nullif(expire_date, '''') as expire_date
       FROM netbill.USERS'
         )),
     cte2
AS (SELECT o.Username,
           MIN(ii.ServiceStartDate) AS MinStartDate,
           MAX(ii.ServiceExpirationDate) AS MaxExpireDate,
           DATEDIFF(DAY, MIN(ii.ServiceStartDate), MAX(ii.ServiceExpirationDate)) AS StartToEnd,
           DATEDIFF(DAY, GETDATE(), MAX(ii.ServiceExpirationDate)) AS ToEnd,
           DATEDIFF(DAY, MIN(ii.ServiceStartDate), GETDATE()) AS FromStart,
           IIF(DATEDIFF(DAY, GETDATE(), MAX(ii.ServiceExpirationDate)) < 0,
               DATEDIFF(DAY, MIN(ii.ServiceStartDate), MAX(ii.ServiceExpirationDate)),
               ABS(DATEDIFF(DAY, MIN(ii.ServiceStartDate), GETDATE()))) AS CustomerLifeTime,
           SUM(ii.Price) AS totalPayment,
           COUNT(DISTINCT ii.InvoiceId) AS OrderCount,
           DATEDIFF(DAY, MAX(inv.FinalizeDate), GETDATE()) AS RecentOrderDate
    FROM Fanava_CRM.dbo.Invoices inv
        INNER JOIN Fanava_CRM.dbo.InvoiceItems AS ii
            ON inv.Id = ii.InvoiceId
        LEFT JOIN Fanava_CRM.dbo.Orders AS o
            ON ii.OrderId = o.OrderId
        INNER JOIN Fanava_CRM.dbo.Services AS srv
            ON srv.ServiceId = o.ServiceId
        INNER JOIN Fanava_CRM.dbo.Contacts AS c
            ON c.ContactId = o.ContactId
        INNER JOIN Fanava_CRM.dbo.aspnet_Users AS mgr
            ON mgr.UserId = c.AccountManagerId
        LEFT JOIN LiveDbs.dbo.ForooshRolesForGozaresheForoosh AS roles
            ON roles.Username = mgr.UserName
        INNER JOIN Fanava_CRM.dbo.WorkflowOrders AS wo
            ON wo.OrderId = o.OrderId
        INNER JOIN Fanava_CRM.dbo.Workflows AS wf
            ON wf.InstanceId = wo.InstanceId
        INNER JOIN Fanava_CRM.dbo.WorkflowTypeStates AS wfstates
            ON wfstates.InternalState = wf.InternalState
               AND wfstates.TypeId = wf.TypeId
        LEFT JOIN cte1 AS nb
            ON nb.Username = o.Username
    WHERE wf.TypeId = 'A3416996-783D-4ACC-9F1A-0D2E1A1E1417'
          AND wfstates.StateId IN ( 96, 100, 103, 104, 108 )
          AND roles.Rolename <> N'org-group'
          AND inv.InvoiceStatus = 20
    GROUP BY o.Username),
     cte3
AS (SELECT cte2.Username,
           cte2.MinStartDate,
           cte2.MaxExpireDate,
           cte2.StartToEnd,
           cte2.ToEnd,
           cte2.FromStart,
           cte2.CustomerLifeTime,
           cte2.RecentOrderDate,
           cte2.OrderCount,
           AVG(cte2.CustomerLifeTime) OVER (PARTITION BY 1) AS TotalAverage,
           AVG(cte2.totalPayment) OVER (PARTITION BY 1) AS PaymentAverage,
           AVG(cte2.RecentOrderDate) OVER (PARTITION BY 1) AS RecentAverage,
           AVG(cte2.OrderCount) OVER (PARTITION BY 1) AS OrderAverage,
           cte2.totalPayment
    FROM cte2),
     cte4
AS (SELECT cte3.Username,
           cte3.MinStartDate,
           cte3.MaxExpireDate,
           cte3.StartToEnd,
           cte3.ToEnd,
           cte3.FromStart,
           cte3.CustomerLifeTime,
           cte3.TotalAverage,
           cte3.totalPayment,
           cte3.PaymentAverage,
           cte3.OrderAverage,
           cte3.RecentOrderDate,
           cte3.OrderCount,
           CASE
               WHEN cte3.CustomerLifeTime < (cte3.TotalAverage / 2) THEN
                   4
               WHEN cte3.CustomerLifeTime
                    BETWEEN (cte3.TotalAverage / 2) AND cte3.TotalAverage  THEN
                   3
               WHEN cte3.CustomerLifeTime
                     > cte3.TotalAverage AND cte3.CustomerLifeTime < (cte3.TotalAverage *1.25) THEN
                   2
               ELSE
                   1
           END AS LifeTimeScore,
           CASE
               WHEN cte3.totalPayment < (cte3.PaymentAverage / 2) THEN
                   4
               WHEN cte3.totalPayment
                    BETWEEN (cte3.PaymentAverage / 2) AND cte3.PaymentAverage THEN
                   3
				WHEN cte3.totalPayment
                    BETWEEN cte3.TotalAverage AND (cte3.TotalAverage * 1.25) THEN
                   2
               ELSE
                   1
           END AS MonetaryScore,
           CASE
               WHEN cte3.RecentOrderDate < (cte3.RecentAverage / 2) THEN
                   1
               WHEN cte3.RecentOrderDate
                    BETWEEN (cte3.RecentAverage / 2) AND cte3.RecentAverage THEN
                   3
               WHEN cte3.totalPayment
                    BETWEEN cte3.RecentOrderDate AND (cte3.RecentAverage * 1.5) THEN
                   2
               ELSE
                   1
           END AS RecencyScore,
           CASE
               WHEN cte3.OrderCount < (cte3.OrderAverage / 2) THEN
                   1
               WHEN cte3.OrderCount
                    BETWEEN (cte3.OrderAverage / 2) AND cte3.OrderAverage THEN
                   2
               WHEN cte3.OrderCount
                    BETWEEN cte3.OrderAverage AND (cte3.OrderAverage * 1.5) THEN
                   3
               ELSE
                   4
           END AS FrequencyScore
    FROM cte3)
SELECT a.Username,
       a.LifeTimeScore AS LifeTime,
       a.MonetaryScore AS Monetary,
       a.RecencyScore AS Recency,
       a.FrequencyScore,
	   a.CustomerLifeTime AS N'طول عمر مشترک',
       CASE
           WHEN a.LifeTimeScore = 1
                AND a.MonetaryScore = 1
                AND a.RecencyScore = 1
                AND a.FrequencyScore = 1 THEN
               N'مشتری طلایی'
           WHEN a.LifeTimeScore = 1
                AND a.MonetaryScore = 1
                AND a.RecencyScore > 1
                AND a.FrequencyScore > 1 THEN
               N'وفادار سودآور'
           WHEN a.LifeTimeScore = 1
                AND
                (
                    a.MonetaryScore = 3
                    OR a.MonetaryScore = 4
                ) THEN
               N'وفادار با قیمت میانی'
           WHEN (
                    a.LifeTimeScore = 4
                    OR a.LifeTimeScore = 3
                )
                AND a.MonetaryScore = 1 THEN
               N'تازه وارد سودآور'
           WHEN a.LifeTimeScore = 4
                AND a.RecencyScore = 1
                AND a.FrequencyScore = 4
                AND a.MonetaryScore = 4 THEN
               N'جدید حساس به قیمت'
           WHEN (
                    a.LifeTimeScore = 1
                    OR a.LifeTimeScore = 2
                )
                AND
                (
                    a.MonetaryScore = 3
                    OR a.MonetaryScore = 4
                ) THEN
               N'وفادار غیر سودآور'
           ELSE
               N'سایر'
       END AS N'RFM امتیاز'
FROM cte4 AS a
