SELECT E.empid, E.firstname, E.lastname, N.n
FROM dbo.Nums AS N
	CROSS JOIN HR.Employees AS E
WHERE N.n <= 5
ORDER BY N.n, E.empid;