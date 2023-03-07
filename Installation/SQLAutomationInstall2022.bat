powershell.exe -executionpolicy bypass -Command Start-Process PowerShell -ArgumentList '-File C:\Projects\AutomatedSQLInstall\AutomatedSQLInstall\Installation\SQLAutomatedInstall.ps1 -SQLInstallURI https://go.microsoft.com/fwlink/p/?linkid=2215158 -SQLMajorVersion 16 -WorkingDirectory C:\Projects\AutomatedSQLInstall\AutomatedSQLInstall'  -Verb RunAs -Wait

pause
