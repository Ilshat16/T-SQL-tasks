---------------------------------------------------------------------
-- Microsoft SQL Server 2012: Основы T-SQL
-- Глава 08 - Изменение данных
-- © Ицик Бен-Ган
---------------------------------------------------------------------

USE TSQL2012;

---------------------------------------------------------------------
-- Добавление данных
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Команда INSERT VALUES
---------------------------------------------------------------------

IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;

CREATE TABLE dbo.Orders
(
  orderid   INT         NOT NULL
    CONSTRAINT PK_Orders PRIMARY KEY,
  orderdate DATE        NOT NULL
    CONSTRAINT DFT_orderdate DEFAULT(SYSDATETIME()),
  empid     INT         NOT NULL,
  custid    VARCHAR(10) NOT NULL
);

INSERT INTO dbo.Orders(orderid, orderdate, empid, custid)
  VALUES(10001, '20090212', 3, 'A');

INSERT INTO dbo.Orders(orderid, empid, custid)
  VALUES(10002, 5, 'B');

INSERT INTO dbo.Orders
  (orderid, orderdate, empid, custid)
VALUES
  (10003, '20090213', 4, 'B'),
  (10004, '20090214', 1, 'A'),
  (10005, '20090213', 1, 'C'),
  (10006, '20090215', 3, 'C');

SELECT *
FROM ( VALUES
         (10003, '20090213', 4, 'B'),
         (10004, '20090214', 1, 'A'),
         (10005, '20090213', 1, 'C'),
         (10006, '20090215', 3, 'C') )
     AS O(orderid, orderdate, empid, custid);

---------------------------------------------------------------------
-- Команда INSERT SELECT
---------------------------------------------------------------------

INSERT INTO dbo.Orders(orderid, orderdate, empid, custid)
  SELECT orderid, orderdate, empid, custid
  FROM Sales.Orders
  WHERE shipcountry = 'Великобритания';

INSERT INTO dbo.Orders(orderid, orderdate, empid, custid)
  SELECT 10007, '20090215', 2, 'B' UNION ALL
  SELECT 10008, '20090215', 1, 'C' UNION ALL
  SELECT 10009, '20090216', 2, 'C' UNION ALL
  SELECT 10010, '20090216', 3, 'A'; 

---------------------------------------------------------------------
-- Команда INSERT EXEC
---------------------------------------------------------------------

IF OBJECT_ID('Sales.usp_getorders', 'P') IS NOT NULL
  DROP PROC Sales.usp_getorders;
GO

CREATE PROC Sales.usp_getorders
  @country AS NVARCHAR(40)
AS

SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE shipcountry = @country;
GO

EXEC Sales.usp_getorders @country = 'Франция';

INSERT INTO dbo.Orders(orderid, orderdate, empid, custid)
  EXEC Sales.usp_getorders @country = 'Франция';

---------------------------------------------------------------------
-- Команда SELECT INTO
---------------------------------------------------------------------

IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;

SELECT orderid, orderdate, empid, custid
INTO dbo.Orders
FROM Sales.Orders;

-- Команда SELECT INTO в сочетании с операциями работы с наборами
IF OBJECT_ID('dbo.Locations', 'U') IS NOT NULL DROP TABLE dbo.Locations;

SELECT country, region, city
INTO dbo.Locations
FROM Sales.Customers

EXCEPT

SELECT country, region, city
FROM HR.Employees;

---------------------------------------------------------------------
-- Команда BULK INSERT
---------------------------------------------------------------------

BULK INSERT dbo.Orders FROM 'c:\temp\orders.txt'
  WITH 
    (
       DATAFILETYPE    = 'char',
       FIELDTERMINATOR = ',',
       ROWTERMINATOR   = '\n'
    );
GO

---------------------------------------------------------------------
-- Свойство identity и объект последовательности
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Свойство IDENTITY
---------------------------------------------------------------------

IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;

