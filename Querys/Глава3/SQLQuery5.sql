SELECT C.custid, C.companyname
FROM Sales.Customers AS C
	LEFT JOIN Sales.Orders AS O
		ON C.custid = O.custid
WHERE O.orderid IS NULL