SELECT empid, firstname, lastname
FROM HR.Employees
WHERE (LEN(lastname) - LEN(REPLACE(lastname, '�', ''))) > 1;
