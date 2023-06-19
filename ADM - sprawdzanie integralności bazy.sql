/*

	Administracja Microsoft SQL Server

	Sprawdzanie integralno�ci bazy danych

	(c) Grzegorz Stolecki

*/


-- wykrywanie uszkodze� w bazie danych
dbcc checkdb;
dbcc checkdb('AdventureWorksDW2019');

/*

Do nast�pnego eksperymentu b�dzie potrzebny edytor pliku:
http://www.chmaas.handshake.de/delphi/freeware/xvi32/xvi32.htm

*/

-- testowa baza danych
use master;
go
drop database if exists Baza;
go
create database Baza;
go
use Baza;
go

create table Tab(tekst varchar(50));

insert Tab values 
  ('Pierwszy wiersz'), 
  ('Dane w wierszu s� OK'), 
  ('Piesek szczeka pod domem');

select * from Tab

use master;

-- pe�na kopia zapasowa bazy
backup database Baza 
  to disk = N'c:\bak\baza_ok.bak'
  with checksum;


-- teraz popsujemy baz�

-- lokalizacja plik�w bazy
select * from sys.master_files
where database_id = db_id('Baza');

-- odpinamy baz�
alter database Baza set offline;

-- modyfikujemy jedn� literk�
-- u�yj XVI32

-- podpinamy baz�
alter database Baza set online;

use Baza;
select * from Tab;
-- b��d 824, Level 24 !!!!

-- tabela podejrzanych stron w msdb
select * from msdb.dbo.suspect_pages;

-- czy mo�emy wykona� kopi� zapasow�?
-- nie sprawdzaj�c sum kontrolnych: TAK!
-- NIEDOBRZE! Mamy w kopii zapasowej uszkodzon� baz�!
backup database Baza 
  to disk = N'c:\bak\baza_uszk.bak';

-- sprawdzenie integralno�ci, zostawiamy tylko komunikaty b��d�w
dbcc checkdb('Baza') with no_infomsgs;

-- pr�ba backup z sumami kontrolnymi
backup database Baza 
  to disk = N'c:\bak\baza_uszk2.bak'
  with checksum;

-- mo�na wykona� kopi� pomijaj�c b��dy
backup database Baza 
  to disk = N'c:\bak\baza_uszk2.bak'
  with checksum, continue_after_error;

-- informacja o b��dach zostaje zalogowana
-- xp_readerrorlog lognumber, logtype, search1, search2, date_start, date_end, sort
exec xp_readerrorlog 0, 1, N'', N'', null, null, N'desc'

-- odtworzenie uszkodzonej strony z dobrej kopii zapasowej
-- 1. odtworzenie strony
restore database Baza 
	page='1:280' 
	from disk = N'c:\bak\baza_ok.bak' 
	with file = 1, norecovery, stats = 5;
-- 2. kopia tail-of-the-log
backup log Baza
	to disk = N'C:\BAK\Baza_LogBackup_2023-06-19_15-15-01.bak' 
	with name = N'Baza_LogBackup_2023-06-19_15-15-01', stats = 5;
-- 3. odtworzenie logu
restore log Baza 
	from disk = N'C:\BAK\Baza_LogBackup_2023-06-19_15-15-01.bak';

-- sprawdzenie odtworzenia
select * from Baza.dbo.Tab;


GO


-- czyszczenie
use master;
go
drop database Baza;
go
