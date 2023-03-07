powershell.exe -executionpolicy bypass -Command Start-Process PowerShell -ArgumentList '-File C:\Projects\AutomatedSQLInstall\AutomatedSQLInstall\Installation\SQLAutomatedInstall.ps1 -SQLInstallURI https://go.microsoft.com/fwlink/?linkid=866662 -SQLMajorVersion 15 -WorkingDirectory C:\Projects\AutomatedSQLInstall\AutomatedSQLInstall'  -Verb RunAs -Wait

pause
