/*

	Administracja Microsoft SQL Server

	Kopie zapasowe

	(c) Grzegorz Stolecki

*/

-- przygotowanie bazy do testów
use master;
go

-- usuniêcie bazy o ile istnieje, ostro¿nie!!!
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

-- UWAGA! Kopie zapasowe w kolejnych poleceniach wykonywane s¹
-- do folderu C:\BAK
-- Utwórz taki folder albo zmieñ œcie¿kê w poleceniach.

-- pe³na kopia zapasowa - bez kompresji
BACKUP DATABASE [DB] 
  TO DISK = N'C:\BAK\DB_Full.bak' 
  WITH NOFORMAT, NOINIT,  NAME = N'DB-Full Database Backup', 
  SKIP, NOREWIND, NOUNLOAD, NO_COMPRESSION,  STATS = 10
GO

-- pe³na kopia zapasowa z kompresj¹
BACKUP DATABASE [DB] 
  TO DISK = N'C:\BAK\DB_Full_Cmp.bak' 
  WITH NOFORMAT, NOINIT,  NAME = N'DB-Full Database Backup', 
  SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
GO

-- sekwencja kopii zapasowych
-- zwróæ uwagê na rozmiar tworzonych plików

-- ró¿nicowa kopia zapasowa
-- zawiera wszystkie zmiany wprowadzone po poprzedniej kopii PE£NEJ
BACKUP DATABASE [DB] 
  TO  DISK = N'C:\BAK\DB_Diff_01.bak' 
  WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N'DB-Full Database Backup', 
  SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

-- aktualizacja danych
update Dane set
	tekst = 'Zaktualizowano'
where id between 40001 and 50000;

-- druga kopia ró¿nicowa
BACKUP DATABASE [DB] 
  TO  DISK = N'C:\BAK\DB_Diff_02.bak' 
  WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N'DB-Full Database Backup', 
  SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

-- aktualizacja danych
update Dane set
	tekst = 'Zaktualizowano'
where id between 50001 and 60000;

-- trzecia kopia ró¿nicowa
BACKUP DATABASE [DB] 
  TO  DISK = N'C:\BAK\DB_Diff_03.bak' 
  WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N'DB-Full Database Backup', 
  SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

-- czwarta kopia ró¿nicowa - nie by³o ¿adnych zmian od poprzedniej
BACKUP DATABASE [DB] 
  TO  DISK = N'C:\BAK\DB_Diff_04.bak' 
  WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N'DB-Full Database Backup', 
  SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

-- pe³na kopia zapasowa
BACKUP DATABASE [DB] 
  TO DISK = N'C:\BAK\DB_Full_02.bak' 
  WITH NOFORMAT, NOINIT,  NAME = N'DB-Full Database Backup', 
  SKIP, NOREWIND, NOUNLOAD, NO_COMPRESSION,  STATS = 10
GO

-- kopia ró¿nicowa - pierwsza po ostatniej pe³nej
BACKUP DATABASE [DB] 
  TO  DISK = N'C:\BAK\DB_Diff_05.bak' 
  WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N'DB-Full Database Backup', 
  SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

update Dane set tekst = 'Zaktualizowano drugi raz'

-- kolejna kopia ró¿nicowa
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


-- wiêkszoœæ opcji podawana w poprzednich poleceniach 
-- nie jest potrzebna
backup database DB
  to disk = N'C:\BAK\DB_Full_03.bak';

backup database DB
  to disk = N'C:\BAK\DB_Diff_07.bak'
  with differential;

