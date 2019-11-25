USE [master]
GO

SET NOCOUNT ON;

-- Common variables
DECLARE @NumberofInstances int;
SET @NumberofInstances = 1;             -- set this to the number of instances the server will host

-- Database Mail Account variables
DECLARE @AccountName nvarchar(128);     -- the "From" account name when email is sent from the default profile
DECLARE @AccountEmail nvarchar(128);    -- the "From" email address when email is sent from the default profile
DECLARE @MailServer nvarchar(128);      -- the Company mail server DNS alias
DECLARE @MailServerPort int;            -- the Company mail server TCP Port
DECLARE @SendTestEmail bit;             -- send a test email or not on creation of the Mail Profile

SET @AccountName = 'DBA Team';
SET @AccountEmail = 'dba.team@mycompany.com';
SET @MailServer = 'mailserver.mycompany.com';
SET @MailServerPort = 25;
SET @SendTestEmail = 0;

-- SA property variables
DECLARE @RenameSA bit;                  -- if "1" the "sa" login will be renamed
DECLARE @DisableSA bit;                 -- if "1" the "sa" login will be disabled

SET @RenameSA = 0;
SET @DisableSA = 0;

-- define Audit params
DECLARE @CreateServerAudit bit;			-- if "1" the Server Audit and Audit Specification will be created
DECLARE @OrganisationName nvarchar(50);	-- The Organisation Name which will be used to define the Audit name property. NOTE: All UPPERCASE and do not use spaces
DECLARE @AuditFolder nvarchar(128);     -- The path of the audit log. The file name is generated based on the audit name and audit GUID.
DECLARE @AuditMaxSizeMB int;            -- The maximum size to which the audit file can grow. The max_size value must be an integer followed by MB, GB, TB, or UNLIMITED.
                                        -- The minimum size that you can specify for max_size is 2 MB and the maximum is 2,147,483,647 TB. When UNLIMITED is specified, the file grows until the disk is full.
                                        -- (0 also indicates UNLIMITED.) Specifying a value lower than 2 MB will raise the error MSG_MAXSIZE_TOO_SMALL. The default value is UNLIMITED.
DECLARE @AuditMaxRolloverFileCount int; -- The maximum number of files to retain in the file system in addition to the current file. The MAX_ROLLOVER_FILES value must be an integer or UNLIMITED.
DECLARE @AuditReserverDiskSpace bit;    -- This option pre-allocates the file on the disk to the MAXSIZE value.

SET @CreateServerAudit = 0;
SET @OrganisationName = 'CONTOSO';
SET @AuditFolder = N'B:\MSSQL\AUDIT';
SET @AuditMaxSizeMB = 5;
SET @AuditMaxRolloverFileCount = 400;
SET @AuditReserverDiskSpace = 0;

-- define TEMPDB parameters
DECLARE @TempDBDataFileSize int;		-- the TEMPDB initial data file size (MB)
DECLARE @TempDBDataFileMaxSize int;		-- the TEMPDB maximum data file size (MB)
DECLARE @TempDBLogFileSize int;			-- the TEMPDB initial log file size (MB)
DECLARE @TempDBLogFileMaxSize int;		-- the TEMPDB maximum log file size (MB)

SET @TempDBDataFileSize = 1024;			-- MB
SET @TempDBDataFileMaxSize = 1024;		-- MB
SET @TempDBLogFileSize = 4000;			-- MB
SET @TempDBLogFileMaxSize = 4000;		-- MB

-- define default SQL Agent Operator
DECLARE @AlertOperatorName nvarchar(128);   -- the Name assigned to the default Operator
DECLARE @AlertOperatorEmail nvarchar(500);  -- the Email Address for the default Operator

SET @AlertOperatorName = @AccountName;  -- same as above
SET @AlertOperatorEmail = @AccountEmail;-- same as above


/* ************************************************** */
-- start here
DECLARE @InstanceName nvarchar(128);
SET @InstanceName = UPPER(ISNULL(@@SERVERNAME, CAST(SERVERPROPERTY('ServerName') AS nvarchar(128))));

CREATE TABLE #msver (
	[Index] int,
	[Name] nvarchar(128),
	[Internal_Value] sql_variant,
	[Character_Value] nvarchar(4000)
);
-- populate the table
INSERT INTO #msver EXEC xp_msver;

DECLARE @ProductVersion nvarchar(128);
SET @ProductVersion = CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(128));

DECLARE @EngineEdition nvarchar(128);
SET @EngineEdition = CAST(SERVERPROPERTY('Edition') AS nvarchar(128));

DECLARE @IsClustered bit;
SET @IsClustered = CAST(SERVERPROPERTY('IsClustered') AS bit);

DECLARE @IsHadrEnabled bit;
SET @IsHadrEnabled = CAST(SERVERPROPERTY('IsHadrEnabled') AS bit);

DECLARE @HostPlatform nvarchar(256); -- Windows or Linux
SET @HostPlatform = (SELECT TOP(1) host_platform FROM sys.dm_os_host_info);
DECLARE @FolderSeparator nchar(1); -- "\" or "/"
SET @FolderSeparator = CASE @HostPlatform WHEN 'Windows' THEN N'\' WHEN 'Linux' THEN N'/' END;

PRINT '--------------------------------------------------------------------------------';
PRINT 'Post-install configuration script running on ' + @InstanceName;
PRINT 'Engine Edition           = ' + @EngineEdition;
PRINT 'Product Version          = ' + @ProductVersion;
PRINT 'Is Clustered             = ' + CASE @IsClustered WHEN 0 THEN 'No' WHEN 1 THEN 'Yes' ELSE 'N/A' END;
PRINT 'Is HADR Enabled          = ' + CASE @IsHadrEnabled WHEN 0 THEN 'No' WHEN 1 THEN 'Yes' ELSE 'N/A' END;
PRINT 'Host Platform            = ' + @HostPlatform;
PRINT '================================================================================'
PRINT 'Operator-defined variable values:';
PRINT '  @NumberofInstances     = ' + CAST(@NumberofInstances AS varchar(15));
PRINT '';
PRINT '  @AccountName           = "' + @AccountName + '"';
PRINT '  @AccountEmail          = "' + @AccountEmail + '"';
PRINT '  @MailServer            = "' + @MailServer + '"';
PRINT '  @MailServerPort        = ' + CAST(@MailServerPort AS varchar(15));
PRINT '  @SendTestEmail         = ' + CASE @SendTestEmail WHEN 1 THEN 'Yes' ELSE 'No' END;
PRINT '';
PRINT '  @RenameSA              = ' + CASE @RenameSA WHEN 1 THEN 'Yes' ELSE 'No' END;
PRINT '  @DisableSA             = ' + CASE @DisableSA WHEN 1 THEN 'Yes' ELSE 'No' END;
PRINT '';
PRINT '  @OrganisationName      = "' + @OrganisationName + '"';
PRINT '  @CreateServerAudit     = ' + CASE @CreateServerAudit WHEN 1 THEN 'Yes' ELSE 'No' END;
PRINT '  @AuditFolder           = "' + @AuditFolder + '"';
PRINT '  @AuditMaxSizeMB        = ' + CAST(@AuditMaxSizeMB AS varchar(15));
PRINT '  @AuditMaxRolloverFileCount = ' + CAST(@AuditMaxRolloverFileCount AS varchar(15));
PRINT '  @AuditReserverDiskSpace = ' + CAST(@AuditReserverDiskSpace AS varchar(15));
PRINT '';
PRINT '  @TempDBDataFileSize    = ' + CAST(@TempDBDataFileSize AS varchar(10));
PRINT '  @TempDBDataFileMaxSize = ' + CAST(@TempDBDataFileMaxSize AS varchar(10));
PRINT '  @TempDBLogFileSize     = ' + CAST(@TempDBLogFileSize AS varchar(10));
PRINT '  @TempDBLogFileMaxSize  = ' + CAST(@TempDBLogFileMaxSize AS varchar(10));
PRINT '================================================================================'
PRINT '';

IF (@ProductVersion LIKE '9.%')
BEGIN
    PRINT 'NOTE: Auditing is not available in this version of SQL Server.';
    SET @CreateServerAudit = 0;
END
-- for 2008 and later versions (also, future proof check...)
IF (@ProductVersion LIKE '[1-9][0-9].%')
BEGIN
    IF ((@EngineEdition LIKE 'Developer%') OR (@EngineEdition LIKE 'Enterprise%')) AND
	   (@CreateServerAudit = 1)
    BEGIN
        SET @CreateServerAudit = 1;
    END
    ELSE
    BEGIN
        PRINT 'NOTE: Auditing is not available in this version of SQL Server.';
        SET @CreateServerAudit = 0;
    END
END

IF EXISTS (SELECT 1 FROM sys.configurations WHERE [name] = 'show advanced options' AND CAST([value] AS int) = 0)
BEGIN
	EXEC sys.sp_configure 'show advanced options', 1;
	RECONFIGURE WITH OVERRIDE;
END

