/*

	Administracja Microsoft SQL Server

	Brent Ozar - FirstResponderKit
	Adam Machanic - WhoIsActive

	(c) Grzegorz Stolecki

*/

/*

	https://www.brentozar.com/first-aid/

	Instalacja: otw�rz i wykonaj skrypt z pliku
	Install-All-Scripts.sql
	w kontek�cie bazy master.

*/

-- lista aktywnych oraz blokuj�cych sesji
exec sp_BlitzWho;

-- wi�cej informacji
exec sp_BlitzWho
  @ExpertMode = 1;

/*

	WhoIsActive
	http://whoisactive.com/
	Pobierz z github: https://github.com/amachanic/sp_whoisactive/releases

*/

exec sp_WhoIsActive
  @get_plans = 1,
  @get_transaction_info = 1,
  @get_locks = 1,
  @get_additional_info = 1,
  @find_block_leaders = 1,
  @format_output = 0;

-- Aby zapisywa� wyniki do bazy danych nale�y najpierw uzyska�
-- struktur� tabeli dopasowan� do zestawu parametr�w.
declare @s varchar(max);
exec sp_WhoIsActive
  @get_plans = 1,
  @get_transaction_info = 1,
  @get_locks = 1,
  @get_additional_info = 1,
  @find_block_leaders = 1,
  @format_output = 0,
  @destination_table = 'WhoIsActive',
  @return_schema = 1,
  @schema = @s output;
select @s;

-- Nast�pnie tworzymy tabel�
use Monitoring;
create table WhoIsActive ( 
  [session_id] smallint NOT NULL, [sql_text] nvarchar(max) NULL, [login_name] nvarchar(128) NOT NULL,
  [wait_info] nvarchar(4000) NULL, [tran_log_writes] nvarchar(4000) NULL, [CPU] bigint NULL,
  [tempdb_allocations] bigint NULL, [tempdb_current] bigint NULL, [blocking_session_id] smallint NULL,
  [blocked_session_count] smallint NULL, [reads] bigint NULL, [writes] bigint NULL,
  [physical_reads] bigint NULL, [query_plan] xml NULL, [locks] xml NULL,
  [used_memory] bigint NOT NULL, [status] varchar(30) NOT NULL, [tran_start_time] datetime NULL,
  [implicit_tran] nvarchar(3) NULL, [open_tran_count] smallint NULL, [percent_complete] real NULL,
  [host_name] nvarchar(128) NULL, [database_name] nvarchar(128) NULL, [program_name] nvarchar(128) NULL,
  [additional_info] xml  NULL, [start_time] datetime NOT NULL, [login_time] datetime NULL,
  [request_id] int NULL,[collection_time] datetime NOT NULL);
go

-- Wykonanie procedury z zapisem do bazy danych
exec sp_WhoIsActive
  @get_plans = 1,
  @get_transaction_info = 1,
  @get_locks = 1,
  @get_additional_info = 1,
  @find_block_leaders = 1,
  @format_output = 0,
  @destination_table = 'WhoIsActive';


select * from WhoIsActive;


