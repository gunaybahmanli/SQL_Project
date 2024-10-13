/*This project aims to analyze sales data and compare actual sales with predefined sales targets to assess 
performance across various categories and geographical regions. 
By querying and transforming data from three different CSV files—List of Orders, Order Details, 
and Sales Target—this project provides insights into sales performance, profitability, and goal achievement.*/


--1.Find the monhtly cumulative sales for each category

with MonthlySales as (
	select
		DATEPART(month, lo.Order_Date) as OrderMonth,
		od.Category,
		SUM(od.Amount) as MonthlySales
	from ListofOrders lo
	join OrderDetails od on lo.Order_ID = od.Order_ID
	group by DATEPART(month, lo.Order_Date), od.Category
)
select
	OrderMonth,
	Category,
	SUM(MonthlySales) over (Partition by Category order by OrderMonth) as CumulativeSales
from MonthlySales;

--Calculate the year-over-year (Yoy) growth in profit for each category

with YearlyProfit as (
	select
		DATEPART(year, lo.Order_Date) as OrderYear,
		od.Category,
		SUM(od.Profit) as YearlyProfit
	from ListofOrders lo
	join OrderDetails od on lo.Order_ID = od.Order_ID
	group by DATEPART(year, lo.Order_Date), od.Category
)
select
	OrderYear,
	Category,
	YearlyProfit,
	LAG(YearlyProfit, 1) over (Partition by category order by OrderYear) as PreviousYearProfit,
	((YearlyProfit - LAG(YearlyProfit, 1) over (partition by Category order by OrderYear)) /
	LAG(YearlyProfit, 1) over (partition by Category order by OrderYear)) * 100 as YoYGrowth
from YearlyProfit;


--Identify which customers consistently purchase products from the most profitable categories

with CategoryProfit as (
	select
		od.Category,
		SUM(od.Profit) as TotalProfit
	from OrderDetails od
	group by od.Category
),  TopCategories as (
	select Category
	from CategoryProfit
	where TotalProfit = (select MAX(TotalProfit) from CategoryProfit)
)
select lo.CustomerName, COUNT(distinct lo.Order_ID) as NumberofOrders
from ListofOrders lo
join OrderDetails od on lo.Order_ID = od.Order_ID
where od.Category in (select Category from TopCategories)
group by lo.CustomerName
having COUNT(Distinct lo.Order_ID) > 1;

--Calculate the percentage contribution of each customer's sales to the total company sales

with CustomerSales as (
	select lo.CustomerName, SUM(od.Amount) as TotalSales
	from ListofOrders lo
	join OrderDetails od on lo.Order_ID = od.Order_ID
	group by lo.CustomerName
),  TotalCompanySales as (
	select SUM(TotalSales) as CompanyTotalSales
	from CustomerSales
)
select
	cs.CustomerName,
	(cs.TotalSales / tcs.CompanyTotalSales) * 100 as SalesContributionPercent
from CustomerSales cs, TotalCompanySales tcs;

--Rank customers based on their totaal spending and assign them into spending tiers

with CustomerSpending as (
	select lo.CustomerName, SUM(od.Amount) as TotalSpending
	from ListofOrders lo
	join OrderDetails od on lo.Order_ID = od.Order_ID
	group by lo.CustomerName
)
select
	CustomerName,
	TotalSpending,
	NTILE(5) over (order by TotalSpending DESC) as SpendingTier
from CustomerSpending;

--Calculate the total sales amount for each month

with MonthlySales as (
select DATEPART(month, lo.Order_Date) as OrderMonth, 
od.Category,
SUM(od.Amount) as TotalSales
from ListofOrders lo
join OrderDetails od on lo.Order_ID = od.Order_ID
group by DATEPART(month, lo.Order_date), od.Category
)
select 
	OrderMonth,
	Category,
	TotalSales
from MonthlySales
order by OrderMonth;