CREATE TABLE dbo.T1
(
  keycol  INT         NOT NULL IDENTITY(1, 1)
    CONSTRAINT PK_T1 PRIMARY KEY,
  datacol VARCHAR(10) NOT NULL
    CONSTRAINT CHK_T1_datacol CHECK(datacol LIKE '[A-Z]%')
);
GO

INSERT INTO dbo.T1(datacol) VALUES('AAAAA');
INSERT INTO dbo.T1(datacol) VALUES('CCCCC');
INSERT INTO dbo.T1(datacol) VALUES('BBBBB');

SELECT * FROM dbo.T1;

SELECT $identity FROM dbo.T1; 

-- Использование функции SCOPE_IDENTITY
DECLARE @new_key AS INT;

INSERT INTO dbo.T1(datacol) VALUES('AAAAA');

SET @new_key = SCOPE_IDENTITY();

SELECT @new_key AS new_key

-- Запуск в контексте другого соединения
SELECT
  SCOPE_IDENTITY() AS [SCOPE_IDENTITY],
  @@identity AS [@@identity],
  IDENT_CURRENT('dbo.T1') AS [IDENT_CURRENT];
GO

-- Запуск команд INSERT
INSERT INTO dbo.T1(datacol) VALUES('12345');
GO
INSERT INTO dbo.T1(datacol) VALUES('EEEEE');
GO

SELECT * FROM dbo.T1;

-- Использование функции IDENTITY_INSERT 
SET IDENTITY_INSERT dbo.T1 ON;
INSERT INTO dbo.T1(keycol, datacol) VALUES(5, 'FFFFF');
SET IDENTITY_INSERT dbo.T1 OFF;

INSERT INTO dbo.T1(datacol) VALUES('GGGGG');

SELECT * FROM dbo.T1;

---------------------------------------------------------------------
-- Объект последовательности
---------------------------------------------------------------------

-- создание последовательности и запрос значения
IF OBJECT_ID('dbo.SeqOrderIDs') IS NOT NULL
  DROP SEQUENCE dbo.SeqOrderIDs;

CREATE SEQUENCE dbo.SeqOrderIDs AS INT
  MINVALUE 1
  CYCLE;

/*
ALTER SEQUENCE dbo.SeqOrderIDs
  RESTART WITH <constant>
  INCREMENT BY <constant>
  MINVALUE <constant> | NO MINVALUE
  MAXVALUE <constant> | NO MAXVALUE
  CYCLE | NO CYCLE
  CACHE <constant> | NO CACHE;
*/

ALTER SEQUENCE dbo.SeqOrderIDs
  NO CYCLE;

-- использование
SELECT NEXT VALUE FOR dbo.SeqOrderIDs;
GO

IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;

CREATE TABLE dbo.T1
(
  keycol  INT         NOT NULL
    CONSTRAINT PK_T1 PRIMARY KEY,
  datacol VARCHAR(10) NOT NULL
);
GO

DECLARE @neworderid AS INT = NEXT VALUE FOR dbo.SeqOrderIDs;
INSERT INTO dbo.T1(keycol, datacol) VALUES(@neworderid, 'a');

SELECT * FROM dbo.T1;
GO


INSERT INTO dbo.T1(keycol, datacol)
  VALUES(NEXT VALUE FOR dbo.SeqOrderIDs, 'b');

SELECT * FROM dbo.T1;
GO

UPDATE dbo.T1
  SET keycol = NEXT VALUE FOR dbo.SeqOrderIDs;

SELECT * FROM dbo.T1;
GO

-- информация
SELECT current_value
FROM sys.sequences
WHERE OBJECT_ID = OBJECT_ID('dbo.SeqOrderIDs');

-- упорядочивание
INSERT INTO dbo.T1(keycol, datacol)
  SELECT
    NEXT VALUE FOR dbo.SeqOrderIDs OVER(ORDER BY hiredate),
    LEFT(firstname, 1) + LEFT(lastname, 1)
  FROM HR.Employees;

SELECT * FROM dbo.T1;
GO

ALTER TABLE dbo.T1
  ADD CONSTRAINT DFT_T1_keycol
    DEFAULT (NEXT VALUE FOR dbo.SeqOrderIDs)
    FOR keycol;

