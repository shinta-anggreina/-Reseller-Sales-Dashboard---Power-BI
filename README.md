# 📊 Reseller Sales Dashboard

## 🌐 Overview
This portfolio project showcases my data visualization skills using **Power BI**.  
The dataset used in this project is sourced from the AdventureworksDW22 database.
The goal is to generate meaningful insights regarding reseller performance and present them in an interactive and visually appealing dashboard.  

## 📂 Data Source  
[Sourced Link](https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver17&tabs=ssms)  
The following information is included for analysis:  
### ✅ Fact Table (Main Transaction Table)
- `FactResellerSales` → the main source for sales amount, quantity, order value, and reseller performance  
### ✅ Dimension Tables (Supporting Dimensions)  
- `DimDate` → for time-based analysis (Year, Month, Quarter)  
- `DimReseller` → for reseller details (name, location, etc.)  
- `DimProduct` → for product details  
- `DimProductCategory` → for grouping products (e.g., Bikes, Accessories)  
- `DimProductSubcategory` → for product subcategories (e.g., Road Bikes, Helmets)  
- `DimGeography` → for country/region-based sales distribution (map visualization)  
- `DimCurrency` → to ensure analysis is restricted to USD  
  
Only transactions in USD are considered for consistency.  

## ⚙️ Tools and Technologies
- 📈 **Power BI**: For data visualization and dashboard creation  
- 📑 **SQL Server Management Studio**: For dataset preprocessing  

## 💡 Insights
The following insights were derived from the dashboard:  
- 💵 **Total Sales**: $80.45M across all transactions  
- 📦 **Total Orders**: 3,796 with an average order value of $21.19K  
- 🏆 **Reseller Performance**: Top resellers contributed significantly to total sales volume  
- 🌎 **Geographic Insights**: North America contributed the largest share of sales  
- 🚴 **Product Subcategories**: Road Bikes dominated in total order quantity compared to other categories  

## 📊 Visualizations
The Power BI dashboard includes the following visualizations:  
- 🧾 **KPI Cards**: Total Sales, Total Quantity, Total Orders, Average Order Value, Total Resellers  
- 📉 **Sales Trends**: Line chart showing sales amount over time  
- 🗺️ **Geographic Analysis**: Map visualization of sales by country  
- 📊 **Product Analysis**: Bar chart of order quantity by product subcategory  
- 👥 **Reseller Performance**: Detailed table and top reseller performance section  

This project was developed by:  
🎓 **Shinta Anggreina**  
📩 **Thank you for reviewing my Dashboard!** If you have any questions or need further details, feel free to reach out! 🚀