/*
Co bierzemy pod uwagê planuj¹c wykonywanie i odtwarzanie
kopii zapasowych?
- aktywnoœæ u¿ytkowników / liczba zmian
- szybkoœæ lokalizacji
- harmonogram
- RPO / RTO
- wielkoœæ bazy danych
- czy dane s¹ replikowane (Availibility Groups, Database Mirroring, Log Shipping, itd.)

Przyk³adowe scenariusze:

hurtownia danych, zasilana ca³oœciowo raz na dobê, brak zmian w ci¹gu dnia
> FULL po za³adowaniu danych

hurtownia danych, zasilana przyrostowa raz na dobê (5%), brak zmian w ci¹gu dnia
> FULL raz na tydzieñ, DIFF codziennie po zasileniu

baza transakcyjna 200 GB, przyrost dziennika - 10 GB na 24h równomiernie
> FULL co 24h, LOG wg RPO (np. raz na 15 minut)

baza zabezpieczona przez inne narzêdzia replikacji, cel kopii - analiza danych,
przywrócenie danych przypadkowo skasowanych
> FULL co 24h, LOG co 4..6h

Æwiczenie: okreœl harmonogram wykonywania kopii zapasowych

1. baza analityczna, zasilana z wielu Ÿróde³ (np. Excel, CSV)
   w ci¹gu dnia ³adujemy ok 100-200 MB nowych danych, godziny zmienne
   g³ówna czêœæ bazy zasilana co 24h (1:00 AM) przyrostowo (ok. 10 GB nowych danych).
   rozmiar bazy - obecnie 450 GB

2. baza systemu FK
   obecny rozmiar 250 GB, przyrost 50 MB / dzieñ
   liczba nowych, modyfikowanych wierszy w tabelach to ok. 100 tys. dziennie
   baza ma ok. 150 tabel, 20-30 widoków
   20 u¿ytkowników wprowadzaj¹cych dane
   brak innych procesów replikacji
*/

-- odtwarzanie bazy danych

-- lista plików w folderze
exec xp_dirtree 'C:\BAK', 1, 1

-- usuwamy bazê danych
use master
go
drop database DB;
go

-- odtworzenie z drugiej kopii pe³nej
-- brak opcji oznacza WITH RECOVERY
restore database DB
from disk = N'C:\BAK\DB_Full_02.bak';

-- odtworzenie bazy z kopii zapasowej
-- utworzenie kopii bazy z backup
-- uwaga na œcie¿ki docelowe
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
-- jest niemo¿liwe
restore log DB
from disk = N'C:\BAK\DB_Log_01.trn';

-- baza danych dla kolejnych przyk³adów:
use master;
go
create database Test;
go
use Test;
go

create table Dane(nr int);
insert Dane select top(10) 1 from sys.messages;
select * from Dane;

-- kopia zapasowa pe³na
backup database Test
to disk = N'C:\BAK\Test_Full_01.bak';

-- modyfikujemy dane
update Dane set nr = 2;
select * from Dane;

-- kopia zapasowa ró¿nicowa
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

-- usuwamy bazê
use master;
go
drop database Test;
go

-- odtwarzamy kopiê pe³n¹ z opcj¹ NORECOVERY
-- dalsze odtwarzanie bêdzie mo¿liwe
restore database Test
from disk = N'C:\BAK\Test_Full_01.bak'
with norecovery;

-- baza jest, ale niedostêpna
select database_id, name, state, state_desc
from sys.databases
where name = 'Test';

-- odtwarzamy kopiê ró¿nicow¹ drug¹ (03)
restore database Test
from disk = N'C:\BAK\Test_Diff_03.bak'
with norecovery;

-- przywracamy bazê do u¿ycia
restore database Test with recovery;

use Test;
go
select * from Dane;
go

-- po odtworzeniu kopii pe³nej mo¿na przywróciæ dowoln¹
-- z kopii ró¿nicowych wykonanych po tej pe³nej

-- utworzenie nowej kopii pe³nej rozpoczyna nowy ³añcuch 
-- kopii zapasowych

-- druga kopia zapasowa pe³na
backup database Test
to disk = N'C:\BAK\Test_Full_05.bak';

-- usuwamy bazê
use master;
go
drop database Test;
go

-- odtwarzamy DRUG¥ kopiê pe³n¹ z opcj¹ NORECOVERY
-- dalsze odtwarzanie bêdzie mo¿liwe
restore database Test
from disk = N'C:\BAK\Test_Full_05.bak'
with norecovery;

-- baza jest, ale niedostêpna
select database_id, name, state, state_desc
from sys.databases
where name = 'Test';

-- odtwarzamy kopiê ró¿nicow¹ drug¹ (03)
restore database Test
from disk = N'C:\BAK\Test_Diff_03.bak'
with norecovery;
-- b³¹d: niew³aœciwa kopia ró¿nicowa!

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

-- kopia zapasowa pe³na
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

-- usuwamy bazê
use master;
go
drop database Test;
go

-- odtwarzamy kopiê pe³n¹ z opcj¹ NORECOVERY
-- dalsze odtwarzanie bêdzie mo¿liwe
restore database Test
from disk = N'C:\BAK\Test_Full_10.bak'
with norecovery;

-- baza jest, ale niedostêpna
select database_id, name, state, state_desc
from sys.databases
where name = 'Test';

