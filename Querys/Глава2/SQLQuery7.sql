SELECT empid, lastname, firstname, titleofcourtesy,
	CASE
		WHEN titleofcourtesy IN ('мисс', 'миссис')	THEN 'женщина'
		WHEN titleofcourtesy = 'мистер'				THEN 'мужщина'
		ELSE											'неизвестно'
	END AS gender
FROM HR.Employees