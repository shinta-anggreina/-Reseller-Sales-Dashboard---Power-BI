/* ===========================================================
   FULL QUERY — Reseller Sales (AdventureWorksDW2022)
   Tujuan:
   1) Data checks (dupe, nilai negatif, orphan keys, NULL)
   2) Buat views dimensi & fakta yang rapi untuk Power BI
   3) Wide view
   =========================================================== */

---------------------------------------------------------------
-- 0) Target Database & Setup
---------------------------------------------------------------
USE AdventureWorksDW2022;
GO
SET NOCOUNT ON;
SET ANSI_WARNINGS ON;
SET QUOTED_IDENTIFIER ON;

-- Parameter batas tanggal untuk DimDate (bisa kamu ubah)
DECLARE @MinDate DATE = '2010-01-01';

---------------------------------------------------------------
-- 1) DATA QUALITY CHECKS (READ-ONLY QUERIES)
---------------------------------------------------------------

-- 1.1 Cek duplikasi level baris detail order
-- Kombinasi (SalesOrderNumber, SalesOrderLineNumber) seharusnya unik
SELECT
    SalesOrderNumber,
    SalesOrderLineNumber,
    COUNT(*) AS DuplicateCount
FROM dbo.FactResellerSales
GROUP BY SalesOrderNumber, SalesOrderLineNumber
HAVING COUNT(*) > 1;
-- >> Jika hasil tidak kosong, ada duplikasi yang perlu diinvestigasi.

-- 1.2 Cek angka negatif/aneh pada kolom utama
SELECT TOP (50) *
FROM dbo.FactResellerSales
WHERE OrderQuantity    < 0
   OR UnitPrice        < 0
   OR ExtendedAmount   < 0
   OR DiscountAmount   < 0
   OR TotalProductCost < 0
   OR SalesAmount      < 0;
-- >> AdventureWorks biasanya bersih; jika ada baris di sini, exclude via view (lihat langkah 3.2).

-- 1.3 Cek orphan keys (fakta tanpa pasangan dimensi)
-- Product
SELECT COUNT(*) AS OrphanProducts
FROM dbo.FactResellerSales f
LEFT JOIN dbo.DimProduct p ON p.ProductKey = f.ProductKey
WHERE p.ProductKey IS NULL;

-- Reseller
SELECT COUNT(*) AS OrphanResellers
FROM dbo.FactResellerSales f
LEFT JOIN dbo.DimReseller r ON r.ResellerKey = f.ResellerKey
WHERE r.ResellerKey IS NULL;

-- OrderDate
SELECT COUNT(*) AS OrphanOrderDates
FROM dbo.FactResellerSales f
LEFT JOIN dbo.DimDate d ON d.DateKey = f.OrderDateKey
WHERE d.DateKey IS NULL;

-- Territory
SELECT COUNT(*) AS OrphanTerritories
FROM dbo.FactResellerSales f
LEFT JOIN dbo.DimSalesTerritory t ON t.SalesTerritoryKey = f.SalesTerritoryKey
WHERE t.SalesTerritoryKey IS NULL;

-- 1.4 Cek NULL di kolom kunci & angka inti
SELECT
  SUM(CASE WHEN OrderDateKey   IS NULL THEN 1 ELSE 0 END) AS Null_OrderDateKey,
  SUM(CASE WHEN ProductKey     IS NULL THEN 1 ELSE 0 END) AS Null_ProductKey,
  SUM(CASE WHEN ResellerKey    IS NULL THEN 1 ELSE 0 END) AS Null_ResellerKey,
  SUM(CASE WHEN SalesTerritoryKey IS NULL THEN 1 ELSE 0 END) AS Null_TerritoryKey,
  SUM(CASE WHEN SalesAmount    IS NULL THEN 1 ELSE 0 END) AS Null_SalesAmount,
  SUM(CASE WHEN OrderQuantity  IS NULL THEN 1 ELSE 0 END) AS Null_OrderQty
FROM dbo.FactResellerSales;
-- >> Jika ada nilai > 0, audit sumbernya; untuk portfolio cukup di-exclude via view.

---------------------------------------------------------------
-- 2) VIEWS DIMENSI (CREATE OR ALTER)
---------------------------------------------------------------

-- 2.1 DimDate minimalis + label siap pakai
CREATE OR ALTER VIEW dbo.vw_DimDate AS
SELECT
    DateKey,
    FullDateAlternateKey              AS [Date],
    CalendarYear,
    MonthNumberOfYear,
    EnglishMonthName                  AS MonthName,
    LEFT(EnglishMonthName, 3)         AS MonthShort,
    CalendarQuarter                   AS Quarter,
    'Q' + CAST(CalendarQuarter AS varchar(1)) + ' ' + CAST(CalendarYear AS varchar(4)) AS QuarterLabel,
    FORMAT(FullDateAlternateKey, 'yyyy-MM') AS YearMonth
