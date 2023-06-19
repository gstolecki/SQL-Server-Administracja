/*

	Administracja Microsoft SQL Server

	Zasada dzia³ania dziennika transakcyjnego

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

-- model odtwarzania bazy
select 
	database_id, 
	name, 
	recovery_model, 
	recovery_model_desc 
from sys.databases where name = 'Baza';

-- UWAGA!
-- Nale¿y wykonaæ pe³n¹ kopiê zapasow¹ bazy danych, 
-- aby model odtwarzania zacz¹³ w pe³ni funkcjonowaæ.

-- kopia zapasowa
backup database Baza 
	to disk = 'C:\BAK\Baza_Full_001.bak';

-- tworzymy tabelê
use Baza;
go
create table Tab01(id int, tekst nvarchar(200));
go

-- odczyt dziennika
select * from fn_dblog(null, null);

-- tryb odtwarzania FULL
--   jedyny sposób przyciêcia dziennika to kopia zapasowa
--   pozwala odtworzyæ bazê danych na dowolny moment w czasie

-- kopia zapasowa dziennika
backup log Baza 
	to disk = 'C:\BAK\Baza_log_001.trn';

-- odczyt dziennika
select * from fn_dblog(null, null);

-- checkpoint
--  Zapisuje oczekuj¹ce zmiany z bufora na dysk
--  Skutek uboczny: wyczyszczenie dziennika z transakcji
--  oczekuj¹cych na zapis.
checkpoint;

-- odczyt dziennika
select * from fn_dblog(null, null);

-- dodajemy wiersz do tabeli
insert Tab01 values(8, 'AAAAAAAAA');
select * from Tab01;

-- odczyt dziennika
select * from fn_dblog(null, null);

-- gdzie jest nasza transakcja?
--  mo¿na poszukaæ operacji na naszej tabeli [AllocUnitName]
select * from fn_dblog(null, null) where AllocUnitName = 'dbo.Tab01';
select * from fn_dblog(null, null) where [Transaction ID] = '0000:00000429';

-- dziennik nie zawiera wykonanych instrukcji SQL
-- zawiera efekty ich dzia³ania jako modyfikacje bajtów na stronach bazy

-- jak wygl¹da rollback?
begin transaction

	select * from fn_dblog(null, null) where Operation = 'LOP_BEGIN_XACT'
	order by [Begin Time] desc;
	-- nie ma jeszcze nic w dzienniku
	-- logowanie zacznie siê po pierwszej modyfikacji

	insert Tab01 values(9, 'BBBBBBBB');

	select * from fn_dblog(null, null) where Operation = 'LOP_BEGIN_XACT'
	order by [Begin Time] desc;

	select * from fn_dblog(null, null) where [Transaction ID] = '0000:0000042c';
	-- jest LOP_BEGIN_XACT
	-- jest LOP_INSERT_ROWS

-- wycofanie transakcji
rollback;

select * from fn_dblog(null, null) where [Transaction ID] = '0000:0000042c';
-- pojawi³ siê zapis kompensuj¹cy - LOP_DELETE_ROWS