DECLARE @SqlCmd nvarchar(2000);
DECLARE @ReturnValue int;

CREATE TABLE #fixeddrives (DriveLetter nchar(1), MBFree int);
INSERT INTO #fixeddrives EXEC xp_fixeddrives;

PRINT '';

/* ************************************************** */
-- 001_sql_server_memory
PRINT 'Configuring memory parameters:';
DECLARE @PhysicalMemoryAvailable int;
DECLARE @OSReservedMemory int;
DECLARE @MinServerMemory int;
DECLARE @MaxServerMemory int;

-- get values for Physical Memory available to the server
SET @PhysicalMemoryAvailable = (SELECT CAST([Internal_Value] AS int) FROM #msver WHERE [Name] = N'PhysicalMemory');

-- Reserve 1 GB of RAM for the OS, 
SET @OSReservedMemory = 1024;

-- 1 GB for each 4 GB of RAM installed from 4–16 GB, 
IF (@PhysicalMemoryAvailable BETWEEN 4096 AND 16384)
    SET @OSReservedMemory = @OSReservedMemory + (1024 * ((@PhysicalMemoryAvailable - 4096) / 4096))

-- and then 1 GB for every 8 GB RAM installed above 16 GB RAM.
IF (@PhysicalMemoryAvailable > 16384)
BEGIN
    SET @OSReservedMemory = @OSReservedMemory + (1024 * ((@PhysicalMemoryAvailable -  4096) / 4096))
    SET @OSReservedMemory = @OSReservedMemory + (1024 * ((@PhysicalMemoryAvailable - 16384) / 8192))
END

-- check Engine Edition
IF (@EngineEdition LIKE 'Express%')
    -- For Express Editions the @MaxServerMemory that can be allocated is 1024
    SET @MaxServerMemory = 1024;
ELSE
    SET @MaxServerMemory = FLOOR((((@PhysicalMemoryAvailable - @OSReservedMemory) / @NumberofInstances) / 1024)) * 1024;;

-- set the minumum to half the maximum allocation
SET @MinServerMemory = CASE WHEN @MaxServerMemory > 1024 THEN FLOOR(((@MaxServerMemory / 2) / 1024)) * 1024 ELSE 512 END;

/*
SELECT 
    @MinServerMemory AS MinServerMemory, @MaxServerMemory AS MaxServerMemory, 
    @PhysicalMemoryAvailable AS PhysicalMemoryAvailable, @OSReservedMemory AS OSReservedMemory
*/
PRINT '  Physical Memory Available = ' + CAST(@PhysicalMemoryAvailable AS varchar(15));
PRINT '  Min Server Memory value = ' + CAST(@MinServerMemory AS varchar(15));
PRINT '  Max Server Memory value = ' + CAST(@MaxServerMemory AS varchar(15));

-- check current and set parameter values
IF @MinServerMemory <> (
    SELECT CAST(value_in_use AS int) FROM sys.configurations 
    WHERE [name] = 'min server memory (MB)')
BEGIN
    EXEC sys.sp_configure 'min server memory', @MinServerMemory;
    RECONFIGURE WITH OVERRIDE;
END
ELSE
    PRINT 'Min Server Memory option did not require reconfiguration';

IF @MaxServerMemory <> (
    SELECT CAST(value_in_use AS int) FROM sys.configurations 
    WHERE [name] = 'max server memory (MB)')
BEGIN
    EXEC sys.sp_configure 'max server memory (MB)', @MaxServerMemory;
    RECONFIGURE WITH OVERRIDE;
END
ELSE
    PRINT 'Max Server Memory option did not require reconfiguration';

PRINT '';

/* ************************************************** */
-- 002_set_login_auditing
/*
0 - None
1 - Successful logins only
2 - Failed logins only
3 - Both failed and successful logins
*/
PRINT 'Setting login auditing to "Failed Only"';

EXEC xp_instance_regwrite 
    N'HKEY_LOCAL_MACHINE', 
    N'Software\Microsoft\MSSQLServer\MSSQLServer', 
    N'AuditLevel', 
    REG_DWORD, 2;

PRINT '';

/* ************************************************** */
-- 003_compress_backups
/*
Database Engine edition of the instance of SQL Server installed on the server.
1 = Personal or Desktop Engine (Not available in SQL Server 2005 and later versions.)
2 = Standard (This is returned for Standard, Web, and Business Intelligence.)
3 = Enterprise (This is returned for Evaluation, Developer, and both Enterprise editions.)
4 = Express (This is returned for Express, Express with Tools and Express with Advanced Services)
5 = SQL Azure
Base data type: int
*/
PRINT 'Enabling "backup compression default" and "backup checksum default" for Developer, Enterprise and Standard Editions only';

-- see http://msdn.microsoft.com/en-us/library/cc645993.aspx
-- check Engine Edition
IF (@EngineEdition LIKE 'Developer%') OR
   (@EngineEdition LIKE 'Enterprise%') OR
   (@EngineEdition LIKE 'Business Intelligence%') OR
   (@EngineEdition LIKE 'Standard%')
BEGIN
	-- check current and set parameter values
	IF (SELECT CAST(value_in_use AS int) FROM sys.configurations 
		WHERE [name] = 'backup compression default') <> 1
    BEGIN
		EXEC sp_configure 'backup compression default', 1;
		RECONFIGURE WITH OVERRIDE;
	END
    ELSE
    BEGIN
        PRINT 'Backup Compression option did not require reconfiguration';
    END
    
    -- check current and set parameter values
    IF (SELECT CAST(value_in_use AS int) FROM sys.configurations
        WHERE [name] = 'backup checksum default') <> 1
    BEGIN
        EXEC sp_configure 'backup checksum default', 1;
        RECONFIGURE WITH OVERRIDE;
    END
    ELSE
    BEGIN
        PRINT 'Backup Checksum option did not require reconfiguration';
    END
END -- check Engine Edition

PRINT '';

/* ************************************************** */
-- 004_set_maxdop
PRINT 'Setting "max degree of parallelism" option for Developer, Enterprise and Standard Editions only';
DECLARE @ProcessorCount int;
-- get values for Processor Count available to the server
SET @ProcessorCount = (SELECT CAST([Internal_Value] AS int) FROM #msver WHERE [Name] = N'ProcessorCount');
PRINT '  Processor Count = ' + CAST(@ProcessorCount AS varchar(15));
-- check Engine Edition
IF (@EngineEdition LIKE 'Developer%') OR
   (@EngineEdition LIKE 'Enterprise%') OR
   (@EngineEdition LIKE 'Business Intelligence%') OR
   (@EngineEdition LIKE 'Standard%')
BEGIN
	-- check current and set parameter values
	IF @ProcessorCount <> (
		SELECT CAST(value_in_use AS int) FROM sys.configurations 
		WHERE [name] = 'max degree of parallelism')
	BEGIN
		EXEC sys.sp_configure 'max degree of parallelism', @ProcessorCount;
		RECONFIGURE WITH OVERRIDE;
	END
	ELSE
		PRINT 'Max Degree of Parallelism option did not require reconfiguration';
END -- check Engine Edition
PRINT '';

/* ************************************************** */
-- 005_increase_errorlog_count
PRINT 'Increasing the number or ERRORLOG files to 99';
-- Increase the number of ErrorLog files to 99 
EXEC xp_instance_regwrite 
    N'HKEY_LOCAL_MACHINE', 
    N'Software\Microsoft\MSSQLServer\MSSQLServer', 
    N'NumErrorLogs', 
    REG_DWORD, 99;

PRINT 'Setting size limit of the ERRORLOG file to 30MB';
-- Set a limit for the size of the ErrorLog file (30MB).
EXEC xp_instance_regwrite 
    N'HKEY_LOCAL_MACHINE',
    N'Software\Microsoft\MSSQLServer\MSSQLServer', 
    N'ErrorLogSizeInKb', 
    REG_DWORD, 30720;

PRINT '';

/* ************************************************** */
-- 006_deploy_dbatoolbox
PRINT 'Deploying DBA Toolbox database';
DECLARE @device_directory nvarchar(1000);
DECLARE @compatibility_level int;
DECLARE @default_datafolder nvarchar(1000);
DECLARE @default_logfolder nvarchar(1000);
SET @device_directory = (
	SELECT SUBSTRING([physical_name], 1, CHARINDEX(N'master.mdf', LOWER([physical_name])) - 1)
	FROM sys.master_files WHERE [database_id] = DB_ID('master') AND [file_id] = 1);
SET @compatibility_level = (SELECT compatibility_level FROM sys.databases WHERE name = 'master');

IF (@ProductVersion < '13') -- all versiosn up to 2012
BEGIN
    EXEC xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultData', @default_datafolder OUTPUT;
    EXEC xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultLog', @default_logfolder OUTPUT;

    SET @default_datafolder = @default_datafolder + @FolderSeparator;
    SET @default_logfolder = @default_logfolder + @FolderSeparator;
END
ELSE -- all versions from 2012 R2 onwards
BEGIN
    -- these SERVERPROPERTY values are also available in Linux (ver >= 2017)
    SET @default_datafolder = CAST(SERVERPROPERTY('InstanceDefaultDataPath') AS nvarchar(128));
    SET @default_logfolder = CAST(SERVERPROPERTY('InstanceDefaultLogPath') AS nvarchar(128));
END

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'DBAToolbox')
BEGIN
    PRINT '  Creating database';
    SET @SqlCmd = N'USE [master];
CREATE DATABASE [DBAToolbox] ON PRIMARY ( 
    NAME = N''DBAToolbox'', 
    FILENAME = ''' + @default_datafolder + 'DBAToolbox.mdf'' , 
    SIZE = 5120KB , 
    FILEGROWTH = 1024KB )
LOG ON ( 
    NAME = N''DBAToolbox_log'', 
    FILENAME = ''' + @default_logfolder + 'DBAToolbox_log.ldf'' , 
    SIZE = 5120KB , 
    FILEGROWTH = 1024KB );';

    EXEC sp_executesql @SqlCmd;

    EXEC sys.sp_dbcmptlevel @dbname=N'DBAToolbox', @new_cmptlevel=@compatibility_level;

    ALTER DATABASE [DBAToolbox] SET RECOVERY SIMPLE;
	
    ALTER DATABASE [DBAToolbox] SET RESTRICTED_USER;

    ALTER DATABASE [DBAToolbox] SET AUTO_CLOSE OFF WITH NO_WAIT;

    PRINT '  DBA Toolbox database created';
END
ELSE
    PRINT 'DBA Toolbox already deployed';

-- check again...
IF NOT EXISTS (SELECT [name] FROM [sys].[databases] WHERE [name] = N'DBAToolbox')
BEGIN
    RAISERROR('Database DBAToolbox does not exist!', 16, 1);
    --RETURN -1;
END

PRINT '  Setting database owner for DBA Toolbox';
DECLARE @SALoginName sysname; -- login name for the 'sa'
SET @SqlCmd = '';
SET @SALoginName = (SELECT [name] FROM sys.sql_logins WHERE sid = 0x01);

SET @SqlCmd = 'USE [master];ALTER AUTHORIZATION ON DATABASE::[DBAToolbox] TO ' + @SALoginName;
EXEC sp_executesql @SqlCmd;

PRINT '
********************************************************************************
The DBA Toolbox has been deployed. Kindly ensure that the latest version of the 
SQL Server Maintenance Solution (scripts for running backups, integrity checks, 
and index and statistics maintenance) is downloaded from https://ola.hallengren.com/ 
and applied to the DBAToolbox database.
********************************************************************************';

PRINT '';

/* ************************************************** */
-- 007_set_databasemail
PRINT 'Setting Database Mail for Developer, Enterprise and Standard Editions only';
-- check Engine Edition
IF (@EngineEdition LIKE 'Developer%') OR
   (@EngineEdition LIKE 'Enterprise%') OR
   (@EngineEdition LIKE 'Business Intelligence%') OR
   (@EngineEdition LIKE 'Standard%')
BEGIN
    -- Database Mail Profile variables
    DECLARE @DBMailProfileName nvarchar(128);
    DECLARE @DBMailProfileDesc nvarchar(256);

    SET @DBMailProfileName = 'SQL Server Email Notifications - ' + @InstanceName;
    SET @DBMailProfileDesc = 'Email notification service for SQL Server ' + @InstanceName;
    PRINT '  Mail Profile Name = ' + @DBMailProfileName;
    PRINT '  Mail Profile Desc = ' + @DBMailProfileDesc;

    -- check if Service Broker is enabled on the MSDB database and prompt user
    IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE [name] = 'msdb' AND [is_broker_enabled] = 1)
    BEGIN
        PRINT '  Enabling Service Broker on the ''msdb'' database...'
        SET @SqlCmd = 'USE [master];ALTER DATABASE [msdb] SET ENABLE_BROKER;';
        EXEC sp_executesql @SqlCmd;
    END

    -- check if the 'Database Mail XPs' configuration option is enabled and enable if not
    IF NOT EXISTS(SELECT 1 FROM sys.configurations WHERE [name] = 'Database Mail XPs' AND [value] = 1)
    BEGIN
        PRINT '  Enabling "Database Mail XPs" option';
        IF NOT EXISTS (SELECT 1 FROM sys.configurations WHERE [name] = 'show advanced options' AND [value] = 1)
        BEGIN
            EXEC sp_configure 'show advanced options', 1;
            RECONFIGURE WITH OVERRIDE;
        END
        EXEC sp_configure 'Database Mail XPs', 1;
        RECONFIGURE WITH OVERRIDE;
    END

    -- Create a Database Mail profile
        PRINT '  Create a Database Mail profile';
	IF NOT EXISTS(SELECT 1 FROM msdb.dbo.sysmail_profile WHERE [name] = @DBMailProfileName AND [description] = @DBMailProfileDesc)
	BEGIN
            EXECUTE msdb.dbo.sysmail_add_profile_sp
                @profile_name = @DBMailProfileName,
                @description = @DBMailProfileDesc;
	END
    ELSE
        PRINT 'Database Mail Profile already created';
	
    -- Create a Database Mail account
    PRINT '  Create a Database Mail account';
    IF NOT EXISTS(SELECT 1 FROM msdb.dbo.sysmail_account WHERE [name] = @AccountName AND [description] = @AccountName AND [email_address] = @AccountEmail)
    BEGIN
        EXECUTE msdb.dbo.sysmail_add_account_sp
            @account_name = @AccountName,
            @description = @AccountName,
            @email_address = @AccountEmail,
            @replyto_address = @AccountEmail,
            @display_name = @DBMailProfileName,
            @mailserver_name = @MailServer,
            @port = @MailServerPort;
    END
    ELSE
        PRINT 'Database Mail Account already created';

    -- Add the account to the profile
	PRINT '  Add the account to the profile';
	IF NOT EXISTS(
		SELECT 1 FROM msdb.dbo.sysmail_profileaccount pa
			INNER JOIN msdb.dbo.sysmail_profile p ON pa.profile_id = p.profile_id
			INNER JOIN msdb.dbo.sysmail_account a ON pa.account_id = a.account_id
		WHERE p.name = @DBMailProfileName AND a.name = @AccountName)
	BEGIN
		EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
			@profile_name = @DBMailProfileName,
			@account_name = @AccountName,
			@sequence_number =1;
	END
    ELSE
        PRINT 'Database Mail Account already added to the Profile';
	
    -- Grant access to the profile to the DBMailUsers role
	PRINT '  Grant access to the profile to the DBMailUsers role';
	IF NOT EXISTS(
		SELECT * FROM msdb.dbo.sysmail_principalprofile pp
			INNER JOIN msdb.dbo.sysmail_profile p ON pp.profile_id = p.profile_id
		WHERE p.[name] = @DBMailProfileName AND pp.[is_default] = 1)
    BEGIN
		EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
			@profile_name = @DBMailProfileName,
			@principal_id = 0,
			@is_default = 1;
	END
    ELSE
        PRINT 'The DBMailUsers role already has access to the profile';

    /*
    SELECT * FROM msdb.dbo.sysmail_profile
    SELECT * FROM msdb.dbo.sysmail_account
    */

    -- Send test email notification
    IF (@SendTestEmail = 1)
    BEGIN
	    PRINT '  Send test email notification';
        DECLARE @TestMailSubject nvarchar(128);
        DECLARE @TestMailMessage nvarchar(2000);
        SET @TestMailSubject = 'Testing a Database Mail Profile from ' + @InstanceName;
        SET @TestMailMessage = @DBMailProfileDesc + N'

        This is a test email sent from ' + @InstanceName + N' using Database Mail';
        EXEC msdb.dbo.sp_send_dbmail 
            @profile_name = @DBMailProfileName,
            @recipients = @AccountEmail,
            @subject = @TestMailSubject,
            @body = @TestMailMessage,
            @body_format = 'TEXT';
    END

