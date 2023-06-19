/*

	Administracja Microsoft SQL Server

	Grupy plikowe i pliki

	(c) Grzegorz Stolecki

*/

use master;
go

-- jeœli testowa baza istnieje - usuwamy j¹
drop database if exists Baza;
go

-- utworzenie bazy danych, wszystkie opcje domyœlne
create database Baza
go

use Baza;
go

-- grupy plikowe
select * from sys.filegroups;

-- pliki
select * from sys.master_files where database_id = DB_ID('Baza');

-- dodanie nowej grupy plikowej
use [master]
go
alter database [Baza] add filegroup [ARCHIVE]
go
alter database [Baza] add filegroup [DATA]
go

-- sprawdzenie
use Baza;
select * from sys.filegroups;

use [master]
go

-- dodanie pliku do grupy plikowej
-- UWAGA na parametr "filename" - konieczne podanie prawid³owej œcie¿ki
alter database [Baza] 
add file 
	( name = N'Baza2', 
	  filename = N'E:\SQLDATA\MSSQL15.MSSQLSERVER\MSSQL\DATA\Baza2.ndf' , 
	  size = 8192KB , 
	  filegrowth = 65536KB ) to filegroup [DATA]
GO

alter database [Baza] 
add file 
	( name = N'BazaArch', 
	  filename = N'E:\SQLDATA\MSSQL15.MSSQLSERVER\MSSQL\DATA\BazaArch.ndf' , 
	  size = 8192KB , 
	  filegrowth = 65536KB ) to filegroup [ARCHIVE]
GO

alter database [Baza] 
add file 
	( name = N'BazaArch2', 
	  filename = N'E:\SQLDATA\MSSQL15.MSSQLSERVER\MSSQL\DATA\BazaArch2.ndf' , 
	  size = 8192KB , 
	  filegrowth = 65536KB ) to filegroup [ARCHIVE]
GO

-- sprawdzenie
select * from sys.master_files where database_id = DB_ID('Baza');

-- ustawienie domyœlnej grupy plikowej
-- W tej grupie plikowej bêd¹ tworzone obiekty, jeœli nie podamy inaczej.
use [Baza]
go
alter database [Baza] modify filegroup [DATA] default
go

-- utworzenie tabeli w domyœlnej grupie plikowej
create table Tab01(tekst nvarchar(max));

-- utworzenie tabeli we wskazanej grupie plikowej
create table Tab01_Arch(tekst nvarchar(max)) on [ARCHIVE];

-- za³adowanie 1000 wierszy do obu tabel
insert Tab01(tekst)
select top(1000) text from sys.messages;

insert Tab01_Arch(tekst)
select top(1000) text from sys.messages;

-- u¿ywaj¹c funkcji %%physloc%% sprawdzimy, 
-- w którym pliku znajduje siê konkretny wiersz
select 
	sys.fn_physLocFormatter(%%physloc%%), 
	substring(sys.fn_physLocFormatter(%%physloc%%), 2, 1), 
	tekst 
from Tab01;

-- tylko jeden numer pliku
select distinct
	substring(sys.fn_physLocFormatter(%%physloc%%), 2, 1)
from Tab01;

-- dwa numery pliku
select distinct
	substring(sys.fn_physLocFormatter(%%physloc%%), 2, 1)
from Tab01_Arch;

