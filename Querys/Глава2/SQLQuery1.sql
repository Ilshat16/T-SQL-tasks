SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderdate >= '20070601' AND orderdate < '20070701'