-- kopie zapasowe dziennika musz¹ byæ odtwarzane
-- bez pomijania 
restore log Test
from disk = N'C:\BAK\Test_Log_13.trn'
with norecovery;
-- b³¹d: niew³aœciwa kopia dziennika

restore log Test
from disk = N'C:\BAK\Test_Log_11.trn'
with norecovery;
-- ok

-- odtwarzanie w trybie STANDBY
restore log Test
from disk = N'C:\BAK\Test_Log_12.trn'
with standby = N'C:\BAK\standbyfile_01.dat';

-- baza jest i nawet dostêpna! ale...
select database_id, name, state, state_desc, is_read_only, is_in_standby
from sys.databases
where name = 'Test';

-- mamy podgl¹d danych
select * from Test.dbo.Dane;

-- mo¿na kontynuowaæ odtwarzanie
restore log Test
from disk = N'C:\BAK\Test_Log_13.trn'
with standby = N'C:\BAK\standbyfile_01.dat';

select * from Test.dbo.Dane;

-- dane s¹ ok - przywracamy bazê (recovery to domyœlna opcja)
restore database Test;

select database_id, name, state, state_desc, is_read_only, is_in_standby
from sys.databases
where name = 'Test';

/*
	Opcja STOPAT

	Scenariusz: przypadkowo wyczyszczono dane w tabeli, ale
	wiemy dok³adnie kiedy siê to sta³o.
	Zadanie: przywróciæ bazê do stanu sprzed usuniêcia danych.

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

-- kopia zapasowa pe³na
backup database Test
to disk = N'C:\BAK\Test_Full_20.bak';

-- modyfikujemy dane
update Dane set nr = 2;
select * from Dane;

-- tutaj zapamiêtajmy aktualny czas
select getdate();
-- 2023-06-19 10:57:20.513

-- usuwamy dane
truncate table Dane;
select * from Dane;

-- POMOCY!!!!


-- BEZ PANIKI!
-- wykonujemy kopiê zapasow¹ dziennika
-- transakcja z truncate bêdzie w niej zawarta
backup log Test
to disk = N'C:\BAK\Test_Log_21.trn';

-- usuwamy bazê (lepsza opcja: odtwarzamy do kopii)
use master;
go
drop database Test;
go

-- odtwarzamy kopiê pe³n¹ z opcj¹ NORECOVERY
-- dalsze odtwarzanie bêdzie mo¿liwe
restore database Test
from disk = N'C:\BAK\Test_Full_20.bak'
with norecovery;

-- odtwarzamy kopiê zapasow¹ dziennika z opcjami STOPAT
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

	Scenariusz: ktoœ usun¹³ tabelê, niestety nie bardzo wiemy
	kiedy siê to sta³o.
	Zadanie: przywróciæ bazê to momentu sprzed usuniêcia tabeli.

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

-- kopia zapasowa pe³na
backup database Test
to disk = N'C:\BAK\Test_Full_30.bak';

-- modyfikujemy dane
update Dane set nr = 2;
select * from Dane;

-- usuwamy tabelê Dane!
drop table Dane;

-- POMOCY!!!!


-- BEZ PANIKI!
-- najpierw musimy namierzyæ transakcjê, w której usuniêto tabelê
select *
from fn_dblog (NULL, NULL)
where [Transaction NAME] LIKE '%DROPOBJ%'
order by [Begin Time] desc;

-- kopiujemy LSN
-- 00000025:000000f8:0001

-- wykonujemy kopiê zapasow¹ dziennika
-- transakcja z drop bêdzie w niej zawarta
backup log Test
to disk = N'C:\BAK\Test_Log_31.trn';

-- usuwamy bazê (lepsza opcja: odtwarzamy do kopii)
use master;
go
drop database Test;
go

-- odtwarzamy kopiê pe³n¹ z opcj¹ NORECOVERY
-- dalsze odtwarzanie bêdzie mo¿liwe
restore database Test
from disk = N'C:\BAK\Test_Full_30.bak'
with norecovery;

-- odtwarzamy kopiê zapasow¹ dziennika z opcjami STOPAT
-- oraz STANDBY
restore log Test
from disk = N'C:\BAK\Test_Log_31.trn'
with stopbeforemark = N'lsn:0x00000025:000000f8:0001';

-- sprawdzamy czy mamy dane
select * from Test.dbo.Dane;

-- UFF!!!