INSERT INTO dbo.T1(datacol) VALUES('c');

SELECT * FROM dbo.T1;
GO

-- диапазон
DECLARE @first AS SQL_VARIANT;

EXEC sys.sp_sequence_get_range
  @sequence_name     = N'dbo.SeqOrderIDs',
  @range_size        = 1000,
  @range_first_value = @first OUTPUT ;

SELECT @first;
GO

-- очистка
IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;
IF OBJECT_ID('dbo.SeqOrderIDs', 'So') IS NOT NULL DROP SEQUENCE dbo.SeqOrderIDs;
GO

---------------------------------------------------------------------
-- Удаление данных
---------------------------------------------------------------------

IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;

CREATE TABLE dbo.Customers
(
  custid       INT          NOT NULL,
  companyname  NVARCHAR(40) NOT NULL,
  contactname  NVARCHAR(30) NOT NULL,
  contacttitle NVARCHAR(30) NOT NULL,
  address      NVARCHAR(60) NOT NULL,
  city         NVARCHAR(15) NOT NULL,
  region       NVARCHAR(15) NULL,
  postalcode   NVARCHAR(10) NULL,
  country      NVARCHAR(15) NOT NULL,
  phone        NVARCHAR(24) NOT NULL,
  fax          NVARCHAR(24) NULL,
  CONSTRAINT PK_Customers PRIMARY KEY(custid)
);

CREATE TABLE dbo.Orders
(
  orderid        INT          NOT NULL,
  custid         INT          NULL,
  empid          INT          NOT NULL,
  orderdate      DATETIME     NOT NULL,
  requireddate   DATETIME     NOT NULL,
  shippeddate    DATETIME     NULL,
  shipperid      INT          NOT NULL,
  freight        MONEY        NOT NULL
    CONSTRAINT DFT_Orders_freight DEFAULT(0),
  shipname       NVARCHAR(40) NOT NULL,
  shipaddress    NVARCHAR(60) NOT NULL,
  shipcity       NVARCHAR(15) NOT NULL,
  shipregion     NVARCHAR(15) NULL,
  shippostalcode NVARCHAR(10) NULL,
  shipcountry    NVARCHAR(15) NOT NULL,
  CONSTRAINT PK_Orders PRIMARY KEY(orderid),
  CONSTRAINT FK_Orders_Customers FOREIGN KEY(custid)
    REFERENCES dbo.Customers(custid)
);
GO

INSERT INTO dbo.Customers SELECT * FROM Sales.Customers;
INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;

---------------------------------------------------------------------
-- Команда DELETE 
---------------------------------------------------------------------

DELETE FROM dbo.Orders
WHERE orderdate < '20070101';

---------------------------------------------------------------------
-- Команда TRUNCATE
---------------------------------------------------------------------

TRUNCATE TABLE dbo.T1;

---------------------------------------------------------------------
-- Команда DELETE, основанная на соединении
---------------------------------------------------------------------

-- Использование соединения
DELETE FROM O
FROM dbo.Orders AS O
  JOIN dbo.Customers AS C
    ON O.custid = C.custid
WHERE C.country = N'США';

-- Использование вложенного запроса
DELETE FROM dbo.Orders
WHERE EXISTS
  (SELECT *
   FROM dbo.Customers AS C
   WHERE Orders.custid = C.custid
     AND C.country = N'США');

-- очистка
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;

---------------------------------------------------------------------
-- Обновление данных
---------------------------------------------------------------------

IF OBJECT_ID('dbo.OrderDetails', 'U') IS NOT NULL DROP TABLE dbo.OrderDetails;
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;

