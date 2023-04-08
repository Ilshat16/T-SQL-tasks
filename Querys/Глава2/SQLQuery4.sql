SELECT orderid, sum(unitprice * qty) as totalprice
FROM Sales.OrderDetails
GROUP BY orderid
HAVING sum(unitprice * qty) > 10000
ORDER BY totalprice DESC;
