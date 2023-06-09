---------------------------------------------------------------------
-- Microsoft SQL Server 2012: Основы T-SQL
-- Глава 06 - Операторы работы с наборами
-- Решения
-- © Ицик Бен-Ган
---------------------------------------------------------------------

-- 1
-- Напишите запрос, который генерирует виртуальную вспомогательную таблицу
-- с десятью числами в диапазоне от 1 до 10, не используя при этом цикл.
-- Используемые таблицы: отсутствуют

--Ожидаемый результат
n
-----------
1
2
3
4
5
6
7
8
9
10

(10 row(s) affected)

-- Решение
SELECT 1 AS n
UNION ALL SELECT 2
UNION ALL SELECT 3
UNION ALL SELECT 4
UNION ALL SELECT 5
UNION ALL SELECT 6
UNION ALL SELECT 7
UNION ALL SELECT 8
UNION ALL SELECT 9
UNION ALL SELECT 10;

-- Решение при использовании инструкции VALUES 
SELECT n
FROM (VALUES(1),(2),(3),(4),(5),(6),(7),(8),(9),(10)) AS Nums(n);

-- 2
-- Напишите запрос, который возвращает пары «клиент-сотрудник»,
-- работавшие с заказами в январе, но не в феврале 2008 года.
-- Используемые таблицы: Orders 

--Ожидаемый результат
custid      empid
----------- -----------
1           1
3           3
5           8
5           9
6           9
7           6
9           1
12          2
16          7
17          1
20          7
24          8
25          1
26          3
32          4
38          9
39          3
40          2
41          2
42          2
44          8
47          3
47          4
47          8
49          7
55          2
55          3
56          6
59          8
63          8
64          9
65          3
65          8
66          5
67          5
70          3
71          2
75          1
76          2
76          5
80          1
81          1
81          3
81          4
82          6
84          1
84          3
84          4
88          7
89          4

(50 row(s) affected)

-- Решение
USE TSQL2012;

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20080101' AND orderdate < '20080201'

EXCEPT

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20080201' AND orderdate < '20080301';

-- 3
-- Напишите запрос, который возвращает пары «клиент-сотрудник»,
-- работавшие с заказами как в январе, так и в феврале 2008 года.
-- Используемые таблицы: Orders 

--Ожидаемый результат
custid      empid
----------- -----------
20          3
39          9
46          5
67          1
71          4

(5 row(s) affected)

-- Решение
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20080101' AND orderdate < '20080201'

INTERSECT

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20080201' AND orderdate < '20080301';

-- 4
-- Напишите запрос, который возвращает пары «клиент-сотрудник»,
-- работавшие с заказами в январе и феврале 2008 года, но не в 2007 году.
-- Используемые таблицы: Orders 

--Ожидаемый результат
custid      empid
----------- -----------
67          1
46          5

(2 row(s) affected)

-- Решение
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20080101' AND orderdate < '20080201'

INTERSECT

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20080201' AND orderdate < '20080301'

EXCEPT

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20070101' AND orderdate < '20080101';

-- Со скобками
(SELECT custid, empid
 FROM Sales.Orders
 WHERE orderdate >= '20080101' AND orderdate < '20080201'

 INTERSECT

 SELECT custid, empid
 FROM Sales.Orders
 WHERE orderdate >= '20080201' AND orderdate < '20080301')

EXCEPT

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20070101' AND orderdate < '20080101';

-- 5
-- Вам дан следующий запрос:
SELECT country, region, city
FROM HR.Employees

UNION ALL

SELECT country, region, city
FROM Production.Suppliers;

-- Вы должны добавить в него код, благодаря которому строки из таблицы
-- Employees будут находиться в результирующем наборе перед строками
-- из таблицы Suppliers. Кроме того, каждый сегмент должен быть
-- отсортирован по стране, региону и городу.
-- Используемые таблицы: Employees и Suppliers 

--Ожидаемый результат
country         region          city
--------------- --------------- ---------------
Великобритания  NULL            Лондон
Великобритания  NULL            Лондон
Великобритания  NULL            Лондон
Великобритания  NULL            Лондон
США             WA              Киркланд
США             WA              Редмонд
США             WA              Сиэтл
США             WA              Сиэтл
США             WA              Такома
Австралия       NSW             Сидней
Австралия       Виктория        Мельбурн
Бразилия        NULL            Сан-Паулу
Великобритания  NULL            Лондон
Великобритания  NULL            Манчестер
Германия        NULL            Берлин
Германия        NULL            Куксхафен
Германия        NULL            Франкфурт
Дания           NULL            Лингби
Испания         Астурия         Овьедо
Италия          NULL            Равенна
Италия          NULL            Салерно
Канада          Квебек          Монреаль
Канада          Квебек          Сент-Иасент
Нидерланды      NULL            Зандам
Норвегия        NULL            Сандвика
Сингапур        NULL            Сингапур
США             LA              Новый Орлеан
США             MA              Бостон
США             MI              Энн-Арбор
США             OR              Бенд
Финляндия       NULL            Лаппеэнранта
Франция         NULL            Анси
Франция         NULL            Монсо
Франция         NULL            Париж
Швеция          NULL            Гетеборг
Швеция          NULL            Стокгольм
Япония          NULL            Осака
Япония          NULL            Токио

(38 row(s) affected)

-- Решение
SELECT country, region, city
FROM (SELECT 1 AS sortcol, country, region, city
      FROM HR.Employees

      UNION ALL

      SELECT 2, country, region, city
      FROM Production.Suppliers) AS D
ORDER BY sortcol, country, region, city;
