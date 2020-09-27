WITH t
AS (SELECT o.Username,
           a.TimeStamp AS startdate,
           b.TimeStamp AS enddate,
           CAST(b.TimeStamp AS DATE) AS PBIDate,
           a.WorkflowInstance,
           a.WorkflowFromState AS fromid,
           a.WorkflowFromStateDescription AS fromstate,
           b.WorkflowToStateDescription AS tostate,
           b.WorkflowToState AS toid,
           o.TelecommunicationCenterId,
           w.TypeId,
           o.OrderId,
           a.OperatorId,
           roles.Rolename,
           city.CityId,
           pro.ProvinceId,
           o.ServiceId
    FROM dbo.WorkflowHistories AS a
        INNER JOIN dbo.WorkflowHistories AS b
            ON a.WorkflowInstance = b.WorkflowInstance
        INNER JOIN dbo.Workflows w
            ON w.InstanceId = b.WorkflowInstance
        INNER JOIN dbo.WorkflowOrders wo
            ON wo.InstanceId = w.InstanceId
        INNER JOIN dbo.Orders o
            ON o.OrderId = wo.OrderId
        INNER JOIN dbo.Services ser
            ON ser.ServiceId = o.CurrentServiceId
        INNER JOIN dbo.TelecommunicationCenters Tc
            ON Tc.Id = o.TelecommunicationCenterId
        INNER JOIN dbo.Cities city
            ON city.CityId = Tc.CityId
        INNER JOIN dbo.Provinces pro
            ON pro.ProvinceId = city.ProvinceId
        INNER JOIN dbo.Contacts c
            ON c.ContactId = o.ContactId
        INNER JOIN dbo.aspnet_Users u
            ON u.UserId = c.AccountManagerId
        LEFT JOIN LiveDbs.dbo.ForooshRolesForGozaresheForoosh roles
            ON roles.Username = u.UserName
    WHERE (
              a.WorkflowFromState = 110 ----بدهی
              AND b.WorkflowToState = 140 ----شروع سرویس 
          )
          OR
          (
              a.WorkflowFromState = 104 ----عدم امکان فنی
              AND b.WorkflowToState = 140
          )
          OR
          (
              a.WorkflowFromState = 130 ------منتظر دایری
              AND b.WorkflowToState = 140
          )
          OR
          (
              a.WorkflowFromState = 120 ------شروع سرویس
              AND b.WorkflowToState = 140
          )
          OR
          (
              a.WorkflowFromState = 108 -------مغایرت اطلاعات
              AND b.WorkflowToState = 140
          )
          OR
          (
              a.WorkflowFromState = 106 ----------دایری از شرکت دیگر
              AND b.WorkflowToState = 140
          )
          OR
          (
              a.WorkflowFromState = 80 ----------منتظر فعالسازی پورت
              AND b.WorkflowToState = 140
          )
          OR
          (
              a.WorkflowFromState = 102 ----------- خرابی رانژه
              AND b.WorkflowToState = 140
          )

),
     cte2
AS (SELECT t.startdate AS shoro,
           t.enddate AS payan,
           t.PBIDate,
           t.WorkflowInstance,
           t.fromid,
           t.fromstate,
           t.tostate,
           t.toid,
           t.TypeId,
           t.OrderId,
           t.Username,
           t.TelecommunicationCenterId,
           t.CityId,
           t.ProvinceId,
           t.Rolename,
           DATEDIFF(DAY, t.startdate, t.enddate) AS daierimodat,
           ROW_NUMBER() OVER (PARTITION BY t.Username
                              ORDER BY DATEDIFF(DAY, t.startdate, t.enddate) ASC
                             ) AS radif,
           t.ServiceId
    FROM t)
SELECT *
FROM cte2
WHERE cte2.radif = 1
      AND cte2.TypeId = 'A3416996-783D-4ACC-9F1A-0D2E1A1E1417'
ORDER BY cte2.payan DESC;

