/*

	Administracja Microsoft SQL Server

	Migawki (snapshot) baz danych

	(c) Grzegorz Stolecki

*/

-- przygotowanie bazy testowej
use master;
go
drop database if exists Adm;
go
create database Adm;
go
use Adm;
go

select * into Kom from sys.messages;
select count(*) from Kom;

-- utworzenie migawki bazy danych
create database Adm_Snap on
  (name = Adm, filename = 'c:\bak\Adm_snap.dbsnap' )
as snapshot of Adm;

-- mo�na przegl�da� dane w migawce
use Adm_Snap;
select count(*) from Kom;
select top(100) * from Kom;

-- wracamy do oryginalnej bazy i modyfikujemy dane
use Adm;
truncate table Kom;
select * from Kom;

-- sprawdzamy dane w migawce
use Adm_Snap;
select count(*) from Kom;
select top(100) * from Kom;

-- przywr�cenie bazy danych z migawki
use master;
go
restore database Adm
  from database_snapshot = 'Adm_Snap';
go

-- sprawdzamy dane w oryginalnej bazie
use Adm;
select count(*) from Kom;
select top(100) * from Kom;

-- migawka nadal jest dost�pna
use Adm_Snap;
select count(*) from Kom;
select top(100) * from Kom;

-- usuwamy 150 tys. wierszy
use Adm;
delete top(150000) from Kom;
select count(*) from Kom;

-- tworzymy migawk�
create database Adm_Snap_2 on
  (name = Adm, filename = 'c:\bak\Adm_snap_2.dbsnap' )
as snapshot of Adm;

-- spis baz danych
select 
  name, database_id, source_database_id, is_read_only
from sys.databases
where name like 'adm%';

-- wracamy do oryginalnej bazy i modyfikujemy dane
use Adm;
truncate table Kom;
select * from Kom;

-- jak si� czuj� migawki?
select count(*) from Adm_Snap.dbo.Kom;
select count(*) from Adm_Snap_2.dbo.Kom;

-- przywracamy baz� z pierwszej
use master;
go
restore database Adm
  from database_snapshot = 'Adm_Snap';
go
-- b��d!

-- z drugiej
use master;
go
restore database Adm
  from database_snapshot = 'Adm_Snap_2';
go
-- b��d!

-- WA�NE
-- Baz� mo�na przywr�ci� z migawki tylko wtedy kiedy mamy jedn� migawk�!

-- usuwamy pierwsz� migawk�
drop database Adm_Snap;
go

-- odtwarzamy baz� z drugiej
use master;
go
restore database Adm
  from database_snapshot = 'Adm_Snap_2';
go
select count(*) from Adm.dbo.Kom;
go

