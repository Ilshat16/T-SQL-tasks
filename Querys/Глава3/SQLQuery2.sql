SELECT E.empid, DATEADD(day, N.n, '20090612') AS dt
FROM dbo.Nums AS N
	CROSS JOIN HR.Employees AS E
WHERE N.n <= DATEDIFF(day, '20090612', '20090616') + 1
ORDER BY empid, dt;