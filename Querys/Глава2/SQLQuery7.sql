SELECT empid, lastname, firstname, titleofcourtesy,
	CASE
		WHEN titleofcourtesy IN ('����', '������')	THEN '�������'
		WHEN titleofcourtesy = '������'				THEN '�������'
		ELSE											'����������'
	END AS gender
FROM HR.Employees