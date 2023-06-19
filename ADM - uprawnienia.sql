/*

	Administracja Microsoft SQL Server

	Uprawnienia

	(c) Grzegorz Stolecki

*/

-- Baza dla przyk³adów
use master;
go
drop database if exists DB;
go
create database DB;
go
use DB;
go

-- utworzenie schematów
create schema HR;
go
create schema CRM;
go

-- tabele
create table HR.Klienci(
	nazwa varchar(50));
create table HR.Pracownicy(
	dzial varchar(50),
	nazwisko varchar(50));
insert HR.Klienci values('Alfa'),('Beta');
select * from HR.Klienci
insert HR.Pracownicy values
	('FK','Kowalska'), ('IT','Admin');
select * from HR.Pracownicy;	
create table CRM.Klienci(
	kontakt varchar(50));
insert CRM.Klienci values ('Potencjalny'),('James Bond');
select * from CRM.Klienci;

-- utworzenie loginów
use master;
go
create login [Test] with 
  password=N'1234', 
  default_database=[master], 
  check_expiration=off, 
  check_policy=off;
go
create login [Test2] with 
  password=N'1234', 
  default_database=[master], 
  check_expiration=off, 
  check_policy=off;
go

-- szybki sposób na testowanie uprawnieñ to impersonifikacja

-- bie¿¹cy login
select SUSER_SNAME();

-- impersonifikacja
execute as login='Test'
select user_name(), suser_sname()
revert

-- sprawdzenie po zakoñczeniu dzia³ania jako Test
select suser_sname()

use DB;
go

-- dodanie u¿ytkownika do bazy danych
create user [Test] for login [Test];
go

-- czy u¿ytkownik Test ma uprawnienia do danych?
execute as user='Test'
select user_name(), suser_sname()
select * from HR.Klienci
revert
-- no access by default!

-- wykorzystanie roli bazy danych
alter role db_datareader add member Test;

-- czy u¿ytkownik Test ma uprawnienia do danych?
execute as user='Test'
select user_name(), suser_sname()
select * from HR.Klienci
revert
-- ok!

-- widoki systemowe

use master;
select * from sys.server_principals;
select * from sys.server_role_members;
select * from sys.server_permissions;

use DB;
select * from sys.database_principals;
select * from sys.database_role_members;
select * from sys.database_permissions;

-- user Test ma principal_id = 5 (sprawdŸ)
select * from sys.database_role_members where member_principal_id = 5;
select * from sys.database_permissions where grantee_principal_id = 5;

select * from fn_my_permissions(NULL, 'SERVER');  
select * from fn_my_permissions('HR.Klienci', 'SERVER');  

execute as user = 'Test';
select * from fn_my_permissions('HR.Klienci', 'OBJECT');  
revert;

-- usuniêcie u¿ytkownika Test z roli
alter role db_datareader drop member Test;

-- czy u¿ytkownik Test ma uprawnienia do tabeli HR.Klienci?
execute as user='Test'
select user_name(), suser_sname()
select * from HR.Klienci
revert

-- nadanie uprawnienia do tabeli HR.Klienci
grant select on HR.Klienci to Test;

-- test
execute as user='Test';
select user_name(), suser_sname();
select * from sys.tables;
select * from HR.Klienci;
revert;

-- odebranie uprawnienia do tabeli HR.Klienci
revoke select on HR.Klienci to Test;

-- test
execute as user='Test';
select user_name(), suser_sname();
select * from sys.tables;
select * from HR.Klienci;
revert;

-- uprawnienie: wszystko z wyj¹tkiem HR.Klienci
grant select on database::DB to Test;
deny select on HR.Klienci to Test;

-- test
execute as user='Test';
select user_name(), suser_sname();
select * from sys.tables;
select * from HR.Klienci;
revert;

-- odebranie select na bazie
revoke select on database::DB to Test;

-- test
execute as user='Test';
select user_name(), suser_sname();
select * from sys.tables;
select * from HR.Klienci;
revert;

-- uprawnienie do schematu CRM
grant select on schema::CRM to Test;

-- test
execute as user='Test';
select user_name(), suser_sname();
select * from sys.tables;
revert;


-- w³aœcicielstwo

-- utworzenie schematu Sales, którego w³aœcicielem bêdzie Test
use DB;
go
create schema Sales authorization Test;
go

-- utworzenie tabeli w schemacie Sales
create table Sales.Dane(dane_sales int);
go
create table Sales.Klienci(klienci_sales int);
go

-- jeszcze jedna tabela - w schemacie dbo
create table dbo.Dane(dane_dbo int);
go

-- czy u¿ytkownik Test widzi te tabele?
execute as user='Test';
select user_name(), suser_sname();
select * from sys.tables;
revert;