CREATE TABLE dbo.Orders
(
  orderid        INT          NOT NULL,
  custid         INT          NULL,
  empid          INT          NOT NULL,
  orderdate      DATETIME     NOT NULL,
  requireddate   DATETIME     NOT NULL,
  shippeddate    DATETIME     NULL,
  shipperid      INT          NOT NULL,
  freight        MONEY        NOT NULL
    CONSTRAINT DFT_Orders_freight DEFAULT(0),
  shipname       NVARCHAR(40) NOT NULL,
  shipaddress    NVARCHAR(60) NOT NULL,
  shipcity       NVARCHAR(15) NOT NULL,
  shipregion     NVARCHAR(15) NULL,
  shippostalcode NVARCHAR(10) NULL,
  shipcountry    NVARCHAR(15) NOT NULL,
  CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);

CREATE TABLE dbo.OrderDetails
(
  orderid   INT           NOT NULL,
  productid INT           NOT NULL,
  unitprice MONEY         NOT NULL
    CONSTRAINT DFT_OrderDetails_unitprice DEFAULT(0),
  qty       SMALLINT      NOT NULL
    CONSTRAINT DFT_OrderDetails_qty DEFAULT(1),
  discount  NUMERIC(4, 3) NOT NULL
    CONSTRAINT DFT_OrderDetails_discount DEFAULT(0),
  CONSTRAINT PK_OrderDetails PRIMARY KEY(orderid, productid),
  CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY(orderid)
    REFERENCES dbo.Orders(orderid),
  CONSTRAINT CHK_discount  CHECK (discount BETWEEN 0 AND 1),
  CONSTRAINT CHK_qty  CHECK (qty > 0),
  CONSTRAINT CHK_unitprice CHECK (unitprice >= 0)
);
GO

INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;
INSERT INTO dbo.OrderDetails SELECT * FROM Sales.OrderDetails;

---------------------------------------------------------------------
-- Команда UPDATE 
---------------------------------------------------------------------

UPDATE dbo.OrderDetails
  SET discount = discount + 0.05
WHERE productid = 51;

-- Составные операторы присваивания
UPDATE dbo.OrderDetails
  SET discount += 0.05
WHERE productid = 51;
GO

UPDATE dbo.T1
  SET col1 = col1 + 10, col2 = col1 + 10;

UPDATE dbo.T1
  SET col1 = col2, col2 = col1;
GO

---------------------------------------------------------------------
-- Команда UPDATE, основанная на соединении
---------------------------------------------------------------------

-- Листинг 8.1. Команда UPDATE, основанная на соединении
UPDATE OD
  SET discount += 0.05
FROM dbo.OrderDetails AS OD
  JOIN dbo.Orders AS O
    ON OD.orderid = O.orderid
WHERE O.custid = 1;

UPDATE dbo.OrderDetails
  SET discount += 0.05
WHERE EXISTS
  (SELECT * FROM dbo.Orders AS O
   WHERE O.orderid = OrderDetails.orderid
     AND custid = 1);
GO

UPDATE T1
  SET col1 = T2.col1,
      col2 = T2.col2,
      col3 = T2.col3
FROM dbo.T1 JOIN dbo.T2
  ON T2.keycol = T1.keycol
WHERE T2.col4 = 'ABC';

UPDATE dbo.T1
  SET col1 = (SELECT col1
              FROM dbo.T2
              WHERE T2.keycol = T1.keycol),
              
      col2 = (SELECT col2
              FROM dbo.T2
              WHERE T2.keycol = T1.keycol),
      
      col3 = (SELECT col3
              FROM dbo.T2
              WHERE T2.keycol = T1.keycol)
WHERE EXISTS
  (SELECT *
   FROM dbo.T2
   WHERE T2.keycol = T1.keycol
     AND T2.col4 = 'ABC');
GO

/*
UPDATE dbo.T1

  SET (col1, col2, col3) =

      (SELECT col1, col2, col3
       FROM dbo.T2
       WHERE T2.keycol = T1.keycol)
       
WHERE EXISTS
  (SELECT *
   FROM dbo.T2
   WHERE T2.keycol = T1.keycol
     AND T2.col4 = 'ABC');
*/     
GO
        
---------------------------------------------------------------------
-- Обновление с присваиванием
---------------------------------------------------------------------

