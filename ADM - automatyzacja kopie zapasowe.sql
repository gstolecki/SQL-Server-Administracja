/*

	Administracja Microsoft SQL Server

	Automatyzacja wykonywania i odtwarzania kopii zapasowych

	(c) Grzegorz Stolecki

*/

/*
	Ola Hallengren's Maintenance Solution
	https://ola.hallengren.com/
*/

-- sprawdzenie integralnoœci baz danych
EXECUTE [dbo].[DatabaseIntegrityCheck]
  @Databases = 'USER_DATABASES',
  @LogToTable = 'Y';

-- sprawdzenie logu wykonania
select * from master.dbo.CommandLog;

-- wykonanie kopii zapasowych wszystkich baz u¿ytkownika
EXECUTE [dbo].[DatabaseBackup]
  @Databases = 'USER_DATABASES',
  @Directory = 'C:\BAK',
  @BackupType = 'FULL',
  @Verify = 'Y',
  @CleanupTime = NULL,
  @CheckSum = 'Y',
  @LogToTable = 'Y';


/*
	DBATools - pakiet dla Powershell
	https://dbatools.io/
*/

/*

Restore-DbaDatabase -SqlInstance server1\instance1 -Path \\server2\backups

Restore-DbaDatabase -SqlInstance server1\instance1 -Path \\server2\backups -MaintenanceSolutionBackup -DestinationDataDirectory c:\restores

*/



