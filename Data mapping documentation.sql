USE AdventureWorks2019;



CREATE TABLE DimEmployee 
(
    EmployeeKey INT PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    JobTitle VARCHAR(50),
    Department VARCHAR(50)
);





CREATE TABLE StageDimEmployee 
(
    EmployeeKey INT PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    JobTitle VARCHAR(50),
    Department VARCHAR(50)
);



INSERT INTO StageDimEmployee (EmployeeKey, FirstName, LastName, JobTitle, Department)
SELECT DISTINCT HumanResources.Employee.BusinessEntityID, 
Person.Person.FirstName, 
Person.Person.LastName, 
HumanResources.Employee.JobTitle, 
HumanResources.Department.Name
FROM HumanResources.Employee
INNER JOIN 
    Person.Person 
    ON HumanResources.Employee.BusinessEntityID = Person.Person.BusinessEntityID
INNER JOIN 
    HumanResources.EmployeeDepartmentHistory 
    ON HumanResources.Employee.BusinessEntityID = HumanResources.EmployeeDepartmentHistory.BusinessEntityID
INNER JOIN 
    HumanResources.Department 
    ON HumanResources.EmployeeDepartmentHistory.DepartmentID = HumanResources.Department.DepartmentID
WHERE  HumanResources.EmployeeDepartmentHistory.EndDate IS NULL AND HumanResources.Employee.BusinessEntityID IS NOT NULL;


INSERT INTO DimEmployee
SELECT EmployeeKey, FirstName, LastName, JobTitle, Department 
FROM StageDimEmployee


SELECT * from DimEmployee


-- Product -- 
select 
p.ProductID as ProductKey,
p.Name as ProductName,
pc.Name as ProductCategory,  
	ps.Name as ProductSubCategory, 
	p.ListPrice
from 
	Production.Product as p
	inner join Production.ProductSubcategory as ps 
	on p.ProductSubcategoryID = ps.ProductSubcategoryID
	inner join Production.ProductCategory as pc 
	on pc.ProductCategoryID = ps.ProductCategoryID
WHERE
     p.ProductID IS NOT NULL
    OR p.Name IS NOT NULL
    OR pc.Name IS NOT NULL
    OR ps.Name IS NOT NULL
    OR p.ListPrice IS NOT NULL;

CREATE TABLE StageDimProduct (
ProductKey INT PRIMARY KEY,
    ProductName VARCHAR(50),
    ProductCategory VARCHAR(50),
    ProductSubcategory VARCHAR(50),
    ListPrice DECIMAL(10,2)
);


INSERT INTO StageDimProduct (ProductKey, ProductName,ProductCategory,ProductSubcategory,ListPrice)
SELECT 
ROW_NUMBER() OVER (ORDER BY p.Name) as ProductKey,
p.Name as ProductName,
pc.Name as ProductCategory,
ps.Name as ProductSubcategory,
p.ListPrice
FROM
AdventureWorks2019.Production.Product as p
INNER JOIN AdventureWorks2019.Production.ProductSubcategory as ps ON
p.ProductSubcategoryID = ps.ProductSubcategoryID
INNER JOIN AdventureWorks2019.Production.ProductCategory as pc ON 
ps.ProductCategoryID = pc.ProductCategoryID
WHERE 
p.ProductID IS NOT NULL
OR
p.Name IS NOT NULL
OR pc.Name IS NOT NULL
OR ps.Name IS NOT NULL
OR pc.Name IS NOT NULL;

SELECT *
FROM StageDimProduct;


Create TABLE DimProduct
(
    ProductKey INT PRIMARY KEY,
    ProductName VARCHAR(50),
    ProductCategory VARCHAR(50),
    ProductSubcategory VARCHAR(50),
    ListPrice DECIMAL(10,2)
);

INSERT INTO DimProduct (ProductKey, ProductName, ProductCategory, ProductSubcategory,ListPrice)
SELECT *
FROM StageDimProduct;

SELECT * from 
DimProduct



--creating the DimCustomer table
CREATE TABLE DimCustomer
(
 CustomerKey INT PRIMARY KEY,
 FirstName VARCHAR(50),
 LastName VARCHAR(50),
 City VARCHAR(50),
 State VARCHAR(50),
 Country VARCHAR(50)
);

--extract the data from adventure works 
use AdventureWorks2019
select pp.FirstName, pp. LastName, pa.City, sp.Name as StateProvinceName, cr. Name as CountryRegionName from
Person. BusinessEntityAddress as bea
inner join Person.Address as pa on pa.AddressID = bea.AddressID
inner join Person. BusinessEntityContact as bec on bec. BusinessEntityID = bea.
BusinessEntityID
inner join Person.Person as pp on pp. BusinessEntityID = bec.PersonID
inner join Sales.Customer as sc on sc.PersonID = pp. BusinessEntityID
inner join Person. StateProvince as sp on sp. StateProvinceID = pa. StateProvinceID
inner join Person.CountryRegion as cr on cr. CountryRegionCode = sp. CountryRegionCode
where not pp.FirstName is null or pp. LastName is null or pa.City is null or sp.Name is null
or cr.Name is null