-- Создание таблицы Sequence
IF OBJECT_ID('dbo.Sequences', 'U') IS NOT NULL DROP TABLE dbo.Sequences;

CREATE TABLE dbo.Sequences
(
  id VARCHAR(10) NOT NULL
    CONSTRAINT PK_Sequences PRIMARY KEY(id),
  val INT NOT NULL
);
INSERT INTO dbo.Sequences VALUES('SEQ1', 0);

DECLARE @nextval AS INT;

UPDATE dbo.Sequences
  SET @nextval = val += 1
WHERE id = 'SEQ1';

SELECT @nextval;

-- очистка
IF OBJECT_ID('dbo.Sequences', 'U') IS NOT NULL DROP TABLE dbo.Sequences;

---------------------------------------------------------------------
-- Слияние данных
---------------------------------------------------------------------

-- Листинг 8.2. Код для создания и заполнения таблиц dbo.Customers и dbo.CustomersStage
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;
GO

CREATE TABLE dbo.Customers
(
  custid      INT         NOT NULL,
  companyname VARCHAR(25) NOT NULL,
  phone       VARCHAR(20) NOT NULL,
  address     VARCHAR(50) NOT NULL,
  CONSTRAINT PK_Customers PRIMARY KEY(custid)
);

INSERT INTO dbo.Customers(custid, companyname, phone, address)
VALUES
  (1, 'cust 1', '(111) 111-1111', 'address 1'),
  (2, 'cust 2', '(222) 222-2222', 'address 2'),
  (3, 'cust 3', '(333) 333-3333', 'address 3'),
  (4, 'cust 4', '(444) 444-4444', 'address 4'),
  (5, 'cust 5', '(555) 555-5555', 'address 5');

IF OBJECT_ID('dbo.CustomersStage', 'U') IS NOT NULL DROP TABLE dbo.CustomersStage;
GO

CREATE TABLE dbo.CustomersStage
(
  custid      INT         NOT NULL,
  companyname VARCHAR(25) NOT NULL,
  phone       VARCHAR(20) NOT NULL,
  address     VARCHAR(50) NOT NULL,
  CONSTRAINT PK_CustomersStage PRIMARY KEY(custid)
);

INSERT INTO dbo.CustomersStage(custid, companyname, phone, address)
VALUES
  (2, 'AAAAA', '(222) 222-2222', 'address 2'),
  (3, 'cust 3', '(333) 333-3333', 'address 3'),
  (5, 'BBBBB', 'CCCCC', 'DDDDD'),
  (6, 'cust 6 (new)', '(666) 666-6666', 'address 6'),
  (7, 'cust 7 (new)', '(777) 777-7777', 'address 7');

-- Запросы к таблицам
SELECT * FROM dbo.Customers;

SELECT * FROM dbo.CustomersStage;

-- Пример слияния №1: добавление несуществующих и обновление уже имеющихся записей 
MERGE INTO dbo.Customers AS TGT
USING dbo.CustomersStage AS SRC
  ON TGT.custid = SRC.custid
WHEN MATCHED THEN
  UPDATE SET
    TGT.companyname = SRC.companyname,
    TGT.phone = SRC.phone,
    TGT.address = SRC.address
WHEN NOT MATCHED THEN 
  INSERT (custid, companyname, phone, address)
  VALUES (SRC.custid, SRC.companyname, SRC.phone, SRC.address);

-- Запрос к таблице
SELECT * FROM dbo.Customers; 

-- Пример слияния №2: добавление несуществующих и обновление уже имеющихся
-- записей, а также удаление несуществующих исходных записей
MERGE dbo.Customers AS TGT
USING dbo.CustomersStage AS SRC
  ON TGT.custid = SRC.custid
WHEN MATCHED THEN
  UPDATE SET
    TGT.companyname = SRC.companyname,
    TGT.phone = SRC.phone,
    TGT.address = SRC.address
WHEN NOT MATCHED THEN 
  INSERT (custid, companyname, phone, address)
  VALUES (SRC.custid, SRC.companyname, SRC.phone, SRC.address)
