/*

	Administracja Microsoft SQL Server

	Kopie zapasowe

	(c) Grzegorz Stolecki

*/

-- przygotowanie bazy do test�w
use master;
go

-- usuni�cie bazy o ile istnieje, ostro�nie!!!
drop database if exists DB;
go

create database DB;
go

use DB;
go

create table Dane(
	id int identity(1,1),
	tekst nchar(1000));

insert Dane
select left(text,1000) from sys.messages;

select top(100) * from Dane;

-- UWAGA! Kopie zapasowe w kolejnych poleceniach wykonywane s�
-- do folderu C:\BAK
-- Utw�rz taki folder albo zmie� �cie�k� w poleceniach.

-- pe�na kopia zapasowa - bez kompresji
BACKUP DATABASE [DB] 
  TO DISK = N'C:\BAK\DB_Full.bak' 
  WITH NOFORMAT, NOINIT,  NAME = N'DB-Full Database Backup', 
  SKIP, NOREWIND, NOUNLOAD, NO_COMPRESSION,  STATS = 10
GO

-- pe�na kopia zapasowa z kompresj�
BACKUP DATABASE [DB] 
  TO DISK = N'C:\BAK\DB_Full_Cmp.bak' 
  WITH NOFORMAT, NOINIT,  NAME = N'DB-Full Database Backup', 
  SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
GO

-- sekwencja kopii zapasowych
-- zwr�� uwag� na rozmiar tworzonych plik�w

-- r�nicowa kopia zapasowa
-- zawiera wszystkie zmiany wprowadzone po poprzedniej kopii PE�NEJ
BACKUP DATABASE [DB] 
  TO  DISK = N'C:\BAK\DB_Diff_01.bak' 
  WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N'DB-Full Database Backup', 
  SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

-- aktualizacja danych
update Dane set
	tekst = 'Zaktualizowano'
where id between 40001 and 50000;

-- druga kopia r�nicowa
BACKUP DATABASE [DB] 
  TO  DISK = N'C:\BAK\DB_Diff_02.bak' 
  WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N'DB-Full Database Backup', 
  SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

-- aktualizacja danych
update Dane set
	tekst = 'Zaktualizowano'
where id between 50001 and 60000;

-- trzecia kopia r�nicowa
BACKUP DATABASE [DB] 
  TO  DISK = N'C:\BAK\DB_Diff_03.bak' 
  WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N'DB-Full Database Backup', 
  SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

-- czwarta kopia r�nicowa - nie by�o �adnych zmian od poprzedniej
BACKUP DATABASE [DB] 
  TO  DISK = N'C:\BAK\DB_Diff_04.bak' 
  WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N'DB-Full Database Backup', 
  SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

-- pe�na kopia zapasowa
BACKUP DATABASE [DB] 
  TO DISK = N'C:\BAK\DB_Full_02.bak' 
  WITH NOFORMAT, NOINIT,  NAME = N'DB-Full Database Backup', 
  SKIP, NOREWIND, NOUNLOAD, NO_COMPRESSION,  STATS = 10
GO

-- kopia r�nicowa - pierwsza po ostatniej pe�nej
BACKUP DATABASE [DB] 
  TO  DISK = N'C:\BAK\DB_Diff_05.bak' 
  WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N'DB-Full Database Backup', 
  SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

update Dane set tekst = 'Zaktualizowano drugi raz'

-- kolejna kopia r�nicowa
BACKUP DATABASE [DB] 
  TO  DISK = N'C:\BAK\DB_Diff_06.bak' 
  WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N'DB-Full Database Backup', 
  SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

-- kopia zapasowa dziennika transakcyjnego
-- zawiera wszystkie zmiany wprowadzone po poprzedniej kopii dziennika
BACKUP LOG [DB] 
  TO  DISK = N'C:\BAK\DB_Log_01.trn' 
  WITH NOFORMAT, NOINIT,  NAME = N'DB-Full Database Backup', 
  SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

update Dane set
	tekst = 'Zaktualizowano trzeci raz'
where id between 50001 and 60000;

BACKUP LOG [DB] 
  TO  DISK = N'C:\BAK\DB_Log_02.trn' 
  WITH NOFORMAT, NOINIT,  NAME = N'DB-Full Database Backup', 
  SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

