---------------------------------------------------------------------
-- Microsoft SQL Server 2012: Основы T-SQL
-- Глава 07 - Продвинутые запросы
-- © Ицик Бен-Ган
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Оконные функции
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Описание оконных функций
---------------------------------------------------------------------

USE TSQL2012;

SELECT empid, ordermonth, val,
  SUM(val) OVER(PARTITION BY empid
                ORDER BY ordermonth
                ROWS BETWEEN UNBOUNDED PRECEDING
                         AND CURRENT ROW) AS runval
FROM Sales.EmpOrders;

---------------------------------------------------------------------
-- Ранжирующие оконные функции
---------------------------------------------------------------------

SELECT orderid, custid, val,
  ROW_NUMBER() OVER(ORDER BY val) AS rownum,
  RANK()       OVER(ORDER BY val) AS rank,
  DENSE_RANK() OVER(ORDER BY val) AS dense_rank,
  NTILE(10)    OVER(ORDER BY val) AS ntile
FROM Sales.OrderValues
ORDER BY val;

SELECT orderid, custid, val,
  ROW_NUMBER() OVER(PARTITION BY custid
                    ORDER BY val) AS rownum
FROM Sales.OrderValues
ORDER BY custid, val;

SELECT DISTINCT val, ROW_NUMBER() OVER(ORDER BY val) AS rownum
FROM Sales.OrderValues;

SELECT val, ROW_NUMBER() OVER(ORDER BY val) AS rownum
FROM Sales.OrderValues
GROUP BY val;

---------------------------------------------------------------------
-- Оконные функции со смещением
---------------------------------------------------------------------

-- Функции LAG и LEAD
SELECT custid, orderid, val,
  LAG(val)  OVER(PARTITION BY custid
                 ORDER BY orderdate, orderid) AS prevval,
  LEAD(val) OVER(PARTITION BY custid
                 ORDER BY orderdate, orderid) AS nextval
FROM Sales.OrderValues;

-- Функции FIRST_VALUE и LAST_VALUE
SELECT custid, orderid, val,
  FIRST_VALUE(val) OVER(PARTITION BY custid
                        ORDER BY orderdate, orderid
                        ROWS BETWEEN UNBOUNDED PRECEDING
                                 AND CURRENT ROW) AS firstval,
  LAST_VALUE(val)  OVER(PARTITION BY custid
                        ORDER BY orderdate, orderid
                        ROWS BETWEEN CURRENT ROW
                                 AND UNBOUNDED FOLLOWING) AS lastval
FROM Sales.OrderValues
ORDER BY custid, orderdate, orderid;

---------------------------------------------------------------------
-- Агрегатные оконные функции
---------------------------------------------------------------------

SELECT orderid, custid, val,
  SUM(val) OVER() AS totalvalue,
  SUM(val) OVER(PARTITION BY custid) AS custtotalvalue
FROM Sales.OrderValues;

SELECT orderid, custid, val,
  100. * val / SUM(val) OVER() AS pctall,
  100. * val / SUM(val) OVER(PARTITION BY custid) AS pctcust
FROM Sales.OrderValues;

SELECT empid, ordermonth, val,
  SUM(val) OVER(PARTITION BY empid
                ORDER BY ordermonth
                ROWS BETWEEN UNBOUNDED PRECEDING
                         AND CURRENT ROW) AS runval
FROM Sales.EmpOrders;

---------------------------------------------------------------------
-- Разворачивание данных
---------------------------------------------------------------------

-- Листинг 7.1. Код для создания и заполнения таблицы dbo.Orders
USE TSQL2012;

IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
GO

CREATE TABLE dbo.Orders
(
  orderid   INT        NOT NULL,
  orderdate DATE       NOT NULL,
  empid     INT        NOT NULL,
  custid    VARCHAR(5) NOT NULL,
  qty       INT        NOT NULL,
  CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);

INSERT INTO dbo.Orders(orderid, orderdate, empid, custid, qty)
VALUES
  (30001, '20070802', 3, 'A', 10),
  (10001, '20071224', 2, 'A', 12),
  (10005, '20071224', 1, 'B', 20),
  (40001, '20080109', 2, 'A', 40),
  (10006, '20080118', 1, 'C', 14),
  (20001, '20080212', 2, 'B', 12),
  (40005, '20090212', 3, 'A', 10),
  (20002, '20090216', 1, 'C', 20),
  (30003, '20090418', 2, 'B', 15),
  (30004, '20070418', 3, 'C', 22),
  (30007, '20090907', 3, 'D', 30);

SELECT * FROM dbo.Orders;

-- Запрос к таблице Orders, группирующий сотрудников и клиентов
SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid, custid;

---------------------------------------------------------------------
-- Разворачивание с использованием стандартных средств SQL
---------------------------------------------------------------------

-- Query against Orders, grouping by employee, pivoting customers,
-- aggregating sum of quantity
SELECT empid,
  SUM(CASE WHEN custid = 'A' THEN qty END) AS A,
  SUM(CASE WHEN custid = 'B' THEN qty END) AS B,
  SUM(CASE WHEN custid = 'C' THEN qty END) AS C,
  SUM(CASE WHEN custid = 'D' THEN qty END) AS D  
FROM dbo.Orders
GROUP BY empid;

---------------------------------------------------------------------
-- Разворачивание с использованием встроенного оператора PIVOT 
---------------------------------------------------------------------

-- Аналог предыдущего запроса, переписанный с использованием оператора PIVOT 
SELECT empid, A, B, C, D
FROM (SELECT empid, custid, qty
      FROM dbo.Orders) AS D
  PIVOT(SUM(qty) FOR custid IN(A, B, C, D)) AS P;