END -- check Engine Edition

PRINT '';


/* ************************************************** */
-- 008_sqlagent_alerting_mechanism
PRINT 'Setting SQL Agent Alerting for Developer, Enterprise and Standard Editions only';
/*
00. Check whether the OS platform is Windows
01. Create default Operator
02. For 2005 and later enable SQL Agent Alert System and set failsafe operator
03. Create Alerts
04. Update Alert default Operator
*/

-- check host platform
IF (@HostPlatform = 'Windows')
BEGIN
    -- check Engine Edition
    IF (@EngineEdition LIKE 'Developer%') OR
    (@EngineEdition LIKE 'Enterprise%') OR
    (@EngineEdition LIKE 'Business Intelligence%') OR
    (@EngineEdition LIKE 'Standard%')
    BEGIN
        CREATE TABLE #AlertInfo (
            FailSafeOperator nvarchar(255) NULL,
            NotificationMethod int NULL,
            ForwardingServer nvarchar(255) NULL,
            ForwardingSeverity int NULL,
            ForwardAlways int NULL,
            PagerToTemplate nvarchar(255) NULL,
            PagerCCTemplate nvarchar(255) NULL,
            PagerSubjectTemplate nvarchar(255) NULL,
            PagerSendSubjectOnly int NULL
        );
        INSERT INTO #AlertInfo EXEC sp_MSgetalertinfo;

        /* ******************** */
        /* ***** OPERATOR ***** */
        /* ******************** */
        PRINT '  Creating Operator ' + @AlertOperatorName;
        IF EXISTS(SELECT name FROM msdb.dbo.sysoperators WHERE name = @AlertOperatorName)
            -- check if the operator is the fail-safe operator
            IF NOT EXISTS (SELECT 1 FROM #AlertInfo WHERE FailSafeOperator = @AlertOperatorName)
                EXEC msdb.dbo.sp_delete_operator @name=@AlertOperatorName
            ELSE
                PRINT 'Operator is the fail-safe operator and cannot be deleted';

        IF NOT EXISTS(SELECT name FROM msdb.dbo.sysoperators WHERE name = @AlertOperatorName)
            EXEC msdb.dbo.sp_add_operator @name=@AlertOperatorName, 
                @enabled=1, 
                @weekday_pager_start_time=90000, 
                @weekday_pager_end_time=180000, 
                @saturday_pager_start_time=90000, 
                @saturday_pager_end_time=180000, 
                @sunday_pager_start_time=90000, 
                @sunday_pager_end_time=180000, 
                @pager_days=0, 
                @email_address=@AlertOperatorEmail, 
                @category_name=N'[Uncategorized]'
        ELSE
            PRINT 'Operator already exists';


        /* ******************************** */
        /* ***** SQL AGENT PROPERTIES ***** */
        /* ******************************** */
        -- Enable Mail Profile
        PRINT '  Enable Mail Profile';
        EXEC master.dbo.xp_instance_regwrite 
            N'HKEY_LOCAL_MACHINE', 
            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', 
            N'UseDatabaseMail', 
            N'REG_DWORD', 1;

        -- Set Mail Profile name
        PRINT '  Set Mail Profile name';
        DECLARE @MailProfile nvarchar(256);
        SET @MailProfile=(SELECT TOP(1) [name] FROM msdb.dbo.sysmail_profile);
        PRINT '  Mail Profile = ' + @MailProfile;
        EXEC master.dbo.xp_instance_regwrite 
            N'HKEY_LOCAL_MACHINE', 
            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', 
            N'DatabaseMailProfile', 
            N'REG_SZ', 
            @MailProfile;

        -- Save copies of the sent messages in the Sent Items folder
        -- Replace tokens for all job responses to alerts
        PRINT '  Save copies of the sent messages in the Sent Items folder';
        PRINT '  Replace tokens for all job responses to alerts';
        EXEC msdb.dbo.sp_set_sqlagent_properties 
            @email_save_in_sent_folder=1, 
            @alert_replace_runtime_tokens=1

        -- Check for Failsafe Operator and set
        PRINT '  Check for Failsafe Operator and set to "' + @AlertOperatorName + '"';
        IF NOT EXISTS (SELECT 1 FROM #AlertInfo WHERE FailSafeOperator IS NOT NULL)
        BEGIN
            EXEC master.dbo.sp_MSsetalertinfo 
                @failsafeoperator=@AlertOperatorName, 
                @notificationmethod=1 -- notify using email
        END

        DROP TABLE #AlertInfo;


        /* ****************** */
        /* ***** ALERTS ***** */
        /* ****************** */
        PRINT '  Creating Alerts';
        -- Error 9100 - Index Corruption (2005 and later)
        PRINT '    Error 9100 - Index Corruption (2005 and later)';
        IF EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Error 9100 - Index Corruption')
            EXEC msdb.dbo.sp_delete_alert @name=N'Error 9100 - Index Corruption';

        EXEC msdb.dbo.sp_add_alert @name=N'Error 9100 - Index Corruption', 
            @message_id=9100, 
            @severity=0, 
            @enabled=1, 
            @include_event_description_in=7,
            @delay_between_responses=1800, 
            @category_name=N'[Uncategorized]' ;

        -- Severity 14 - Login failed for user 'sa'
        PRINT '    Severity 14 - Login failed for user "sa"';
        IF EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 14 - Login failed for user ''sa''')
            EXEC msdb.dbo.sp_delete_alert @name=N'Severity 14 - Login failed for user ''sa''';

        EXEC msdb.dbo.sp_add_alert @name=N'Severity 14 - Login failed for user ''sa''', 
            @message_id=0, 
            @severity=14, 
            @enabled=1, 
            @delay_between_responses=60, 
            @include_event_description_in=1, 
            @event_description_keyword=N'Login failed for user ''sa''', 
            @category_name=N'[Uncategorized]', 
            @job_id=N'00000000-0000-0000-0000-000000000000';

        -- Severity 17 - Insufficient Resources
        PRINT '    Severity 17 - Insufficient Resources';
        IF EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 17 - Insufficient Resources')
            EXEC msdb.dbo.sp_delete_alert @name=N'Severity 17 - Insufficient Resources';

        EXEC msdb.dbo.sp_add_alert @name=N'Severity 17 - Insufficient Resources', 
            @message_id=0, 
            @severity=17, 
            @enabled=1, 
            @delay_between_responses=1800, 
            @include_event_description_in=7;

        -- Severity 19 - Fatal Error in Resource
        PRINT '    Severity 19 - Fatal Error in Resource';
        IF EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 19 - Fatal Error in Resource')
            EXEC msdb.dbo.sp_delete_alert @name=N'Severity 19 - Fatal Error in Resource';

        EXEC msdb.dbo.sp_add_alert @name=N'Severity 19 - Fatal Error in Resource', 
            @message_id=0, 
            @severity=19, 
            @enabled=1, 
            @delay_between_responses=1800, 
            @include_event_description_in=7;

        -- Severity 20 - Fatal Error in current process
        PRINT '    Severity 20 - Fatal Error in current process';
        IF EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 20 - Fatal Error in current process')
            EXEC msdb.dbo.sp_delete_alert @name=N'Severity 20 - Fatal Error in current process';

        EXEC msdb.dbo.sp_add_alert @name=N'Severity 20 - Fatal Error in current process', 
            @message_id=0, 
            @severity=20, 
            @enabled=1, 
            @delay_between_responses=1800, 
            @include_event_description_in=7;

        -- Severity 21 - Fatal Error in Database Processes
        PRINT '    Severity 21 - Fatal Error in Database Processes';
        IF EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 21 - Fatal Error in Database Processes')
            EXEC msdb.dbo.sp_delete_alert @name=N'Severity 21 - Fatal Error in Database Processes';

        EXEC msdb.dbo.sp_add_alert @name=N'Severity 21 - Fatal Error in Database Processes', 
            @message_id=0, 
            @severity=21, 
            @enabled=1, 
            @delay_between_responses=1800, 
            @include_event_description_in=7;

        -- Severity 22 - Fatal Error: Table integrity suspect
        PRINT '    Severity 22 - Fatal Error: Table integrity suspect';
        IF EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 22 - Fatal Error: Table integrity suspect')
            EXEC msdb.dbo.sp_delete_alert @name=N'Severity 22 - Fatal Error: Table integrity suspect';

        EXEC msdb.dbo.sp_add_alert @name=N'Severity 22 - Fatal Error: Table integrity suspect', 
            @message_id=0, 
            @severity=22, 
            @enabled=1, 
            @delay_between_responses=1800, 
            @include_event_description_in=7;

        -- Severity 23 - Fatal Error: Database integrity suspect
        PRINT '    Severity 23 - Fatal Error: Database integrity suspect';
        IF EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 23 - Fatal Error: Database integrity suspect')
            EXEC msdb.dbo.sp_delete_alert @name=N'Severity 23 - Fatal Error: Database integrity suspect';

        EXEC msdb.dbo.sp_add_alert @name=N'Severity 23 - Fatal Error: Database integrity suspect', 
            @message_id=0, 
            @severity=23, 
            @enabled=1, 
            @delay_between_responses=1800, 
            @include_event_description_in=7;

        -- Severity 24 - Fatal Error: Hardware error
        PRINT '    Severity 24 - Fatal Error: Hardware error';
        IF EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 24 - Fatal Error: Hardware error')
            EXEC msdb.dbo.sp_delete_alert @name=N'Severity 24 - Fatal Error: Hardware error';

        EXEC msdb.dbo.sp_add_alert @name=N'Severity 24 - Fatal Error: Hardware error', 
            @message_id=0, 
            @severity=24, 
            @enabled=1, 
            @delay_between_responses=1800, 
            @include_event_description_in=7;

        -- Severity 25 - Fatal Error
        PRINT '    Severity 25 - Fatal Error';
        IF EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 25 - Fatal Error')
            EXEC msdb.dbo.sp_delete_alert @name=N'Severity 25 - Fatal Error';

        EXEC msdb.dbo.sp_add_alert @name=N'Severity 25 - Fatal Error', 
            @message_id=0, 
            @severity=25, 
            @enabled=1, 
            @delay_between_responses=1800, 
            @include_event_description_in=7;


        /* ************************* */
        /* ***** NOTIFICATIONS ***** */
        /* ************************* */
        PRINT '  Create Notifications';
        PRINT '    Error 9100 - Index Corruption';
        EXEC msdb.dbo.sp_add_notification 
            @alert_name=N'Error 9100 - Index Corruption', 
            @operator_name=@AlertOperatorName, 
            @notification_method = 1;

        PRINT '    Severity 14 - Login failed for user "sa"';
        EXEC msdb.dbo.sp_add_notification 
            @alert_name=N'Severity 14 - Login failed for user ''sa''', 
            @operator_name=@AlertOperatorName, 
            @notification_method = 1;

        PRINT '    Severity 17 - Insufficient Resources';
        EXEC msdb.dbo.sp_add_notification 
            @alert_name=N'Severity 17 - Insufficient Resources', 
            @operator_name=@AlertOperatorName, 
            @notification_method = 1;

        PRINT '    Severity 19 - Fatal Error in Resource';
        EXEC msdb.dbo.sp_add_notification 
            @alert_name=N'Severity 19 - Fatal Error in Resource', 
            @operator_name=@AlertOperatorName, 
            @notification_method = 1;

        PRINT '    Severity 20 - Fatal Error in current process';
        EXEC msdb.dbo.sp_add_notification 
            @alert_name=N'Severity 20 - Fatal Error in current process', 
            @operator_name=@AlertOperatorName, 
            @notification_method = 1;

        PRINT '    Severity 21 - Fatal Error in Database Processes';
        EXEC msdb.dbo.sp_add_notification 
            @alert_name=N'Severity 21 - Fatal Error in Database Processes', 
            @operator_name=@AlertOperatorName, 
            @notification_method = 1;

        PRINT '    Severity 22 - Fatal Error: Table integrity suspect';
        EXEC msdb.dbo.sp_add_notification 
            @alert_name=N'Severity 22 - Fatal Error: Table integrity suspect', 
            @operator_name=@AlertOperatorName, 
            @notification_method = 1;

        PRINT '    Severity 23 - Fatal Error: Database integrity suspect';
        EXEC msdb.dbo.sp_add_notification 
            @alert_name=N'Severity 23 - Fatal Error: Database integrity suspect', 
            @operator_name=@AlertOperatorName, 
            @notification_method = 1;

        PRINT '    Severity 24 - Fatal Error: Hardware error';
        EXEC msdb.dbo.sp_add_notification 
            @alert_name=N'Severity 24 - Fatal Error: Hardware error', 
            @operator_name=@AlertOperatorName, 
            @notification_method = 1;

        PRINT '    Severity 25 - Fatal Error';
        EXEC msdb.dbo.sp_add_notification 
            @alert_name=N'Severity 25 - Fatal Error', 
            @operator_name=@AlertOperatorName, 
            @notification_method = 1;

    END -- check Engine Edition

END -- check host platform
ELSE
    PRINT '  SQL Agent functionality not available/supported on ' + @HostPlatform

PRINT ''


/* ************************************************** */
-- 009_rename_sa_login
PRINT 'Rename and/or Disable SA login?';
IF (@RenameSA = 1)
BEGIN
    IF EXISTS(SELECT 1 FROM sys.server_principals WHERE [sid] = 0x01 AND [name] = 'sa')
    BEGIN
        ALTER LOGIN [sa] WITH NAME=[sqladmin];
	    PRINT '  SA login renamed';
    END
    ELSE
        PRINT '  SA login with that name does not exist';
END
ELSE
	PRINT '  SA login NOT renamed';

IF (@DisableSA = 1)
BEGIN
    IF (@RenameSA = 1)
        IF EXISTS(SELECT 1 FROM sys.server_principals WHERE [sid] = 0x01 AND [name] = 'sqladmin')
            ALTER LOGIN [sqladmin] DISABLE;
    ELSE
        IF EXISTS(SELECT 1 FROM sys.server_principals WHERE [sid] = 0x01 AND [name] = 'sa')
            ALTER LOGIN [sa] DISABLE;
	PRINT '  SA login disabled';
END
ELSE
	PRINT '  SA login NOT disabled';

PRINT '';


/* ************************************************** */
-- 010_reconfigure_tempdb
PRINT 'Reconfigure TEMPDB';

-- added check to avoid reconfiguring tempdb for SQL Server 2016 and later versions - the installation does it for you; 
-- a "cleaner" solution will be provided in due course
IF (@ProductVersion < '13')
BEGIN
	-- Modify properties of main tempdb file (NOTE: the properties here will be used to create additional tempdb files)
	PRINT '  Modify properties of main tempdb file';

	-- check if the destination drive has enough free space
	SET @device_directory = (SELECT physical_name FROM tempdb.sys.database_files WHERE [name] = 'tempdev' and [file_id] = 1);
	-- verify drive letter
	IF EXISTS(SELECT 1 FROM #fixeddrives WHERE DriveLetter = LEFT(@device_directory, 1))
	BEGIN
		-- current size
		-- check if enough space
		IF ((SELECT MBFree FROM #fixeddrives WHERE DriveLetter = LEFT(@device_directory, 1)) < 
				@TempDBDataFileSize)
			PRINT '  ***** Not enough space to extend main TEMPDB data file *****';
		ELSE
		BEGIN
			-- compare existing to new size
			IF ((SELECT ([size]*8)/1024 FROM tempdb.sys.database_files WHERE [name] = 'tempdev' and [file_id] = 1) <=
				@TempDBDataFileSize)
			BEGIN
				SET @SqlCmd = N'USE [master];
ALTER DATABASE [tempdb] 
    MODIFY FILE ( 
        NAME = N''tempdev'', 
        SIZE = ' + CAST(@TempDBDataFileSize AS varchar(10)) + N'MB);
';
				EXEC sp_executesql @SqlCmd;
			END -- compare existing to new size
			ELSE
				PRINT '  ***** The existing TEMPDB primary data file is larger than the supplied size parameter *****';
		END -- check if enough space

		-- max size
		-- check if enough space
		IF ((SELECT MBFree FROM #fixeddrives WHERE DriveLetter = LEFT(@device_directory, 1)) < 
				@TempDBDataFileMaxSize)
			PRINT '  ***** Not enough space for maximum TEMPDB data file size *****';
		ELSE
		BEGIN
			-- compare existing to new size
			IF ((SELECT ([size]*8)/1024 FROM tempdb.sys.database_files WHERE [name] = 'tempdev' and [file_id] = 1) <=
				@TempDBDataFileMaxSize)
			BEGIN
				SET @SqlCmd = N'USE [master];
ALTER DATABASE [tempdb] 
    MODIFY FILE ( 
        NAME = N''tempdev'', 
		MAXSIZE = ' + CAST(@TempDBDataFileMaxSize AS varchar(10)) + N'MB ,
		FILEGROWTH = 0);
';
				EXEC sp_executesql @SqlCmd;
			END -- compare existing to new size
			ELSE
				PRINT '  ***** The existing TEMPDB primary data file is larger than the supplied maximum size parameter *****';
		END -- check if enough space
	END -- verify drive letter

	-- variables for dynamic tempdb properties
	--DECLARE @device_directory nvarchar(1000);
	DECLARE @size int, @max_size int, @growth int, @is_percent_growth bit;
	-- variables for CPU count and number of tempdb files
	DECLARE @ExtraFiles tinyint;
	DECLARE @FileNumber tinyint;

	-- get values for dynamic tempdb properties
	SELECT 
		@device_directory = SUBSTRING([physical_name], 1, CHARINDEX(N'tempdb.mdf', LOWER([physical_name])) - 1),
		@size = ([size]*8), 
		@max_size = (CASE [max_size] WHEN 0 THEN 0 WHEN -1 THEN -1 ELSE ([max_size]*8) END),
		@growth = (CASE [growth] WHEN 0 THEN 0 ELSE (CASE [is_percent_growth] WHEN 0 THEN ([growth]*8) WHEN 1 THEN [growth] END) END),
		@is_percent_growth = [is_percent_growth]
	FROM tempdb.sys.database_files WHERE [file_id] = 1;
	/*
	NOTE:
	If is_percent_growth = 0, growth increment is in units of 8-KB pages, rounded to the nearest 64 KB
	If is_percent_growth = 1, growth increment is expressed as a whole number percentage.
	*/


	-- get values for Processor Count and number of tempdb files
	-- check Engine Edition
	IF (@EngineEdition LIKE 'Developer%') OR
	   (@EngineEdition LIKE 'Enterprise%') OR
	   (@EngineEdition LIKE 'Business Intelligence%') OR
	   (@EngineEdition LIKE 'Standard%')
	BEGIN
		-- Skipped for Express Editions - the maximum Processor Count that can be allocated is 1
		SET @ExtraFiles = CONVERT(tinyint, (SELECT [Internal_Value] FROM #msver WHERE [Name] = 'ProcessorCount'));
		-- set a maximum threshold of 8 tempdb files per system
		IF @ExtraFiles > 8 SET @ExtraFiles = 8;
		-- remove "1" from the value returned to cater for the default (existing) file
		SET @ExtraFiles = @ExtraFiles - 1;
	
		-- check if the destination drive has enough free space
		-- verify drive letter
		IF EXISTS(SELECT 1 FROM #fixeddrives WHERE DriveLetter = LEFT(@device_directory, 1))
		BEGIN
			-- check if enough space
			IF ((SELECT MBFree FROM #fixeddrives WHERE DriveLetter = LEFT(@device_directory, 1)) < 
				(@TempDBDataFileSize * @ExtraFiles))
			BEGIN
				PRINT '  ***** Not enough space to create extra TEMPDB data files *****';
				SET @ExtraFiles = 0;
			END -- check if enough space
		END -- verify drive letter
	
		-- create additional files (if all conditions are met)
		PRINT '  Create additional files';
		IF (@ExtraFiles > 0)
		BEGIN
			SET @FileNumber = 1;
			WHILE (@FileNumber <= @ExtraFiles)
			BEGIN
				-- check if file exists (...just in case!)
				IF NOT EXISTS (
					SELECT 1 FROM tempdb.sys.database_files WHERE [name] = 'tempdev_' + CAST(@FileNumber AS nvarchar(3)))
				BEGIN
					SET @SqlCmd = N'
ALTER DATABASE [tempdb] 
	ADD FILE ( 
		NAME = N''tempdev_' + CAST(@FileNumber AS nvarchar(3)) + ''', 
		FILENAME = ''' + @device_directory + 'tempdb_' + CAST(@FileNumber AS nvarchar(3)) + N'.ndf'' , 
		SIZE = ' + CAST(@size AS nvarchar(50)) + N'KB, 
		MAXSIZE = ' + CASE WHEN @max_size = -1 THEN N'UNLIMITED' ELSE CAST(@max_size AS nvarchar(50)) + N'KB' END + N', 
		FILEGROWTH = ' + CAST(@growth AS nvarchar(50)) + CASE @is_percent_growth WHEN 0 THEN N'KB' ELSE N'%' END + N')';
					EXEC sp_executesql @SqlCmd;
				END
				SET @FileNumber = @FileNumber + 1;
			END -- WHILE LOOP
		END -- check @ExtraFiles > 0
	END -- check Engine Edition
END

-- modify tempdb LOG file
PRINT '  Modify tempdb LOG file';
-- shrink the log file
SET @SqlCmd = N'USE [tempdb];DBCC SHRINKFILE (N''templog'' , 1024) WITH NO_INFOMSGS;'
EXEC sp_executesql @SqlCmd;
-- check if the destination drive has enough free space
SET @device_directory = (SELECT physical_name FROM tempdb.sys.database_files WHERE [name] = 'templog' and [file_id] = 2);
-- verify drive letter
IF EXISTS(SELECT 1 FROM #fixeddrives WHERE DriveLetter = LEFT(@device_directory, 1))
BEGIN
    -- check if enough space
	IF ((SELECT MBFree FROM #fixeddrives WHERE DriveLetter = LEFT(@device_directory, 1)) < 
		    @TempDBLogFileSize)
		PRINT '  ***** Not enough space to extend the TEMPDB log file *****';
	ELSE
	BEGIN
        -- compare existing to new size
        IF ((SELECT ([size]*8)/1024 FROM tempdb.sys.database_files WHERE [name] = 'templog' and [file_id] = 2) <=
            @TempDBLogFileSize)
        BEGIN
		    SET @SqlCmd = N'
ALTER DATABASE [tempdb] 
    MODIFY FILE ( 
        NAME = N''templog'', 
        SIZE = ' + CAST(@TempDBLogFileSize AS varchar(10)) + N'MB , 
        MAXSIZE = ' + CAST(@TempDBLogFileMaxSize AS varchar(10)) + N'MB ,
		FILEGROWTH = 0);
';
		    EXEC sp_executesql @SqlCmd;
        END -- compare existing to new size
        ELSE
            PRINT '  ***** The existing TEMPDB log file is larger than the supplied parameter *****';
	END -- check if enough space
END -- verify drive letter

PRINT '';

/* ************************************************** */
-- 011_sql_server_auditing
PRINT 'Add SQL Server Auditing for Developer, Enterprise and Standard Editions only';
IF (@CreateServerAudit = 1)
BEGIN
	PRINT '  NOTE: When a server audit is created, it is in a disabled state';
	-- define audit params
	-- NOTE: When a server audit is created, it is in a disabled state.

	-- check Engine Edition
	IF (@EngineEdition LIKE 'Developer%') OR
	   (@EngineEdition LIKE 'Enterprise%') OR
	   (@EngineEdition LIKE 'Business Intelligence%') OR
	   (@EngineEdition LIKE 'Standard%')
	BEGIN
		/*
		The minimum size that you can specify for max_size is 2 MB and the maximum is 2,147,483,647 TB. When UNLIMITED is specified, the file grows until the disk is full. 
		(0 also indicates UNLIMITED.) Specifying a value lower than 2 MB will raise the error MSG_MAXSIZE_TOO_SMALL. The default value is UNLIMITED.
		*/
		IF (@AuditMaxSizeMB < 2)
			SET @AuditMaxSizeMB = 5;

		/*
		Check that enough storage is available with the configuration parameters defined for the audit
		*/
		PRINT '  Check that enough storage is available with the configuration parameters defined for the audit';
		DECLARE @AuditDriveMBFree int;
		IF EXISTS(SELECT 1 FROM #fixeddrives WHERE DriveLetter = LEFT(@AuditFolder, 1))
		BEGIN
			SET @AuditDriveMBFree = (SELECT MBFree FROM #fixeddrives WHERE DriveLetter = LEFT(@AuditFolder, 1));
			EXEC @ReturnValue = [master].[dbo].xp_create_subdir @AuditFolder;
			IF (@ReturnValue <> 0) 
			BEGIN
				RAISERROR('Error creating directory for Server Audit content.', 16, 1);
				--RETURN -1;
			END
		END
		ELSE
		BEGIN
			RAISERROR('The Server Audit destination Drive is not available!', 16, 1);
			--RETURN -1;
		END

		-- change default params if the total space required for the audit is greater than 1/5 of the available disk space
		IF ((@AuditMaxSizeMB * @AuditMaxRolloverFileCount) >= (@AuditDriveMBFree / 5))
		BEGIN
			-- set the maximum size to the minimum allocated
			SET @AuditMaxSizeMB = 2;
			-- set the number of files to fill a maximum of 1/5 of the available disk space
			SET @AuditMaxRolloverFileCount = FLOOR((@AuditDriveMBFree / 5) / @AuditMaxSizeMB);
		END

		-- create server audit
		SET @OrganisationName = UPPER(REPLACE(@OrganisationName, ' ', ''));
		PRINT '  Creating Server Audit for organisation: ' + @OrganisationName;
		IF NOT EXISTS(SELECT 1 FROM sys.server_audits WHERE [name] = @OrganisationName + N'_STANDARD_AUDIT')
		BEGIN
			SET @SqlCmd = N'USE [master];
CREATE SERVER AUDIT [' + @OrganisationName + N'_STANDARD_AUDIT]
TO FILE (
	FILEPATH = ''' + @AuditFolder + N'''
	, MAXSIZE = ' + CAST(@AuditMaxSizeMB AS nvarchar(10)) + ' MB
	, MAX_ROLLOVER_FILES = ' + CAST(@AuditMaxRolloverFileCount AS nvarchar(10)) + N'
	, RESERVE_DISK_SPACE = ' + CASE @AuditReserverDiskSpace WHEN 0 THEN N'OFF' ELSE N'ON' END + N'
)
WITH (
	QUEUE_DELAY = 1000          ' + -- Determines the time, in milliseconds, that can elapse before audit actions are forced to be processed. A value of 0 indicates synchronous delivery.
N'	, ON_FAILURE = CONTINUE     ' + -- Indicates whether the instance writing to the target should fail, continue, or stop SQL Server if the target cannot write to the audit log.
N')';

			EXEC sp_executesql @SqlCmd;

			-- for 2012 and later versions (also, future proof check...)
			IF (@ProductVersion LIKE '[1-9][1-9].%')
			BEGIN
				SET @SqlCmd = N'USE [master];
ALTER SERVER AUDIT [' + @OrganisationName + N'_STANDARD_AUDIT]
WHERE
--  The following line is used solely to ensure that the WHERE statement begins with a clause 
--  that is guaranteed true.  This allows us to begin each subsequent line with AND, making
--  editing easier.  If you wish, you may remove this line (and the first AND).
([Statement] <> ''BBF5B619-D44A-4616-A259-CDD9D426D794'')

-- exclude "tempdb" (i.e. temporary tables) from capture
AND ([database_name] <> N''tempdb'')

--  The following filters out system-generated statements accessing SQL Server internal tables
--  that are not directly visible to or accessible by user processes, but which do appear among 
--  log records if not suppressed.
AND    NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''syspalnames'')
AND    NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''objects$'')
AND    NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''syspalvalues'')
AND    NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''configurations$'')
AND    NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''system_columns$'')
AND    NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''server_audits$'')
AND    NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''parameters$'')


--  The following suppresses audit trail messages about the execution of statements within procedures 
--  and functions.  This is done because it is generally not useful to trace internal operations 
--  of a function or procedure, and this is a simple way to detect them.
--  However, this opens an opportunity for an adversary to obscure actions on the database,
--  so make sure that the creation and modification of functions and procedures is tracked.
--  Further, details of your application architecture may be incompatible with this technique.
--  Use with care.
AND NOT ([Additional_Information] LIKE ''<tsql_stack>%'')


--  The following statements filter out audit records for certain system-generated actions that 
--  frequently occur, and which do not aid in tracking the activities of a user or process.
AND NOT([Schema_Name] = ''sys'' AND [Statement] LIKE 
        ''SELECT%clmns.name%FROM%sys.all_views%sys.all_columns%sys.indexes%sys.index_columns%sys.computed_columns%sys.identity_columns%sys.objects%sys.types%sys.schemas%sys.types%''
        )
AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] <> ''databases'' AND [Statement] LIKE 
        ''SELECT%dtb.name%AS%dtb.state%A%FROM%master.sys.databases%dtb''
        )
AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] <> ''databases'' AND [Statement] LIKE 
        ''%SELECT%clmns.column_id%,%clmns.name%,%clmns.is_nullable%,%CAST%ISNULL%FROM%sys.all_views%AS%v%INNER%JOIN%sys.all_columns%AS%clmns%ON%clmns.object_id%v.object_id%LEFT%OUTER%JOIN%sys.indexes%AS%ik%ON%ik.object_id%clmns.object_id%and%1%ik.is_primary_key%''
        )

 
--  Numerous log records are generated when the SQL Server Management Studio Log Viewer itself is 
--  populated or refreshed.  The following filters out the less useful of these, while not hiding the
--  fact that metadata about the log was accessed.
AND NOT ([Schema_Name] = ''sys'' AND [Statement] LIKE 
        ''SELECT%dtb.name AS%,%dtb.database_id AS%,%CAST(has_dbaccess(dtb.name) AS bit) AS%FROM%master.sys.databases AS dtb%ORDER BY%ASC''
        )
AND NOT ([Schema_Name] = ''sys'' AND [Statement] LIKE 
        ''SELECT%dtb.collation_name AS%,%dtb.name AS%FROM%master.sys.databases AS dtb%WHERE%''
        )


--  If activated, the following filters out system-generated statements, should they occur, accessing
--  additional SQL Server internal tables that are not directly visible to or accessible by user processes
--  (even by administrators).  Enable each line, as needed, to add it to the filter.
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysschobjs'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysbinobjs'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysclsobjs'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysnsobjs'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''syscolpars'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''systypedsubobjs'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysidxstats'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysiscols'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysscalartypes'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysdbreg'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysxsrvs'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysrmtlgns'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''syslnklgns'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysxlgns'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysdbfiles'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysusermsg'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysprivs'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysowners'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysobjkeycrypts'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''syscerts'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysasymkeys'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''ftinds'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysxprops'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysallocunits'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysrowsets'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysrowsetrefs'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''syslogshippers'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysremsvcbinds'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysconvgroup'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysxmitqueue'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysdesend'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysdercv'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysendpts'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''syswebmethods'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysqnames'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysxmlcomponent'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysxmlfacet'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysxmlplacement'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''syssingleobjrefs'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysmultiobjrefs'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysobjvalues'')
--  AND NOT ([Schema_Name] = ''sys'' AND [Object_Name] = ''sysguidrefs'')
;';
				EXEC sp_executesql @SqlCmd;
				
			END -- check 2012 and later versions
		END -- check audit exists

		-- specify audit events
		PRINT '  Creating Server Audit Specification';
		IF NOT EXISTS(SELECT 1 FROM sys.server_audit_specifications WHERE [name] = @OrganisationName + N'_STANDARD_AUDIT_SPECS')
        BEGIN
			SET @SqlCmd = N'USE [master];
CREATE SERVER AUDIT SPECIFICATION [' + @OrganisationName + N'_STANDARD_AUDIT_SPECS]
	FOR SERVER AUDIT [' + @OrganisationName + N'_STANDARD_AUDIT]
	WITH (STATE = OFF);
';
			EXEC sp_executesql @SqlCmd;
			
			SET @SqlCmd = N'USE [master];
ALTER SERVER AUDIT SPECIFICATION [' + @OrganisationName + N'_STANDARD_AUDIT_SPECS]
	ADD (APPLICATION_ROLE_CHANGE_PASSWORD_GROUP), ' + 	-- Raised whenever a password is changed for an application role.
N'	ADD (AUDIT_CHANGE_GROUP), ' + 						-- Raised whenever any audit is created, modified or deleted.
N'	ADD (BACKUP_RESTORE_GROUP), ' + 					-- Raised whenever a backup or restore command is issued.
N'	ADD (DATABASE_CHANGE_GROUP), ' + 					-- Raised when a database is created, altered, or dropped.
--N'	ADD (DATABASE_OBJECT_ACCESS_GROUP), ' + 			-- Raised whenever database objects such as message type, assembly, contract are accessed. This could potentially lead to large audit records.
N'	ADD (DATABASE_OBJECT_CHANGE_GROUP), ' + 			-- Raised when a CREATE, ALTER, or DROP statement is executed on database objects, such as schemas.
N'	ADD (DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP), ' + 	-- Raised when a change of owner for objects within database scope.
N'	ADD (DATABASE_OBJECT_PERMISSION_CHANGE_GROUP), ' + 	-- Raised when a GRANT, REVOKE, or DENY has been issued for database objects, such as assemblies and schemas.
N'	ADD (DATABASE_OWNERSHIP_CHANGE_GROUP), ' + 			-- Raised when you use the ALTER AUTHORIZATION statement to change the owner of a database, and the permissions that are required to do that are checked.
N'	ADD (DATABASE_PERMISSION_CHANGE_GROUP), ' + 		-- Raised whenever a GRANT, REVOKE, or DENY is issued for a statement permission by any principal in SQL Server (This applies to database-only events, such as granting permissions on a database). 
N'	ADD (DATABASE_PRINCIPAL_CHANGE_GROUP), ' + 			-- Raised when principals, such as users, are created, altered, or dropped from a database.
N'	ADD (DATABASE_PRINCIPAL_IMPERSONATION_GROUP), ' + 	-- Raised when there is an impersonation operation in the database scope such as EXECUTE AS <principal> or SETPRINCIPAL.
N'	ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP), ' + 		-- Raised whenever a login is added to or removed from a database role.
N'	ADD (LOGIN_CHANGE_PASSWORD_GROUP), ' + 				-- Raised whenever a login password is changed by way of ALTER LOGIN statement or sp_password stored procedure.
--N'	ADD (SCHEMA_OBJECT_ACCESS_GROUP), ' + 				-- Raised whenever an object permission has been used in the schema. This could potentially lead to large audit records.
N'	ADD (SCHEMA_OBJECT_CHANGE_GROUP), ' + 				-- Raised when a CREATE, ALTER, or DROP operation is performed on a schema.
N'	ADD (SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP), ' + 	-- Raised when the permissions to change the owner of schema object (such as a table, procedure, or function) is checked. This occurs when the ALTER AUTHORIZATION statement is used to assign an owner to an object.
N'	ADD (SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP), ' + 	-- Raised whenever a grant, deny, revoke is performed against a schema object.
N'	ADD (SERVER_OBJECT_CHANGE_GROUP), ' + 				-- Raised for CREATE, ALTER, or DROP operations on server objects.
N'	ADD (SERVER_OBJECT_OWNERSHIP_CHANGE_GROUP), ' + 	-- Raised when the owner is changed for objects in server scope.
N'	ADD (SERVER_OBJECT_PERMISSION_CHANGE_GROUP), ' + 	-- Raised whenever a GRANT, REVOKE, or DENY is issued for a server object permission by any principal in SQL Server.
N'	ADD (SERVER_OPERATION_GROUP), ' + 					-- Raised when Security Audit operations such as altering settings, resources, external access, or authorization are used.
N'	ADD (SERVER_PERMISSION_CHANGE_GROUP), ' + 			-- Raised when a GRANT, REVOKE, or DENY is issued for permissions in the server scope, such as creating a login.
N'	ADD (SERVER_PRINCIPAL_CHANGE_GROUP), ' + 			-- Raised when server principals are created, altered, or dropped.
N'	ADD (SERVER_PRINCIPAL_IMPERSONATION_GROUP), ' + 	-- Raised when there is an impersonation within server scope, such as EXECUTE AS <login>.
N'	ADD (SERVER_ROLE_MEMBER_CHANGE_GROUP), ' + 			-- Raised whenever a login is added or removed from a fixed server role. Raised for the sp_addsrvrolemember and sp_dropsrvrolemember stored procedures.
N'	ADD (SERVER_STATE_CHANGE_GROUP), ' + 				-- Raised when the SQL Server service state is modified.
N'	ADD (TRACE_CHANGE_GROUP), ' + 						-- Raised for all statements that check for the ALTER TRACE permission.
N'	ADD (USER_CHANGE_PASSWORD_GROUP) ' + 				-- Raised whenever the password of a contained database user is changed by using the ALTER USER statement.
N';';
			EXEC sp_executesql @SqlCmd;
		END

		-- enable audit
		PRINT '  Enable Audit';
		IF (((SELECT TOP(1) 1 FROM sys.server_audit_specifications WHERE [name] = @OrganisationName + N'_STANDARD_AUDIT_SPECS') = 1) AND 
            ((SELECT TOP(1) 1 FROM sys.server_audit_specifications WHERE [name] = @OrganisationName + N'_STANDARD_AUDIT_SPECS' AND [is_state_enabled] = 0) = 1)
            )
		BEGIN
			SET @SqlCmd = N'USE [master];ALTER SERVER AUDIT SPECIFICATION [' + @OrganisationName + N'_STANDARD_AUDIT_SPECS] WITH (STATE = ON);';
			EXEC sp_executesql @SqlCmd;
		END
		
		IF (((SELECT 1 FROM sys.server_audits WHERE [name] = @OrganisationName + N'_STANDARD_AUDIT') = 1) AND 
            ((SELECT 1 FROM sys.server_audits WHERE [name] = @OrganisationName + N'_STANDARD_AUDIT' AND [is_state_enabled] = 0) = 1)
			)
		BEGIN
			SET @SqlCmd = N'USE [master];ALTER SERVER AUDIT [' + @OrganisationName + N'_STANDARD_AUDIT] WITH (STATE = ON);';
			EXEC sp_executesql @SqlCmd;
		END

	END -- check Engine Edition
END -- check whether to create audit
PRINT '';

/* ************************************************** */
-- 012_limit_sysadmins
PRINT 'Limit the number of members in the sysadmin fixed server role';
IF ((@ProductVersion LIKE '9.%') OR (@ProductVersion LIKE '10.%'))
BEGIN
	-- syntax for 2008 R2 and earlier versions
    IF ((@IsClustered = 0) AND (@IsHadrEnabled = 0)) -- only if not clustered - login is used as the Cluster Service start-up account
    BEGIN
	    PRINT '  Revoke membership to "NT AUTHORITY\SYSTEM"';
	    IF (((SELECT TOP(1) 1 FROM sys.server_principals WHERE [name] = 'NT AUTHORITY\SYSTEM') = 1) AND (IS_SRVROLEMEMBER('sysadmin', 'NT AUTHORITY\SYSTEM') = 1))
		    EXEC sp_dropsrvrolemember [NT AUTHORITY\SYSTEM], [sysadmin];
    END

	PRINT '  Revoke membership to "NT SERVICE\SQLWriter"';
	IF (((SELECT TOP(1) 1 FROM sys.server_principals WHERE [name] = 'NT SERVICE\SQLWriter') = 1) AND (IS_SRVROLEMEMBER('sysadmin', 'NT SERVICE\SQLWriter') = 1))
		EXEC sp_dropsrvrolemember [NT SERVICE\SQLWriter], [sysadmin];

	PRINT '  Revoke membership to "NT AUTHORITY\Winmgmt"';
	IF (((SELECT TOP(1) 1 FROM sys.server_principals WHERE [name] = 'NT AUTHORITY\Winmgmt') = 1) AND (IS_SRVROLEMEMBER('sysadmin', 'NT AUTHORITY\Winmgmt') = 1))
		EXEC sp_dropsrvrolemember [NT SERVICE\Winmgmt], [sysadmin];

	PRINT '  Disable these accounts'
	IF (@ProductVersion LIKE '10.%')
	BEGIN
        IF ((@IsClustered = 0) AND (@IsHadrEnabled = 0))-- only if not clustered - login is used as the Cluster Service start-up account
        BEGIN
            IF EXISTS(SELECT 1 FROM sys.server_principals WHERE [name] = 'NT AUTHORITY\SYSTEM')
		        ALTER LOGIN [NT AUTHORITY\SYSTEM] DISABLE;
        END
		IF EXISTS(SELECT 1 FROM sys.server_principals WHERE [name] = 'NT SERVICE\SQLWriter')
            ALTER LOGIN [NT SERVICE\SQLWriter] DISABLE
        IF EXISTS(SELECT 1 FROM sys.server_principals WHERE [name] = 'NT SERVICE\Winmgmt')
		    ALTER LOGIN [NT SERVICE\Winmgmt] DISABLE
	END
END
ELSE
BEGIN
	-- syntax for 2012 and later versions
	IF ((@IsClustered = 0) AND (@IsHadrEnabled = 0)) -- only if not clustered - login is used as the Cluster Service start-up account and by Always On Availability Groups
    BEGIN
        PRINT '  Revoke membership to "NT AUTHORITY\SYSTEM"';
	    IF (((SELECT TOP(1) 1 FROM sys.server_principals WHERE [name] = 'NT AUTHORITY\SYSTEM') = 1) AND (IS_SRVROLEMEMBER('sysadmin', 'NT AUTHORITY\SYSTEM') = 1))
		    EXEC sp_executesql N'USE [master];ALTER SERVER ROLE [sysadmin] DROP MEMBER [NT AUTHORITY\SYSTEM]';
    END

	PRINT '  Revoke membership to "NT SERVICE\SQLWriter"';
	IF (((SELECT TOP(1) 1 FROM sys.server_principals WHERE [name] = 'NT SERVICE\SQLWriter') = 1) AND (IS_SRVROLEMEMBER('sysadmin', 'NT SERVICE\SQLWriter') = 1))
		EXEC sp_executesql N'USE [master];ALTER SERVER ROLE [sysadmin] DROP MEMBER [NT SERVICE\SQLWriter]';

	PRINT '  Revoke membership to "NT AUTHORITY\Winmgmt"';
	IF (((SELECT TOP(1) 1 FROM sys.server_principals WHERE [name] = 'NT AUTHORITY\Winmgmt') = 1) AND (IS_SRVROLEMEMBER('sysadmin', 'NT AUTHORITY\Winmgmt') = 1))
		EXEC sp_executesql N'USE [master];ALTER SERVER ROLE [sysadmin] DROP MEMBER [NT SERVICE\Winmgmt]';

	PRINT '  Disable these accounts'
	IF ((@IsClustered = 0) AND (@IsHadrEnabled = 0)) -- only if not clustered - login is used as the Cluster Service start-up account and by Always On Availability Groups
    BEGIN
        IF EXISTS(SELECT 1 FROM sys.server_principals WHERE [name] = 'NT AUTHORITY\SYSTEM')
            ALTER LOGIN [NT AUTHORITY\SYSTEM] DISABLE;
    END
	IF EXISTS(SELECT 1 FROM sys.server_principals WHERE [name] = 'NT SERVICE\SQLWriter')
        ALTER LOGIN [NT SERVICE\SQLWriter] DISABLE
    IF EXISTS(SELECT 1 FROM sys.server_principals WHERE [name] = 'NT SERVICE\Winmgmt')
		ALTER LOGIN [NT SERVICE\Winmgmt] DISABLE
END
PRINT '';


/* ************************************************** */
-- 013_optimize_for_workloads
PRINT 'Enable the ''optimize for ad hoc workloads'' option';
IF EXISTS (SELECT 1 FROM sys.configurations WHERE [name] = 'optimize for ad hoc workloads' AND CAST([value] AS int) = 0)
BEGIN
	EXEC sys.sp_configure 'optimize for ad hoc workloads', 1;
	RECONFIGURE WITH OVERRIDE;
END
PRINT '';

/* ************************************************** */
-- 014_cost_threshold_for_parallelism
PRINT 'Enable the ''cost threshold for parallelism'' option';
IF EXISTS (SELECT 1 FROM sys.configurations WHERE [name] = 'cost threshold for parallelism' AND CAST([value] AS int) < 50)
BEGIN
	EXEC sys.sp_configure N'cost threshold for parallelism', N'50'
	RECONFIGURE WITH OVERRIDE;
END
PRINT '';

/* ************************************************** */
-- clean up
PRINT 'Clean up';
EXEC sys.sp_configure 'show advanced options', 0;
RECONFIGURE WITH OVERRIDE;

DROP TABLE #msver
DROP TABLE #fixeddrives;

PRINT '';

PRINT '--------------------------------------------------------------------------------';
PRINT 'END: Post-install configuration script';
PRINT '================================================================================'