update Dane set
	tekst = 'Zaktualizowano trzeci raz'
where id between 60001 and 70000;

BACKUP LOG [DB] 
  TO  DISK = N'C:\BAK\DB_Log_03.trn' 
  WITH NOFORMAT, NOINIT,  NAME = N'DB-Full Database Backup', 
  SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO


-- wi�kszo�� opcji podawana w poprzednich poleceniach 
-- nie jest potrzebna
backup database DB
  to disk = N'C:\BAK\DB_Full_03.bak';

backup database DB
  to disk = N'C:\BAK\DB_Diff_07.bak'
  with differential;

/*
Co bierzemy pod uwag� planuj�c wykonywanie i odtwarzanie
kopii zapasowych?
- aktywno�� u�ytkownik�w / liczba zmian
- szybko�� lokalizacji
- harmonogram
- RPO / RTO
- wielko�� bazy danych
- czy dane s� replikowane (Availibility Groups, Database Mirroring, Log Shipping, itd.)

Przyk�adowe scenariusze:

hurtownia danych, zasilana ca�o�ciowo raz na dob�, brak zmian w ci�gu dnia
> FULL po za�adowaniu danych

hurtownia danych, zasilana przyrostowa raz na dob� (5%), brak zmian w ci�gu dnia
> FULL raz na tydzie�, DIFF codziennie po zasileniu

baza transakcyjna 200 GB, przyrost dziennika - 10 GB na 24h r�wnomiernie
> FULL co 24h, LOG wg RPO (np. raz na 15 minut)

baza zabezpieczona przez inne narz�dzia replikacji, cel kopii - analiza danych,
przywr�cenie danych przypadkowo skasowanych
> FULL co 24h, LOG co 4..6h

�wiczenie: okre�l harmonogram wykonywania kopii zapasowych

1. baza analityczna, zasilana z wielu �r�de� (np. Excel, CSV)
   w ci�gu dnia �adujemy ok 100-200 MB nowych danych, godziny zmienne
   g��wna cz�� bazy zasilana co 24h (1:00 AM) przyrostowo (ok. 10 GB nowych danych).
   rozmiar bazy - obecnie 450 GB

2. baza systemu FK
   obecny rozmiar 250 GB, przyrost 50 MB / dzie�
   liczba nowych, modyfikowanych wierszy w tabelach to ok. 100 tys. dziennie
   baza ma ok. 150 tabel, 20-30 widok�w
   20 u�ytkownik�w wprowadzaj�cych dane
   brak innych proces�w replikacji
*/

-- odtwarzanie bazy danych

-- lista plik�w w folderze
exec xp_dirtree 'C:\BAK', 1, 1

-- usuwamy baz� danych
use master
go
drop database DB;
go

-- odtworzenie z drugiej kopii pe�nej
-- brak opcji oznacza WITH RECOVERY
restore database DB
from disk = N'C:\BAK\DB_Full_02.bak';

-- odtworzenie bazy z kopii zapasowej
-- utworzenie kopii bazy z backup
-- uwaga na �cie�ki docelowe
restore database DB_kopia
from disk = N'C:\BAK\DB_Full.bak'
with 
  move 'DB' to 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\DB_Kopia.mdf',
  move 'DB_log' to 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\DB_Kopia_log.ldf'

/*
restore database DB_kopia
from disk = N'C:\BAK\DB_Full.bak'
with 
  move 'DB' to 'E:\SQLDATA\MSSQL15.MSSQLSERVER\MSSQL\DATA\DB_Kopia.mdf',
  move 'DB_log' to 'E:\SQLDATA\MSSQL15.MSSQLSERVER\MSSQL\DATA\DB_Kopia_log.ldf'
*/

-- gdy baza jest online odtwarzanie dalszych kopii zapasowych
-- jest niemo�liwe
restore log DB
from disk = N'C:\BAK\DB_Log_01.trn';

-- baza danych dla kolejnych przyk�ad�w:
use master;
go
create database Test;
go
use Test;
go

create table Dane(nr int);
insert Dane select top(10) 1 from sys.messages;
select * from Dane;

-- kopia zapasowa pe�na
backup database Test
to disk = N'C:\BAK\Test_Full_01.bak';

-- modyfikujemy dane
update Dane set nr = 2;
select * from Dane;