WHEN NOT MATCHED BY SOURCE THEN
  DELETE;

-- Запрос к таблице
SELECT * FROM dbo.Customers; 

-- Пример слияния №3: добавление несуществующих и обновление уже
-- имеющихся записей, которые изменились
MERGE dbo.Customers AS TGT
USING dbo.CustomersStage AS SRC
  ON TGT.custid = SRC.custid
WHEN MATCHED AND 
       (   TGT.companyname <> SRC.companyname
        OR TGT.phone       <> SRC.phone
        OR TGT.address     <> SRC.address) THEN
  UPDATE SET
    TGT.companyname = SRC.companyname,
    TGT.phone = SRC.phone,
    TGT.address = SRC.address
WHEN NOT MATCHED THEN 
  INSERT (custid, companyname, phone, address)
  VALUES (SRC.custid, SRC.companyname, SRC.phone, SRC.address);

---------------------------------------------------------------------
-- Изменение данных с помощью табличных выражений
---------------------------------------------------------------------

UPDATE OD
  SET discount += 0.05
FROM dbo.OrderDetails AS OD
  JOIN dbo.Orders AS O
    ON OD.orderid = O.orderid
WHERE O.custid = 1;

-- ОТВ
WITH C AS
(
  SELECT custid, OD.orderid,
    productid, discount, discount + 0.05 AS newdiscount
  FROM dbo.OrderDetails AS OD
    JOIN dbo.Orders AS O
      ON OD.orderid = O.orderid
  WHERE O.custid = 1
)
UPDATE C
  SET discount = newdiscount;

-- Производная таблица
UPDATE D
  SET discount = newdiscount
FROM ( SELECT custid, OD.orderid,
         productid, discount, discount + 0.05 AS newdiscount
       FROM dbo.OrderDetails AS OD
         JOIN dbo.Orders AS O
           ON OD.orderid = O.orderid
       WHERE O.custid = 1 ) AS D;

-- Обновление с нумерацией строк
IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;
CREATE TABLE dbo.T1(id INT NOT NULL IDENTITY PRIMARY KEY, col1 INT, col2 INT);
GO

INSERT INTO dbo.T1(col1) VALUES(10),(20),(30);

SELECT * FROM dbo.T1;
GO

UPDATE dbo.T1
  SET col2 = ROW_NUMBER() OVER(ORDER BY col1);

/*
Сообщение 4108, уровень 15, состояние 1, строка 2
Оконные функции могут использоваться только в предложениях SELECT или ORDER BY.
*/
GO
  
WITH C AS
(
  SELECT col1, col2, ROW_NUMBER() OVER(ORDER BY col1) AS rownum
  FROM dbo.T1
)
UPDATE C
  SET col2 = rownum;

SELECT col1, col2 FROM dbo.T1;

---------------------------------------------------------------------
-- Изменение данных с использованием параметров TOP и OFFSET-FETCH
---------------------------------------------------------------------

IF OBJECT_ID('dbo.OrderDetails', 'U') IS NOT NULL DROP TABLE dbo.OrderDetails;
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;

CREATE TABLE dbo.Orders
(
  orderid        INT          NOT NULL,
  custid         INT          NULL,
  empid          INT          NOT NULL,
  orderdate      DATETIME     NOT NULL,
  requireddate   DATETIME     NOT NULL,
  shippeddate    DATETIME     NULL,
  shipperid      INT          NOT NULL,
  freight        MONEY        NOT NULL
    CONSTRAINT DFT_Orders_freight DEFAULT(0),
  shipname       NVARCHAR(40) NOT NULL,
  shipaddress    NVARCHAR(60) NOT NULL,
  shipcity       NVARCHAR(15) NOT NULL,
  shipregion     NVARCHAR(15) NULL,
  shippostalcode NVARCHAR(10) NULL,
  shipcountry    NVARCHAR(15) NOT NULL,
  CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);
GO

INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;

DELETE TOP(50) FROM dbo.Orders;

UPDATE TOP(50) dbo.Orders
  SET freight += 10.00;

