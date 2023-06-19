/*

	Administracja Microsoft SQL Server

	Fizyczna struktura bazy danych

	(c) Grzegorz Stolecki

*/

-- testowa baza danych
use master;
go
drop database if exists Baza;
go

create database Baza;
go

-- pliki bazy danych
select * from sys.master_files where database_id = db_id('Baza');

-- tworzymy tabelê
use Baza;
go
create table Tab01(id int, tekst nvarchar(200));
go

-- wstawiamy wiersze
insert Tab01
select top(50) message_id, left(text,200) from sys.messages
where language_id = 1045;

select * from Tab01;

-- fizyczna lokalizacja wiersza w bazie
select 
	sys.fn_physLocFormatter(%%physloc%%) [RID], 
	tekst 
from Tab01;

-- RID (numer pliku:numer strony:numer slotu)

-- odczyt zawartoœci strony bazy danych
dbcc traceon(3604)
dbcc page (Baza,1,368,3)

