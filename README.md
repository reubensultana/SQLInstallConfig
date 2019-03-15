# SQL Server Install Configuration
Generic configuration script applied post-installation of an SQL Server instance.

Change the variable values at the top of the script should suffice however it is suggested that the script is reviewed before applying to *any* environment.

Tested with Express, Developer, Standard and Enterprise Editions of SQL Server 2005, 2008, 2008 R2, 2014, and 2016 (32-bit and 64-bit installations).

NOTE: Has not been tested with any Cloud implementation yet, but any feedback would be appreciated.

## What does it do?

The script modifies a number of configuration options according to insudtry best practices and/or standards. It should not be trated as a *one-script-fits-all* and each option change should be assessed for applicability in your environment. For example, an SQL Server instance hosting SharePoint or Dynamics databases, the "NT AUTHORITY\SYSTEM" account must not be disabled.

Whatever the case, the script will cut down on the time to deliver an SQL Server environment, and also standardising the configuration according to a baseline. 

1. SQL Server Memory
2. Set Login Auditing
3. Compress Backups
4. Set Max Degree of Parallelism (MAXDOP)
5. Increase the number of ERRORLOG files, and set a maximum size for automatic cycling
6. Create a DBAToolbox database (container for DBA functionality, etc.)
7. Set up Database Mail
8. Set up SQL Agent Alerting
9. Enable Database Mail
10. Create DBA Operator and set as the Failsafe
11. Create Alerts for:
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
12.Set the DBA Operator as Notifications recipient for the above Alerts
13. Rename and/or Disable the 'sa' login
14. Reconfigure TEMPDB (NOTE: up to SQL Server 2014; later versions configure TEMPDB at installation stage)
15. Add SQL Server Auditing (for Developer, Enterprise and Standard Editions only)
16. Limit the number of members in the sysadmin fixed server role
17. Enable the ''optimize for ad hoc workloads'' option
18. Clean up
