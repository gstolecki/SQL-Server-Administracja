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

-- SQL Server 2019 i nowsze
select * from sys.dm_db_page_info( db_id('Baza'), 1, 368, 'detailed')

-- miejsce zajmowane przez tabelê
exec sp_spaceused 'Tab01';

-- widoki systemowe
select 
	so.name, so.object_id, sp.index_id, sp.partition_id, sp.hobt_id, sa.allocation_unit_id, sa.type_desc, sa.total_pages
from sys.objects so
	join sys.partitions sp on so.object_id = sp.object_id
	join sys.allocation_units sa on sa.container_id = sp.hobt_id
where so.name = 'Tab01';

select object_name(s.object_id) [TableName],
       s.row_count [RowCount],
       s.used_page_count [UsedPages],
       s.reserved_page_count [ReservedPages]
from sys.dm_db_partition_stats s
    join sys.tables t on s.object_id = t.object_id
where object_name(s.object_id) = 'Tab01';

select object_name(pa.object_id) TableName,
       pa.page_free_space_percent,
       pa.page_type_desc,
       pa.allocated_page_page_id,
       pa.extent_file_id
from sys.dm_db_database_page_allocations(db_id(), object_id('dbo.Tab01'), null, null, 'detailed') pa;

