/*

	Administracja Microsoft SQL Server

	Uprawnienia

	(c) Grzegorz Stolecki

*/

-- Baza dla przyk�ad�w
use master;
go
drop database if exists DB;
go
create database DB;
go
use DB;
go

-- utworzenie schemat�w
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

-- utworzenie login�w
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

-- szybki spos�b na testowanie uprawnie� to impersonifikacja

-- bie��cy login
select SUSER_SNAME();

-- impersonifikacja
execute as login='Test'
select user_name(), suser_sname()
revert

-- sprawdzenie po zako�czeniu dzia�ania jako Test
select suser_sname()

use DB;
go

-- dodanie u�ytkownika do bazy danych
create user [Test] for login [Test];
go

-- czy u�ytkownik Test ma uprawnienia do danych?
execute as user='Test'
select user_name(), suser_sname()
select * from HR.Klienci
revert
-- no access by default!

-- wykorzystanie roli bazy danych
alter role db_datareader add member Test;

-- czy u�ytkownik Test ma uprawnienia do danych?
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

-- user Test ma principal_id = 5 (sprawd�)
select * from sys.database_role_members where member_principal_id = 5;
select * from sys.database_permissions where grantee_principal_id = 5;

select * from fn_my_permissions(NULL, 'SERVER');  
select * from fn_my_permissions('HR.Klienci', 'SERVER');  

execute as user = 'Test';
select * from fn_my_permissions('HR.Klienci', 'OBJECT');  
revert;

-- usuni�cie u�ytkownika Test z roli
alter role db_datareader drop member Test;

-- czy u�ytkownik Test ma uprawnienia do tabeli HR.Klienci?
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

-- uprawnienie: wszystko z wyj�tkiem HR.Klienci
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


-- w�a�cicielstwo

-- utworzenie schematu Sales, kt�rego w�a�cicielem b�dzie Test
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

-- czy u�ytkownik Test widzi te tabele?
execute as user='Test';
select user_name(), suser_sname();
select * from sys.tables;
revert;

-- jako w�a�ciciel ma pe�ne uprawnienia do tabel w schemacie
execute as user='Test';
select user_name(), suser_sname();
select * from Sales.Dane;
revert;


-- schemat domy�lny u�ytkownika
select * from Dane;
select * from Sales.Dane;

-- Je�li w zapytaniu nie ma podanego schematu serwer
-- szuka obiektu w schemacie domy�lnym u�ytkownika a nast�pnie w dbo.

-- zmiana domy�lnego schematu dla u�ytkownika Test
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

-- ta sama tre�� zapytanie - odwo�anie do innych tabel!

-- czy mo�na odebra� uprawnienia do schematu jego w�a�cicielowi?
deny select on schema::Sales to Test;


-- �a�cuch w�asno�ci

-- tabela testowa
select * into Kom from sys.messages;

-- Scenariusz: komunikaty s� w r�nych j�zykach.
-- U�ytkownik powinien widzie� komunikaty tylko w swoich j�zykach.
-- Tre�� zapytania powinna by� taka sama dla wszystkich u�ytkownik�w.

-- utworzenie u�ytkownik�w, dla uproszczenia - bez login�w
create user TestPL without login;
create user TestEN without login;
create user TestDE without login;
go

-- Utworzenie schemat�w dla u�ytkownik�w (w�a�ciciel wszystkich to dbo).
create schema TestPL;
go
create schema TestEN;
go
create schema TestDE;
go

-- Ustawiamy schematy jako domy�lne dla u�ytkownik�w
alter user TestPL with default_schema = TestPL;
alter user TestEN with default_schema = TestEN;
alter user TestDE with default_schema = TestDE;
go

-- Utworzenie widok�w w poszczeg�lnych schematach
create view TestPL.MojeKom as
	select * from dbo.Kom where language_id = 1045;
go
create view TestEN.MojeKom as
	select * from dbo.Kom where language_id = 1033;
go
create view TestDE.MojeKom as
	select * from dbo.Kom where language_id = 1031;
go

-- Nadanie uprawnie� do schemat�w
grant select on schema::TestPL to TestPL;
grant select on schema::TestEN to TestEN;
grant select on schema::TestDE to TestDE;

-- Zakaz dost�pu do �r�d�owej tabeli

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
-- Informacja o tym, kto co widzi b�dzie przechowywana w odr�bnej tabeli.

-- tabela definiuj�ca uprawnienia
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

-- zmiana uprawnie� w tabeli
update Kom_KtoCoWidzi set language_id = 1045 where username = 'TestEN';

-- test
execute as user = 'TestEN';
select user_name();
select * from MojeKomDyn;
revert;

-- zmiana uprawnie� w tabeli
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

-- Zmiana definicji widoku tak, by dbo widzia� wszystko!
create or alter view MojeKomDyn as
select * from Kom
where language_id in (select language_id from Kom_KtoCoWidzi
                      where username = user_name())
	or user_name() = 'dbo';
go

select * from MojeKomDyn;
go
-- lepiej!

