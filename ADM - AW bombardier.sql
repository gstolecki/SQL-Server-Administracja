/*

	Administracja Microsoft SQL Server

	AdventureWorks bombardier
	Skrypt generuje ruch w bazie AW.

	(c) Grzegorz Stolecki

*/

-- WA¯NE!
-- Uruchamiaæ albo poprzez SQLCMD, albo z opcj¹ Results to Text (CTRL-T)
-- Najlepiej z u¿yciem SQLQueryStress.

use AdventureWorksDW2019;
go

select * from DimCustomer where YearlyIncome = 130000;
select * from DimCustomer where YearlyIncome = 70000;
select * from DimCustomer where YearlyIncome = 20000;
select * from DimCustomer where YearlyIncome = 80000;
select * from DimCustomer where YearlyIncome = 110000;
select * from DimCustomer where YearlyIncome = 100000;
select * from DimCustomer where YearlyIncome = 170000;

select * from DimCustomer where Gender = 'F';
select * from DimCustomer where Gender = 'M';

select * from FactInternetSales where SalesAmount > 100;
select * from FactInternetSales where SalesAmount < 100;