-- kopia zapasowa r�nicowa
backup database Test
to disk = N'C:\BAK\Test_Diff_02.bak'
with differential;

-- modyfikujemy dane
update Dane set nr = 3;
select * from Dane;

backup database Test
to disk = N'C:\BAK\Test_Diff_03.bak'
with differential;

-- modyfikujemy dane
update Dane set nr = 4;
select * from Dane;

backup database Test
to disk = N'C:\BAK\Test_Diff_04.bak'
with differential;

-- usuwamy baz�
use master;
go
drop database Test;
go

-- odtwarzamy kopi� pe�n� z opcj� NORECOVERY
-- dalsze odtwarzanie b�dzie mo�liwe
restore database Test
from disk = N'C:\BAK\Test_Full_01.bak'
with norecovery;

-- baza jest, ale niedost�pna
select database_id, name, state, state_desc
from sys.databases
where name = 'Test';

-- odtwarzamy kopi� r�nicow� drug� (03)
restore database Test
from disk = N'C:\BAK\Test_Diff_03.bak'
with norecovery;

-- przywracamy baz� do u�ycia
restore database Test with recovery;

use Test;
go
select * from Dane;
go

-- po odtworzeniu kopii pe�nej mo�na przywr�ci� dowoln�
-- z kopii r�nicowych wykonanych po tej pe�nej

-- utworzenie nowej kopii pe�nej rozpoczyna nowy �a�cuch 
-- kopii zapasowych

-- druga kopia zapasowa pe�na
backup database Test
to disk = N'C:\BAK\Test_Full_05.bak';

-- usuwamy baz�
use master;
go
drop database Test;
go

-- odtwarzamy DRUG� kopi� pe�n� z opcj� NORECOVERY
-- dalsze odtwarzanie b�dzie mo�liwe
restore database Test
from disk = N'C:\BAK\Test_Full_05.bak'
with norecovery;

-- baza jest, ale niedost�pna
select database_id, name, state, state_desc
from sys.databases
where name = 'Test';

-- odtwarzamy kopi� r�nicow� drug� (03)
restore database Test
from disk = N'C:\BAK\Test_Diff_03.bak'
with norecovery;
-- b��d: niew�a�ciwa kopia r�nicowa!

/*
    Kopie zapasowe dziennika transakcyjnego - odtwarzanie
*/

use master;
go
drop database if exists Test;
go
create database Test;
go
use Test;
go

create table Dane(nr int);
insert Dane select top(10) 1 from sys.messages;
select * from Dane;

-- kopia zapasowa pe�na
backup database Test
to disk = N'C:\BAK\Test_Full_10.bak';

-- modyfikujemy dane
update Dane set nr = 2;
select * from Dane;

-- kopia zapasowa dziennika
backup log Test
to disk = N'C:\BAK\Test_Log_11.trn';

-- modyfikujemy dane
update Dane set nr = 3;
select * from Dane;

backup log Test
to disk = N'C:\BAK\Test_Log_12.trn';

-- modyfikujemy dane
update Dane set nr = 4;
select * from Dane;

backup log Test
to disk = N'C:\BAK\Test_Log_13.trn';

-- usuwamy baz�
use master;
go
drop database Test;
go

-- odtwarzamy kopi� pe�n� z opcj� NORECOVERY
-- dalsze odtwarzanie b�dzie mo�liwe
restore database Test
from disk = N'C:\BAK\Test_Full_10.bak'
with norecovery;

-- baza jest, ale niedost�pna
select database_id, name, state, state_desc
from sys.databases
where name = 'Test';

-- kopie zapasowe dziennika musz� by� odtwarzane
-- bez pomijania 
restore log Test
from disk = N'C:\BAK\Test_Log_13.trn'
with norecovery;
-- b��d: niew�a�ciwa kopia dziennika

restore log Test
from disk = N'C:\BAK\Test_Log_11.trn'
with norecovery;
-- ok

-- odtwarzanie w trybie STANDBY
restore log Test
from disk = N'C:\BAK\Test_Log_12.trn'
with standby = N'C:\BAK\standbyfile_01.dat';

-- baza jest i nawet dost�pna! ale...
select database_id, name, state, state_desc, is_read_only, is_in_standby
from sys.databases
where name = 'Test';

-- mamy podgl�d danych
select * from Test.dbo.Dane;

