WITH t
AS (SELECT inv.Id,
           s.ServiceId AS serviceid,
           inv.FinalizeDate AS salesdate,
           LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(s.ServiceName, '(', ''), ')', ''), '*', ''))) AS ServiceName,
           itype.Description,
           ii.Price,
           o.TelecommunicationCenterId,
           ii.Price / s.ServicePeriod AS ARPU,
           s.Quota / 1024 AS Qouta,
           s.Speed AS servicespeed,
           CASE
               WHEN s.ServicePeriod IN ( 40, 45 ) THEN
                   2
               ELSE
                   s.ServicePeriod
           END AS ServicePeriod,
           roles.Username,
           roles.Rolename
    FROM Fanava_CRM.dbo.Invoices inv
        INNER JOIN Fanava_CRM.dbo.InvoiceItems ii
            ON ii.InvoiceId = inv.Id
        INNER JOIN Fanava_CRM.dbo.Orders o
            ON o.OrderId = ii.OrderId
        INNER JOIN Fanava_CRM.dbo.Services s
            ON s.ServiceId = ii.ServiceId
        INNER JOIN Fanava_CRM.dbo.ServiceCategories sc
            ON sc.Id = s.ServiceCategoryId
        LEFT JOIN Fanava_CRM.dbo.Contacts c
            ON c.ContactId = inv.ContactId
        INNER JOIN dbo.aspnet_Users u
            ON u.UserId = c.AccountManagerId
        LEFT JOIN LiveDbs.dbo.ForooshRolesForGozaresheForoosh roles
            ON roles.Username = u.UserName
        INNER JOIN Fanava_CRM.dbo.InvoiceTypes itype
            ON itype.Id = inv.InvoiceTypeId
        INNER JOIN dbo.WorkflowOrders wo
            ON wo.OrderId = o.OrderId
        INNER JOIN dbo.Workflows w
            ON w.InstanceId = wo.InstanceId
        LEFT JOIN Fanava_CRM.dbo.Payments p
            ON p.InvoiceId = inv.Id
               AND p.PaymentStatus IN ( 2, 5 )
    WHERE (
              inv.InvoiceStatus = 20
              OR inv.InvoiceStatus = 30
          )
          AND sc.Id NOT IN ( 1, 3, 4, 5, 7, 8, 10, 11, 12, 13, 14, 15, 17 )
          AND s.ServiceId NOT IN ( 39, 71 )
          AND roles.Rolename <> N'org-group'
          AND w.TypeId = 'A3416996-783D-4ACC-9F1A-0D2E1A1E1417'),
     cte2
AS (SELECT YEAR(t.salesdate) AS sal,
           MONTH(t.salesdate) AS mah,
           t.ServiceName,
           SUM(t.Price) AS sales
    FROM t
    GROUP BY YEAR(t.salesdate),
             MONTH(t.salesdate),
             t.ServiceName),
     cte3
AS (SELECT *,
           ROW_NUMBER() OVER (PARTITION BY sal, mah ORDER BY cte2.sales DESC) AS servierank
    FROM cte2)
SELECT *
FROM cte3
WHERE cte3.servierank <= 5
ORDER BY cte3.sal,
         cte3.mah;

