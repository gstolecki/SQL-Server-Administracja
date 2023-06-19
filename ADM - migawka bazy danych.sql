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

-- mo¿na przegl¹daæ dane w migawce
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

-- przywrócenie bazy danych z migawki
use master;
go
restore database Adm
  from database_snapshot = 'Adm_Snap';
go

-- sprawdzamy dane w oryginalnej bazie
use Adm;
select count(*) from Kom;
select top(100) * from Kom;

-- migawka nadal jest dostêpna
use Adm_Snap;
select count(*) from Kom;
select top(100) * from Kom;

-- usuwamy 150 tys. wierszy
use Adm;
delete top(150000) from Kom;
select count(*) from Kom;

-- tworzymy migawkê
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

-- jak siê czuj¹ migawki?
select count(*) from Adm_Snap.dbo.Kom;
select count(*) from Adm_Snap_2.dbo.Kom;

-- przywracamy bazê z pierwszej
use master;
go
restore database Adm
  from database_snapshot = 'Adm_Snap';
go
-- b³¹d!

-- z drugiej
use master;
go
restore database Adm
  from database_snapshot = 'Adm_Snap_2';
go
-- b³¹d!

-- WA¯NE
-- Bazê mo¿na przywróciæ z migawki tylko wtedy kiedy mamy jedn¹ migawkê!

-- usuwamy pierwsz¹ migawkê
drop database Adm_Snap;
go

-- odtwarzamy bazê z drugiej
use master;
go
restore database Adm
  from database_snapshot = 'Adm_Snap_2';
go
select count(*) from Adm.dbo.Kom;
go

