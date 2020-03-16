# SQL Server Install Configuration
Generic configuration script applied post-installation of an SQL Server instance.

Change the variable values at the top of the script should suffice however it is suggested that the script is reviewed before applying to *any* environment.

Tested with Express, Developer, Standard and Enterprise Editions of SQL Server 2005, 2008, 2008 R2, 2014, 2016, 2017, 2019 (32-bit and 64-bit installations where applicable). Also tested with SQL Server 2017 and 2019 on Linux in Docker containers.

NOTE: Has not been tested with any Cloud implementation yet, but any feedback would be appreciated.

## What does it do?

The script modifies a number of configuration options according to insudtry best practices and/or standards. It should NOT be treated as a *one-script-fits-all* and each option change should be assessed for applicability in your environment. For example, for an SQL Server instance hosting Microsoft SharePoint or Microsoft Dynamics databases, the "NT AUTHORITY\SYSTEM" account should not be disabled.

Whatever the case, the script will cut down on the time to deliver an SQL Server environment, and also standardising the configuration according to a baseline. 

1. Configure SQL Server Memory options "min server memory (MB)" and "max server memory (MB)"
2. Set Login Auditing to capture "Failed Only"
3. Enable the "backup compression default" and "backup checksum default" options
4. Set Max Degree of Parallelism (MAXDOP) equal to the number of processors
5. Increase the number of ERRORLOG files (99), and set a maximum size (30MB) for automatic cycling
6. Create the DBAToolbox database (container for DBA functionality, etc.)
7. Create a Database Mail Profile and Account, and send a test email
8. Enable SQL Agent Alerting
9. Create a "DBA Operator" and set as the Failsafe
10. Create Alerts for:
    * Error 9100 - Index Corruption
    * Severity 14 - Login failed for user 'sa'
    * Severity 17 - Insufficient Resources
    * Severity 19 - Fatal Error in Resource
    * Severity 20 - Fatal Error in current process
    * Severity 21 - Fatal Error in Database Processes
    * Severity 22 - Fatal Error: Table integrity suspect
    * Severity 23 - Fatal Error: Database integrity suspect
    * Severity 24 - Fatal Error: Hardware error
    * Severity 25 - Fatal Error
11. Set the DBA Operator as Notifications recipient for the above Alerts
12. Rename and/or Disable the "sa" login (optional)
13. Reconfigure the TEMPDB database (NOTE: up to SQL Server 2014; later versions configure TEMPDB at installation stage)
14. Add SQL Server Auditing (for Developer, Enterprise and Standard Editions only) based on the following (optional):
    * APPLICATION_ROLE_CHANGE_PASSWORD_GROUP
    * AUDIT_CHANGE_GROUP
    * BACKUP_RESTORE_GROUP
    * DATABASE_CHANGE_GROUP
    * DATABASE_OBJECT_ACCESS_GROUP
    * DATABASE_OBJECT_CHANGE_GROUP
    * DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP
    * DATABASE_OBJECT_PERMISSION_CHANGE_GROUP
    * DATABASE_OWNERSHIP_CHANGE_GROUP
    * DATABASE_PERMISSION_CHANGE_GROUP
    * DATABASE_PRINCIPAL_CHANGE_GROUP
    * DATABASE_PRINCIPAL_IMPERSONATION_GROUP
    * DATABASE_ROLE_MEMBER_CHANGE_GROUP
    * LOGIN_CHANGE_PASSWORD_GROUP
    * SCHEMA_OBJECT_ACCESS_GROUP
    * SCHEMA_OBJECT_CHANGE_GROUP
    * SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP
    * SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP
    * SERVER_OBJECT_CHANGE_GROUP
    * SERVER_OBJECT_OWNERSHIP_CHANGE_GROUP
    * SERVER_OBJECT_PERMISSION_CHANGE_GROUP
    * SERVER_OPERATION_GROUP
    * SERVER_PERMISSION_CHANGE_GROUP
    * SERVER_PRINCIPAL_CHANGE_GROUP
    * SERVER_PRINCIPAL_IMPERSONATION_GROUP
    * SERVER_ROLE_MEMBER_CHANGE_GROUP
    * SERVER_STATE_CHANGE_GROUP
    * TRACE_CHANGE_GROUP
    * USER_CHANGE_PASSWORD_GROUP
15. Limit the number of members in the sysadmin fixed server role
16. Enable the "optimize for ad hoc workloads" option
17. Modify the "cost threshold for parallelism" option
18. Clean up