FROM dbo.DimDate
WHERE FullDateAlternateKey >= @MinDate;
GO

-- 2.2 DimProduct + hierarchy kategori
CREATE OR ALTER VIEW dbo.vw_DimProduct AS
SELECT
    p.ProductKey,
    p.ProductAlternateKey,
    p.EnglishProductName                   AS ProductName,
    p.Color,
    p.Size,
    p.StandardCost,
    p.ListPrice,
    ps.EnglishProductSubcategoryName       AS Subcategory,
    pc.EnglishProductCategoryName          AS Category
FROM dbo.DimProduct p
LEFT JOIN dbo.DimProductSubcategory ps
       ON ps.ProductSubcategoryKey = p.ProductSubcategoryKey
LEFT JOIN dbo.DimProductCategory pc
       ON pc.ProductCategoryKey = ps.ProductCategoryKey
WHERE p.Status = 'Current' OR p.Status IS NULL;  -- keep produk aktif
GO

-- 2.3 DimReseller + Geography
CREATE OR ALTER VIEW dbo.vw_DimReseller AS
SELECT
    r.ResellerKey,
    LTRIM(RTRIM(r.ResellerName))           AS ResellerName,
    r.BusinessType,
    g.City,
    g.StateProvinceName                    AS State,
    g.EnglishCountryRegionName             AS Country,
    r.NumberEmployees,
    r.OrderFrequency
FROM dbo.DimReseller r
LEFT JOIN dbo.DimGeography g
       ON g.GeographyKey = r.GeographyKey;
GO

-- 2.4 DimSalesTerritory
CREATE OR ALTER VIEW dbo.vw_DimSalesTerritory AS
SELECT
    SalesTerritoryKey,
    SalesTerritoryRegion   AS Territory,
    SalesTerritoryCountry  AS Country,
    SalesTerritoryGroup    AS [Group]
FROM dbo.DimSalesTerritory;
GO

---------------------------------------------------------------
-- 3) VIEW FAKTA BERSIH + KOLOM TURUNAN
---------------------------------------------------------------

CREATE OR ALTER VIEW dbo.vw_FactResellerSales_Clean AS
SELECT
    f.ResellerKey,
    f.ProductKey,
    f.OrderDateKey,
    f.DueDateKey,
    f.ShipDateKey,
    f.SalesTerritoryKey,
    f.SalesOrderNumber,
    f.SalesOrderLineNumber,
    f.OrderQuantity,
    f.UnitPrice,
    f.ExtendedAmount,
    f.DiscountAmount,
    f.TotalProductCost,
    f.SalesAmount,
    -- Turunan untuk analitik
    (f.SalesAmount - f.TotalProductCost)                                   AS GrossProfit,
    CASE WHEN f.ExtendedAmount > 0 THEN f.DiscountAmount / f.ExtendedAmount ELSE 0 END AS DiscountPct
FROM dbo.FactResellerSales f
WHERE
    -- Sanitasi angka (exclude nilai aneh)
    f.OrderQuantity    >= 0
    AND f.UnitPrice    >= 0
    AND f.ExtendedAmount >= 0
    AND f.SalesAmount  >= 0;
GO

---------------------------------------------------------------
-- 4) MEMBUAT VIEW UNTUK EKSPLORASI CEPAT
--    Catatan: untuk produksi Power BI tetap gunakan star schema
---------------------------------------------------------------

CREATE OR ALTER VIEW dbo.vw_ResellerSales_Wide AS
SELECT
    f.*,
    d.[Date],
    d.CalendarYear,
    d.MonthNumberOfYear,
    d.MonthName,
    d.QuarterLabel,
    d.YearMonth,
    pr.ProductName,
    pr.Subcategory,
    pr.Category,
    r.ResellerName,
    r.BusinessType,
    r.City,
    r.State,
    r.Country,
    t.Territory,
    t.[Group]
FROM dbo.vw_FactResellerSales_Clean f
LEFT JOIN dbo.vw_DimDate           d  ON d.DateKey            = f.OrderDateKey
LEFT JOIN dbo.vw_DimProduct        pr ON pr.ProductKey        = f.ProductKey
LEFT JOIN dbo.vw_DimReseller       r  ON r.ResellerKey        = f.ResellerKey
LEFT JOIN dbo.vw_DimSalesTerritory t  ON t.SalesTerritoryKey  = f.SalesTerritoryKey;
GO
