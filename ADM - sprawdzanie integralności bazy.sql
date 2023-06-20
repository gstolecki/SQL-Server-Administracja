/*

	Administracja Microsoft SQL Server

	Sprawdzanie integralnoœci bazy danych

	(c) Grzegorz Stolecki

*/


-- wykrywanie uszkodzeñ w bazie danych
dbcc checkdb;
dbcc checkdb('AdventureWorksDW2019');

-- tryb Emergency - tylko cz³onkowie roli sysadmin maj¹ dostêp do bazy
--                - baza tylko do odczytu
alter database AdventureWorksDW2019 set emergency;

alter database AdventureWorksDW2019 set single_user;

-- wykrywanie uszkodzeñ w bazie danych
-- zezwalamy na stratê danych przy naprawie
-- baza musi byæ w trybie single_user
dbcc checkdb('AdventureWorksDW2019', REPAIR_ALLOW_DATA_LOSS)

-- przeprowadza tylko naprawy nie powoduj¹ce utraty danych
dbcc checkdb('AdventureWorksDW2019', REPAIR_REBUILD)

alter database AdventureWorksDW2019 set multi_user;
alter database AdventureWorksDW2019 set online;

/*

Do nastêpnego eksperymentu bêdzie potrzebny edytor pliku:
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
  ('Dane w wierszu s¹ OK'), 
  ('Piesek szczeka pod domem');

select * from Tab

use master;

-- pe³na kopia zapasowa bazy
backup database Baza 
  to disk = N'c:\bak\baza_ok.bak'
  with checksum;


-- teraz popsujemy bazê

-- lokalizacja plików bazy
select * from sys.master_files
where database_id = db_id('Baza');

-- odpinamy bazê
alter database Baza set offline;

-- modyfikujemy jedn¹ literkê
-- u¿yj XVI32

-- podpinamy bazê
alter database Baza set online;

use Baza;
select * from Tab;
-- b³¹d 824, Level 24 !!!!

-- tabela podejrzanych stron w msdb
select * from msdb.dbo.suspect_pages;

-- czy mo¿emy wykonaæ kopiê zapasow¹?
-- nie sprawdzaj¹c sum kontrolnych: TAK!
-- NIEDOBRZE! Mamy w kopii zapasowej uszkodzon¹ bazê!
backup database Baza 
  to disk = N'c:\bak\baza_uszk.bak';

-- sprawdzenie integralnoœci, zostawiamy tylko komunikaty b³êdów
dbcc checkdb('Baza') with no_infomsgs;

-- próba backup z sumami kontrolnymi
backup database Baza 
  to disk = N'c:\bak\baza_uszk2.bak'
  with checksum;

-- mo¿na wykonaæ kopiê pomijaj¹c b³êdy
backup database Baza 
  to disk = N'c:\bak\baza_uszk2.bak'
  with checksum, continue_after_error;

-- informacja o b³êdach zostaje zalogowana
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
