SELECT C.custid, COUNT(DISTINCT O.orderid) AS numorders, sum(OD.qty) totalqty
FROM Sales.Customers AS C
	INNER JOIN Sales.Orders AS O
		ON C.custid = O.custid
			INNER JOIN Sales.OrderDetails AS OD
				ON OD.orderid = O.orderid
WHERE C.country = '—ÿ¿'
GROUP BY C.custid
ORDER BY custid