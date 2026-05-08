-- 0. NUKE THE OLD DATABASE (Fresh Start)
DROP DATABASE IF EXISTS sales_db;

-- 1. Create Database
CREATE DATABASE sales_db;
USE sales_db;

-- 2. Create Tables (OLD & NEW)
CREATE TABLE fact_internet_sales_old (
    ProductKey INT,
    OrderDateKey INT,
    DueDateKey INT,
    ShipDateKey INT,
    CustomerKey INT,
    PromotionKey INT,
    CurrencyKey INT,
    SalesTerritoryKey INT,
    SalesOrderNumber VARCHAR(20),
    SalesOrderLineNumber INT,
    RevisionNumber INT,
    OrderQuantity INT,
    UnitPrice DECIMAL(18,4),
    ExtendedAmount DECIMAL(18,4),
    UnitPriceDiscountPct DECIMAL(18,4),
    DiscountAmount DECIMAL(18,4),
    ProductStandardCost DECIMAL(18,4),
    TotalProductCost DECIMAL(18,4),
    SalesAmount DECIMAL(18,4),
    TaxAmt DECIMAL(18,4),
    Freight DECIMAL(18,4),
    CarrierTrackingNumber VARCHAR(50),
    CustomerPONumber VARCHAR(50),
    OrderDate DATE,
    DueDate DATE,
    ShipDate DATE
);

CREATE TABLE fact_internet_sales_new LIKE fact_internet_sales_old;

-- 3. Enable File Load
SET GLOBAL local_infile = 1;

-- 4. Load CSV Files
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/FactInternetSales.csv'
INTO TABLE fact_internet_sales_old
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Fact_Internet_Sales_New.csv'
INTO TABLE fact_internet_sales_new
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- 5. Data Cleaning (Basic)
-- Remove NULL Sales Orders
DELETE FROM fact_internet_sales_old WHERE SalesOrderNumber IS NULL;
DELETE FROM fact_internet_sales_new WHERE SalesOrderNumber IS NULL;

-- Remove negative or zero quantity
DELETE FROM fact_internet_sales_old WHERE OrderQuantity <= 0;
DELETE FROM fact_internet_sales_new WHERE OrderQuantity <= 0;

-- 6. Merge (Append Data) - FIX APPLIED HERE 
-- Using UNION ALL to prevent it from deleting identical rows
CREATE TABLE fact_internet_sales AS
SELECT * FROM fact_internet_sales_old
UNION ALL
SELECT * FROM fact_internet_sales_new;

-- 7. Add Primary Key (Composite)
ALTER TABLE fact_internet_sales
ADD PRIMARY KEY (SalesOrderNumber, SalesOrderLineNumber);

-- 8. DATA MODELING (Star Schema)
-- Dimension: Product
CREATE TABLE dim_product AS
SELECT DISTINCT ProductKey
FROM fact_internet_sales;

ALTER TABLE dim_product ADD PRIMARY KEY (ProductKey);

-- Dimension: Customer
CREATE TABLE dim_customer AS
SELECT DISTINCT CustomerKey
FROM fact_internet_sales;

ALTER TABLE dim_customer ADD PRIMARY KEY (CustomerKey);

-- Dimension: Date
CREATE TABLE dim_date AS
SELECT DISTINCT OrderDateKey, OrderDate
FROM fact_internet_sales;

ALTER TABLE dim_date ADD PRIMARY KEY (OrderDateKey);

-- 9. Add Foreign Keys (Fact → Dimensions)
ALTER TABLE fact_internet_sales
ADD CONSTRAINT fk_product FOREIGN KEY (ProductKey) REFERENCES dim_product(ProductKey),
ADD CONSTRAINT fk_customer FOREIGN KEY (CustomerKey) REFERENCES dim_customer(CustomerKey),
ADD CONSTRAINT fk_orderdate FOREIGN KEY (OrderDateKey) REFERENCES dim_date(OrderDateKey);

-- 10. Validation
SELECT 'Total Rows Merged' AS Metric, COUNT(*) AS Value FROM fact_internet_sales
UNION ALL
SELECT 'Unique Orders' AS Metric, COUNT(DISTINCT SalesOrderNumber) AS Value FROM fact_internet_sales
UNION ALL
SELECT 'Total Sales Amount' AS Metric, SUM(SalesAmount) AS Value FROM fact_internet_sales;

SHOW VARIABLES LIKE 'datadir';