-- Параметр TOP
WITH C AS
(
  SELECT TOP(50) *
  FROM dbo.Orders
  ORDER BY orderid
)
DELETE FROM C;

WITH C AS
(
  SELECT TOP(50) *
  FROM dbo.Orders
  ORDER BY orderid DESC
)
UPDATE C
  SET freight += 10.00;

-- Параметр OFFSET-FETCH
WITH C AS
(
  SELECT *
  FROM dbo.Orders
  ORDER BY orderid
  OFFSET 0 ROWS FETCH FIRST 50 ROWS ONLY
)
DELETE FROM C;

WITH C AS
(
  SELECT *
  FROM dbo.Orders
  ORDER BY orderid DESC
  OFFSET 0 ROWS FETCH FIRST 50 ROWS ONLY
)
UPDATE C
  SET freight += 10.00;

---------------------------------------------------------------------
-- Инструкция OUTPUT
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Команда INSERT в сочетании с инструкцией OUTPUT
---------------------------------------------------------------------

IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;
GO

CREATE TABLE dbo.T1
(
  keycol  INT          NOT NULL IDENTITY(1, 1) CONSTRAINT PK_T1 PRIMARY KEY,
  datacol NVARCHAR(40) NOT NULL
);

INSERT INTO dbo.T1(datacol)
  OUTPUT inserted.keycol, inserted.datacol
    SELECT lastname
    FROM HR.Employees
    WHERE country = N'США';

DECLARE @NewRows TABLE(keycol INT, datacol NVARCHAR(40));

INSERT INTO dbo.T1(datacol)
  OUTPUT inserted.keycol, inserted.datacol
  INTO @NewRows
    SELECT lastname
    FROM HR.Employees
    WHERE country = N'Великобритания';

SELECT * FROM @NewRows;

---------------------------------------------------------------------
-- Команда DELETE в сочетании с инструкцией OUTPUT
---------------------------------------------------------------------

IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;

CREATE TABLE dbo.Orders
(
  orderid        INT          NOT NULL,
  custid         INT          NULL,
  empid          INT          NOT NULL,
  orderdate      DATETIME     NOT NULL,
  requireddate   DATETIME     NOT NULL,
  shippeddate    DATETIME     NULL,
  shipperid      INT          NOT NULL,
  freight        MONEY        NOT NULL
    CONSTRAINT DFT_Orders_freight DEFAULT(0),
  shipname       NVARCHAR(40) NOT NULL,
  shipaddress    NVARCHAR(60) NOT NULL,
  shipcity       NVARCHAR(15) NOT NULL,
  shipregion     NVARCHAR(15) NULL,
  shippostalcode NVARCHAR(10) NULL,
  shipcountry    NVARCHAR(15) NOT NULL,
  CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);
GO

INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;

DELETE FROM dbo.Orders
  OUTPUT
    deleted.orderid,
    deleted.orderdate,
    deleted.empid,
    deleted.custid
WHERE orderdate < '20080101';

---------------------------------------------------------------------
-- Команда UPDATE в сочетании с инструкцией OUTPUT
---------------------------------------------------------------------

IF OBJECT_ID('dbo.OrderDetails', 'U') IS NOT NULL DROP TABLE dbo.OrderDetails;

CREATE TABLE dbo.OrderDetails
(
  orderid   INT           NOT NULL,
  productid INT           NOT NULL,
  unitprice MONEY         NOT NULL
    CONSTRAINT DFT_OrderDetails_unitprice DEFAULT(0),
  qty       SMALLINT      NOT NULL
    CONSTRAINT DFT_OrderDetails_qty DEFAULT(1),
  discount  NUMERIC(4, 3) NOT NULL
    CONSTRAINT DFT_OrderDetails_discount DEFAULT(0),
  CONSTRAINT PK_OrderDetails PRIMARY KEY(orderid, productid),
  CONSTRAINT CHK_discount  CHECK (discount BETWEEN 0 AND 1),
  CONSTRAINT CHK_qty  CHECK (qty > 0),
  CONSTRAINT CHK_unitprice CHECK (unitprice >= 0)
);
GO

