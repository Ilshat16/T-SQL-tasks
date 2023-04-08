SELECT empid, firstname, lastname
FROM HR.Employees
WHERE (LEN(lastname) - LEN(REPLACE(lastname, 'î', ''))) > 1;
