SELECT custid, region
FROM Sales.Customers
ORDER BY
	CASE
		WHEN region IS NULL THEN 1
		ELSE 0
	END,
	region;