INSERT INTO dbo.OrderDetails SELECT * FROM Sales.OrderDetails;

UPDATE dbo.OrderDetails
  SET discount += 0.05
OUTPUT
  inserted.productid,
  deleted.discount AS olddiscount,
  inserted.discount AS newdiscount
WHERE productid = 51;

---------------------------------------------------------------------
-- Команда MERGE в сочетании с инструкцией OUTPUT
---------------------------------------------------------------------

-- Сначала запустите листинг 8.2, чтобы создать таблицы Customers и CustomersStage

MERGE INTO dbo.Customers AS TGT
USING dbo.CustomersStage AS SRC
  ON TGT.custid = SRC.custid
WHEN MATCHED THEN
  UPDATE SET
    TGT.companyname = SRC.companyname,
    TGT.phone = SRC.phone,
    TGT.address = SRC.address
WHEN NOT MATCHED THEN 
  INSERT (custid, companyname, phone, address)
  VALUES (SRC.custid, SRC.companyname, SRC.phone, SRC.address)
OUTPUT $action AS theaction, inserted.custid,
  deleted.companyname AS oldcompanyname,
  inserted.companyname AS newcompanyname,
  deleted.phone AS oldphone,
  inserted.phone AS newphone,
  deleted.address AS oldaddress,
  inserted.address AS newaddress;

---------------------------------------------------------------------
-- Компоновка элементов языка DML
---------------------------------------------------------------------

IF OBJECT_ID('dbo.ProductsAudit', 'U') IS NOT NULL DROP TABLE dbo.ProductsAudit;
IF OBJECT_ID('dbo.Products', 'U') IS NOT NULL DROP TABLE dbo.Products;

CREATE TABLE dbo.Products
(
  productid    INT          NOT NULL,
  productname  NVARCHAR(40) NOT NULL,
  supplierid   INT          NOT NULL,
  categoryid   INT          NOT NULL,
  unitprice    MONEY        NOT NULL
    CONSTRAINT DFT_Products_unitprice DEFAULT(0),
  discontinued BIT          NOT NULL 
    CONSTRAINT DFT_Products_discontinued DEFAULT(0),
  CONSTRAINT PK_Products PRIMARY KEY(productid),
  CONSTRAINT CHK_Products_unitprice CHECK(unitprice >= 0)
);

INSERT INTO dbo.Products SELECT * FROM Production.Products;

CREATE TABLE dbo.ProductsAudit
(
  LSN INT NOT NULL IDENTITY PRIMARY KEY,
  TS  DATETIME NOT NULL DEFAULT(CURRENT_TIMESTAMP),
  productid INT NOT NULL,
  colname SYSNAME NOT NULL,
  oldval SQL_VARIANT NOT NULL,
  newval SQL_VARIANT NOT NULL
);

INSERT INTO dbo.ProductsAudit(productid, colname, oldval, newval)
  SELECT productid, N'unitprice', oldval, newval
  FROM (UPDATE dbo.Products
          SET unitprice *= 1.15
        OUTPUT 
          inserted.productid,
          deleted.unitprice AS oldval,
          inserted.unitprice AS newval
        WHERE supplierid = 1) AS D
  WHERE oldval < 20.0 AND newval >= 20.0;

SELECT * FROM dbo.ProductsAudit;

-- очистка
IF OBJECT_ID('dbo.OrderDetails', 'U') IS NOT NULL DROP TABLE dbo.OrderDetails;
IF OBJECT_ID('dbo.ProductsAudit', 'U') IS NOT NULL DROP TABLE dbo.ProductsAudit;
IF OBJECT_ID('dbo.Products', 'U') IS NOT NULL DROP TABLE dbo.Products;
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;
IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;
IF OBJECT_ID('dbo.Sequences', 'U') IS NOT NULL DROP TABLE dbo.Sequences;
IF OBJECT_ID('dbo.CustomersStage', 'U') IS NOT NULL DROP TABLE dbo.CustomersStage;