-- jako w³aœciciel ma pe³ne uprawnienia do tabel w schemacie
execute as user='Test';
select user_name(), suser_sname();
select * from Sales.Dane;
revert;


-- schemat domyœlny u¿ytkownika
select * from Dane;
select * from Sales.Dane;

-- Jeœli w zapytaniu nie ma podanego schematu serwer
-- szuka obiektu w schemacie domyœlnym u¿ytkownika a nastêpnie w dbo.

-- zmiana domyœlnego schematu dla u¿ytkownika Test
alter user Test with default_schema = Sales;

-- to samo zapytanie wykonuje:

-- ja
select user_name(), suser_sname();
select * from Dane;

-- Test
execute as user='Test';
select user_name(), suser_sname();
select * from Dane;
revert;

-- ta sama treœæ zapytanie - odwo³anie do innych tabel!

-- czy mo¿na odebraæ uprawnienia do schematu jego w³aœcicielowi?
deny select on schema::Sales to Test;


-- £añcuch w³asnoœci

-- tabela testowa
select * into Kom from sys.messages;

-- Scenariusz: komunikaty s¹ w ró¿nych jêzykach.
-- U¿ytkownik powinien widzieæ komunikaty tylko w swoich jêzykach.
-- Treœæ zapytania powinna byæ taka sama dla wszystkich u¿ytkowników.

-- utworzenie u¿ytkowników, dla uproszczenia - bez loginów
create user TestPL without login;
create user TestEN without login;
create user TestDE without login;
go

-- Utworzenie schematów dla u¿ytkowników (w³aœciciel wszystkich to dbo).
create schema TestPL;
go
create schema TestEN;
go
create schema TestDE;
go

-- Ustawiamy schematy jako domyœlne dla u¿ytkowników
alter user TestPL with default_schema = TestPL;
alter user TestEN with default_schema = TestEN;
alter user TestDE with default_schema = TestDE;
go

-- Utworzenie widoków w poszczególnych schematach
create view TestPL.MojeKom as
	select * from dbo.Kom where language_id = 1045;
go
create view TestEN.MojeKom as
	select * from dbo.Kom where language_id = 1033;
go
create view TestDE.MojeKom as
	select * from dbo.Kom where language_id = 1031;
go

-- Nadanie uprawnieñ do schematów
grant select on schema::TestPL to TestPL;
grant select on schema::TestEN to TestEN;
grant select on schema::TestDE to TestDE;

-- Zakaz dostêpu do Ÿród³owej tabeli

-- Testowanie
execute as user = 'TestPL';
select * from dbo.Kom;
select * from MojeKom;
revert;

execute as user = 'TestDE';
select * from MojeKom;
revert;

execute as user = 'TestEN';
select * from MojeKom;
revert;

-- Scenariusz 2 - dynamiczne zabezpieczenia
-- Informacja o tym, kto co widzi bêdzie przechowywana w odrêbnej tabeli.

-- tabela definiuj¹ca uprawnienia
create table Kom_KtoCoWidzi(
	username nvarchar(40),
	language_id int);
go

insert Kom_KtoCoWidzi values
	(N'TestPL', 1045),
	(N'TestEN', 1033),
	(N'TestDE', 1031);

select * from Kom_KtoCoWidzi;
go

-- utworzenie widoku z dynamicznym warunkiem
create view dbo.MojeKomDyn as
select * from dbo.Kom
where language_id in (select language_id from Kom_KtoCoWidzi
                      where username = user_name());
go

-- uprawnienie select do widoku
grant select on MojeKomDyn to TestPL, TestEN, TestDE;

execute as user = 'TestDE';
select user_name();
select * from MojeKomDyn;
select * from Kom;
revert;

execute as user = 'TestEN';
select user_name();
select * from MojeKomDyn;
revert;

-- zmiana uprawnieñ w tabeli
update Kom_KtoCoWidzi set language_id = 1045 where username = 'TestEN';

-- test
execute as user = 'TestEN';
select user_name();
select * from MojeKomDyn;
revert;

-- zmiana uprawnieñ w tabeli
insert Kom_KtoCoWidzi values('TestPL', 1031);
select * from Kom_KtoCoWidzi;

-- test
execute as user = 'TestPL';
select user_name();
select * from MojeKomDyn;
select distinct language_id from MojeKomDyn;
revert;

-- co widzi dbo?
select user_name()
select * from MojeKomDyn;
go
-- UPS!

-- Zmiana definicji widoku tak, by dbo widzia³ wszystko!
create or alter view MojeKomDyn as
select * from Kom
where language_id in (select language_id from Kom_KtoCoWidzi
                      where username = user_name())
	or user_name() = 'dbo';
go

select * from MojeKomDyn;
go
-- lepiej!