-- mo�na kontynuowa� odtwarzanie
restore log Test
from disk = N'C:\BAK\Test_Log_13.trn'
with standby = N'C:\BAK\standbyfile_01.dat';

select * from Test.dbo.Dane;

-- dane s� ok - przywracamy baz� (recovery to domy�lna opcja)
restore database Test;

select database_id, name, state, state_desc, is_read_only, is_in_standby
from sys.databases
where name = 'Test';

/*
	Opcja STOPAT

	Scenariusz: przypadkowo wyczyszczono dane w tabeli, ale
	wiemy dok�adnie kiedy si� to sta�o.
	Zadanie: przywr�ci� baz� do stanu sprzed usuni�cia danych.

*/

use master;
go
drop database if exists Test;
go
create database Test;
go
use Test;
go

create table Dane(nr int);
insert Dane select top(10) 1 from sys.messages;
select * from Dane;

-- kopia zapasowa pe�na
backup database Test
to disk = N'C:\BAK\Test_Full_20.bak';

-- modyfikujemy dane
update Dane set nr = 2;
select * from Dane;

-- tutaj zapami�tajmy aktualny czas
select getdate();
-- 2023-06-19 10:57:20.513

-- usuwamy dane
truncate table Dane;
select * from Dane;

-- POMOCY!!!!


-- BEZ PANIKI!
-- wykonujemy kopi� zapasow� dziennika
-- transakcja z truncate b�dzie w niej zawarta
backup log Test
to disk = N'C:\BAK\Test_Log_21.trn';

-- usuwamy baz� (lepsza opcja: odtwarzamy do kopii)
use master;
go
drop database Test;
go

-- odtwarzamy kopi� pe�n� z opcj� NORECOVERY
-- dalsze odtwarzanie b�dzie mo�liwe
restore database Test
from disk = N'C:\BAK\Test_Full_20.bak'
with norecovery;

-- odtwarzamy kopi� zapasow� dziennika z opcjami STOPAT
-- oraz STANDBY
restore log Test
from disk = N'C:\BAK\Test_Log_21.trn'
with standby = N'C:\BAK\standbyfile.dat',
     stopat = N'2023-06-19 10:57:20.513';

-- sprawdzamy czy mamy dane
select * from Test.dbo.Dane;

-- UFF!!!
restore database Test;


/*
	Opcja STOPBEFOREMARK

	Scenariusz: kto� usun�� tabel�, niestety nie bardzo wiemy
	kiedy si� to sta�o.
	Zadanie: przywr�ci� baz� to momentu sprzed usuni�cia tabeli.

*/

use master;
go
drop database if exists Test;
go
create database Test;
go
use Test;
go

create table Dane(nr int);
insert Dane select top(10) 1 from sys.messages;
select * from Dane;

-- kopia zapasowa pe�na
backup database Test
to disk = N'C:\BAK\Test_Full_30.bak';

-- modyfikujemy dane
update Dane set nr = 2;
select * from Dane;

-- usuwamy tabel� Dane!
drop table Dane;

-- POMOCY!!!!


-- BEZ PANIKI!
-- najpierw musimy namierzy� transakcj�, w kt�rej usuni�to tabel�
select *
from fn_dblog (NULL, NULL)
where [Transaction NAME] LIKE '%DROPOBJ%'
order by [Begin Time] desc;

-- kopiujemy LSN
-- 00000025:000000f8:0001

-- wykonujemy kopi� zapasow� dziennika
-- transakcja z drop b�dzie w niej zawarta
backup log Test
to disk = N'C:\BAK\Test_Log_31.trn';

-- usuwamy baz� (lepsza opcja: odtwarzamy do kopii)
use master;
go
drop database Test;
go

-- odtwarzamy kopi� pe�n� z opcj� NORECOVERY
-- dalsze odtwarzanie b�dzie mo�liwe
restore database Test
from disk = N'C:\BAK\Test_Full_30.bak'
with norecovery;

-- odtwarzamy kopi� zapasow� dziennika z opcjami STOPAT
-- oraz STANDBY
restore log Test
from disk = N'C:\BAK\Test_Log_31.trn'
with stopbeforemark = N'lsn:0x00000025:000000f8:0001';

-- sprawdzamy czy mamy dane
select * from Test.dbo.Dane;

-- UFF!!!



