/*

	Administracja Microsoft SQL Server

	Audyty

	(c) Grzegorz Stolecki

*/

USE master;
GO

-- utworzenie audytu na poziomie serwera
CREATE SERVER AUDIT [Audit_SysAdmin]
  TO FILE(        
     FILEPATH = 'C:\temp\'        
	,MAXSIZE = 256 MB        
	,MAX_ROLLOVER_FILES = 2147483647        
	,RESERVE_DISK_SPACE = OFF)
  WITH(        
     QUEUE_DELAY = 1000        
	 ,ON_FAILURE = CONTINUE)
  WHERE object_name = 'sysadmin';

-- w³¹czenie audytu
ALTER SERVER AUDIT [Audit_SysAdmin]
WITH (STATE = ON);

-- specyfikacja audytu
-- œledzone zdarzenia - zmiana cz³onkostwa roli sysadmin
CREATE SERVER AUDIT SPECIFICATION [Spec_SysAdmin]
FOR SERVER AUDIT [Audit_SysAdmin]
ADD (SERVER_ROLE_MEMBER_CHANGE_GROUP);

-- w³¹czenie specyfikacji
ALTER SERVER AUDIT SPECIFICATION [Spec_SysAdmin]
WITH (STATE = ON);

-- sprawdzenie logu audytu
select * from fn_get_audit_file(N'C:\temp\Audit_SysA*', default, default);



-- audyt na bazie danych
USE master;
GO

CREATE SERVER AUDIT [AW_Delete]
  TO FILE(        
     FILEPATH = 'C:\temp\'        
	,MAXSIZE = 256 MB        
	,MAX_ROLLOVER_FILES = 2147483647        
	,RESERVE_DISK_SPACE = OFF)
  WITH(        
     QUEUE_DELAY = 1000        
	 ,ON_FAILURE = CONTINUE)

ALTER SERVER AUDIT [AW_Delete] WITH (STATE=ON);

USE AdventureWorksDW2019;
GO

-- przygotowanie danych do testów
select
	1 id, 'Tekst' tekst
into test;
select * from test;
insert test values(2,'aaaa'), (3, 'bbbb');
select * from test;

-- specyfikacja audytu
CREATE DATABASE AUDIT SPECIFICATION [DBAudit_AW]
FOR SERVER AUDIT [AW_Delete]
ADD (DELETE ON OBJECT::dbo.Test BY public);

-- w³¹czenie specyfikacji
ALTER DATABASE AUDIT SPECIFICATION [DBAudit_AW]
WITH (STATE = ON);

-- test
select * from Test;
select * from Test where id = 3;
delete Test where id = 2;

-- sprawdzenie logu audytu
select * from fn_get_audit_file(N'C:\temp\AW_Delete*', default, default);



-- w³asne zdarzenie w audycie
--
USE Master
GO

CREATE SERVER AUDIT [AuditTestCustomEvent]
TO FILE
  (FILEPATH = 'c:\temp\'
  ,MAXSIZE = 256 MB
  ,MAX_ROLLOVER_FILES = 2147483647
  ,RESERVE_DISK_SPACE = OFF
)
WITH
  (QUEUE_DELAY = 1000
  ,ON_FAILURE = CONTINUE);
GO

CREATE SERVER AUDIT SPECIFICATION [AuditCustomEvent]
FOR SERVER AUDIT [AuditTestCustomEvent]
ADD (USER_DEFINED_AUDIT_GROUP) ;
GO

ALTER SERVER AUDIT [AuditTestCustomEvent]
WITH (STATE = ON);

USE master;
GO

ALTER SERVER AUDIT SPECIFICATION [AuditCustomEvent]
WITH (STATE = ON) ;

-- wywo³anie zdarzenia
EXEC sys.sp_audit_write 333, 1, N'Zdarzenie testowe!';
EXEC sys.sp_audit_write 505, 1, N'Zdarzenie testowe 2!';

-- odczytanie pliku audytu
select * from fn_get_audit_file(N'C:\temp\AuditTestCu*', default, default);