-- Запрос, иллюстрирующий проблемы с неявным группированием
SELECT empid, A, B, C, D
FROM dbo.Orders
  PIVOT(SUM(qty) FOR custid IN(A, B, C, D)) AS P;

-- Аналог предыдущего запроса
SELECT empid,
  SUM(CASE WHEN custid = 'A' THEN qty END) AS A,
  SUM(CASE WHEN custid = 'B' THEN qty END) AS B,
  SUM(CASE WHEN custid = 'C' THEN qty END) AS C,
  SUM(CASE WHEN custid = 'D' THEN qty END) AS D  
FROM dbo.Orders
GROUP BY orderid, orderdate, empid;

-- Запрос к таблице Orders, группирующий по клиентам, разворачивающий 
-- данные о сотрудниках, агрегирующий общее количество заказанного товара
SELECT custid, [1], [2], [3]
FROM (SELECT empid, custid, qty
      FROM dbo.Orders) AS D
  PIVOT(SUM(qty) FOR empid IN([1], [2], [3])) AS P;

---------------------------------------------------------------------
-- Отмена разворачивания данных
---------------------------------------------------------------------

-- Код для создания и заполнения таблицы EmpCustOrders 
USE TSQL2012;

IF OBJECT_ID('dbo.EmpCustOrders', 'U') IS NOT NULL DROP TABLE dbo.EmpCustOrders;

CREATE TABLE dbo.EmpCustOrders
(
  empid INT NOT NULL
    CONSTRAINT PK_EmpCustOrders PRIMARY KEY,
  A VARCHAR(5) NULL,
  B VARCHAR(5) NULL,
  C VARCHAR(5) NULL,
  D VARCHAR(5) NULL
);

INSERT INTO dbo.EmpCustOrders(empid, A, B, C, D)
  SELECT empid, A, B, C, D
  FROM (SELECT empid, custid, qty
        FROM dbo.Orders) AS D
    PIVOT(SUM(qty) FOR custid IN(A, B, C, D)) AS P;

SELECT * FROM dbo.EmpCustOrders;

---------------------------------------------------------------------
-- Отмена разворачивания данных стандартными средствами
---------------------------------------------------------------------

-- Отмена разворачивания. Шаг 1: создание копий
SELECT *
FROM dbo.EmpCustOrders
  CROSS JOIN (VALUES('A'),('B'),('C'),('D')) AS Custs(custid);

-- Отмена разворачивания. Шаг 2: извлечение элементов
SELECT empid, custid,
  CASE custid
    WHEN 'A' THEN A
    WHEN 'B' THEN B
    WHEN 'C' THEN C
    WHEN 'D' THEN D    
  END AS qty
FROM dbo.EmpCustOrders
  CROSS JOIN (VALUES('A'),('B'),('C'),('D')) AS Custs(custid);

-- Отмена разворачивания. Шаг 3: удаление отметок NULL
SELECT *
FROM (SELECT empid, custid,
        CASE custid
          WHEN 'A' THEN A
          WHEN 'B' THEN B
          WHEN 'C' THEN C
          WHEN 'D' THEN D    
        END AS qty
      FROM dbo.EmpCustOrders
        CROSS JOIN (VALUES('A'),('B'),('C'),('D')) AS Custs(custid)) AS D
WHERE qty IS NOT NULL;

---------------------------------------------------------------------
-- Отмена разворачивания данных с помощью встроенного оператора UNPIVOT
---------------------------------------------------------------------

-- Запрос, в котором используется встроенный оператор UNPIVOT 
SELECT empid, custid, qty
FROM dbo.EmpCustOrders
  UNPIVOT(qty FOR custid IN(A, B, C, D)) AS U;
  
---------------------------------------------------------------------
-- Группирующие наборы
---------------------------------------------------------------------

-- Четыре запроса с разными группирующими наборами
SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid, custid;

SELECT empid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid;

SELECT custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY custid;

SELECT SUM(qty) AS sumqty
FROM dbo.Orders;

-- Объединение результирующих наборов, возвращенных четырьмя запросами
SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid, custid

UNION ALL

SELECT empid, NULL, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid

UNION ALL

SELECT NULL, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY custid

UNION ALL

SELECT NULL, NULL, SUM(qty) AS sumqty
FROM dbo.Orders;

---------------------------------------------------------------------
-- Вложенная инструкция GROUPING SETS
---------------------------------------------------------------------

-- Использование вложенной инструкции GROUPING SETS 
SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY
  GROUPING SETS
  (
    (empid, custid),
    (empid),
    (custid),
    ()
  );

---------------------------------------------------------------------
-- Вложенная инструкция CUBE 
---------------------------------------------------------------------

-- Использование вложенной инструкции CUBE 
SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);

---------------------------------------------------------------------
-- Вложенная инструкция ROLLUP 
---------------------------------------------------------------------

-- Использование вложенной инструкции ROLLUP 
SELECT 
  YEAR(orderdate) AS orderyear,
  MONTH(orderdate) AS ordermonth,
  DAY(orderdate) AS orderday,
  SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY ROLLUP(YEAR(orderdate), MONTH(orderdate), DAY(orderdate));

---------------------------------------------------------------------
-- Функции GROUPING и GROUPING_ID 
---------------------------------------------------------------------

SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);

SELECT
  GROUPING(empid) AS grpemp,
  GROUPING(custid) AS grpcust,
  empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);

SELECT
  GROUPING_ID(empid, custid) AS groupingset,
  empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);