-- Create the StageDimCustomer temporary table
CREATE TABLE StageDimCustomer (
 CustomerKey INT PRIMARY KEY,
 FirstName VARCHAR(50),
 LastName VARCHAR(50),
 City VARCHAR(50),
 State VARCHAR(50),
 Country VARCHAR(50)
);


-- Insert the extracted data into StageDimCustomer and tranform the data 
INSERT INTO StageDimCustomer (CustomerKey,FirstName, LastName, City, State,
Country)
SELECT
 ROW_NUMBER() OVER (ORDER BY pp.FirstName, pp.LastName) AS CustomerKey,
 pp.FirstName,
 pp.LastName,
 pa.City,
 sp.Name AS StateProvinceName,
 cr.Name AS CountryRegionName
FROM
 AdventureWorks2019.Person.BusinessEntityAddress AS bea
 INNER JOIN AdventureWorks2019.Person.Address AS pa ON pa.AddressID = bea.AddressID
 INNER JOIN AdventureWorks2019.Person.BusinessEntityContact AS bec ON
bec.BusinessEntityID = bea.BusinessEntityID
 INNER JOIN AdventureWorks2019.Person.Person AS pp ON pp.BusinessEntityID = bec.PersonID
 INNER JOIN AdventureWorks2019.Person.StateProvince AS sp ON sp.StateProvinceID =
pa.StateProvinceID
 INNER JOIN AdventureWorks2019.Person.CountryRegion AS cr ON cr.CountryRegionCode =
sp.CountryRegionCode
WHERE
 NOT pp.FirstName IS NULL
 OR NOT pp.LastName IS NULL
 OR NOT pa.City IS NULL
 OR NOT sp.Name IS NULL
 OR NOT cr.Name IS NULL

 SELECT * FROM StageDimCustomer;

 --Insert the transformed data into the DimCustomer
 INSERT INTO DimCustomer
 SELECT CustomerKey, FirstName, LastName, City, State, Country
 FROM StageDimCustomer


 SELECT * from DimCustomer


 -- Date --

CREATE TABLE StageDimDate (
    DateKey INT PRIMARY KEY IDENTITY(1,1),
    FullDate DATE,
    DayOfWeek VARCHAR(10),
    MonthName VARCHAR(20),
    QuarterName VARCHAR(20),
    Year INT
);


INSERT INTO StageDimDate (FullDate, DayOfWeek, MonthName, QuarterName, Year)
SELECT 
    OrderDates AS FullDate,
    DATENAME(WEEKDAY, OrderDates) AS DayOfWeek,
    DATENAME(MONTH, OrderDates) AS MonthName,
    CONCAT('Q', DATEPART(QUARTER, OrderDates)) AS QuarterName,
    YEAR(OrderDates) AS Year
FROM 
    (SELECT DISTINCT 
        CAST(OrderDate AS DATE) AS OrderDates
     FROM Sales.SalesOrderHeader
     UNION 
     SELECT DISTINCT 
        CAST(DueDate AS DATE) AS OrderDates
     FROM Sales.SalesOrderHeader
     UNION 
     SELECT DISTINCT 
        CAST(ShipDate AS DATE) AS OrderDates
     FROM Sales.SalesOrderHeader) AS Dates;

	select * from StageDimDate

CREATE TABLE DimDate (
    DateKey INT PRIMARY KEY IDENTITY(1,1),
    FullDate DATE,
    DayOfWeek VARCHAR(10),
    MonthName VARCHAR(20),
    QuarterName VARCHAR(20),
    Year INT
);

INSERT INTO DimDate ( FullDate, DayOfWeek, MonthName, QuarterName, Year)
SELECT  FullDate, DayOfWeek, MonthName, QuarterName, Year FROM StageDimDate;

Select * FROM DimDate;



CREATE TABLE Sales (
    SalesKey INT,
    OrderDateKey INT,
    DueDateKey INT,
    ShipDateKey INT,
    ProductKey INT,
    CustomerKey INT,
    EmployeeKey INT,
    SalesQuantity INT,
    SalesAmount DECIMAL(18,2),
    DiscountAmount DECIMAL(18,2)
);

INSERT INTO Sales (SalesKey, OrderDateKey, DueDateKey, ShipDateKey, ProductKey, CustomerKey, EmployeeKey, SalesQuantity, SalesAmount, DiscountAmount)
SELECT 
    soh.SalesOrderID,
    CAST(CONVERT(varchar, soh.OrderDate, 112) AS INT),
    CAST(CONVERT(varchar, soh.DueDate, 112) AS INT),
    CAST(CONVERT(varchar, soh.ShipDate, 112) AS INT),
    sod.ProductID,
    soh.CustomerID,
    soh.SalesPersonID,
    sod.OrderQty,
    sod.LineTotal,
    sod.UnitPriceDiscount
FROM AdventureWorks2019.Sales.SalesOrderHeader soh
JOIN AdventureWorks2019.Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID;



-- Load data into Sales
INSERT INTO Sales (SalesKey, OrderDateKey, DueDateKey, ShipDateKey, ProductKey, CustomerKey, EmployeeKey, SalesQuantity, SalesAmount, DiscountAmount)
SELECT SalesKey, OrderDateKey, DueDateKey, ShipDateKey, ProductKey, CustomerKey, EmployeeKey, SalesQuantity, SalesAmount, DiscountAmount FROM Sales;

select * from Sales; 