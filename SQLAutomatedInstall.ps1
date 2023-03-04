
#$SQLInstallURI = "https://go.microsoft.com/fwlink/p/?linkid=2215158"
$SQLInstallURI = "https://go.microsoft.com/fwlink/?linkid=866662"
$WorkingDirectory = "C:\Projects\AutomatedSQLInstall\AutomatedSQLInstall"
$ExpectedMajorVersion = 15 ##SQL 2019
$InstallLogFileLocation = "C:\Program Files\Microsoft SQL Server\$($ExpectedMajorVersion)0\Setup Bootstrap\Log"


Try {
    $InstalledSQLInstances = Get-DefaultSQLInstance

    If ($InstalledSQLInstances.Version.Major -eq $ExpectedMajorVersion) {
        Write-Host "[INFO]: SQL Server is already at correct version. Exiting."

        return
    }
    ElseIf ($InstalledSQLInstances.Version.Major -gt $ExpectedMajorVersion) {
        Write-Host "[INFO]: Detected that you are on a higher version of SQL. Uninstall in Installed Apps and rerun this script to install the correct version"

    }
    Else {
    
        # Download SQL ISO
        #Invoke-SQLMediaDownload -WorkingDirectory $WorkingDirectory -SQLMajorVersion $ExpectedMajorVersion -SQLMajorURI $SQLInstallURI

        Write-Host "[INFO]: Mounting ISO File"
        $ISOFile = (Get-ChildItem -Path "$WorkingDirectory\Binaries" | Where-Object { $_.Extension -eq ".iso" } | Select-Object -First 1).FullName
        $ISOMountDiskLetter = (Mount-DiskImage -ImagePath $ISOFile -passthru | Get-Volume).DriveLetter

        If (!$InstalledSQLInstances) {
            Write-Host "[INFO]: No SQL Instance Detected. Installing..."

            Invoke-SQLAutomatedInstall -WorkingDirectory $WorkingDirectory -SQLMajorVersion $ExpectedMajorVersion -SQLInstallFile "$($ISOMountDiskLetter):\setup.exe"

            Write-Host "[INFO]: Dismounting ISO File"
            Dismount-DiskImage -ImagePath $ISOFile | Out-Null
        }
        ElseIf ($InstalledSQLInstances.Version.Major -lt $ExpectedMajorVersion) {
            Write-Host "[INFO]: Detected that you are on a lower version of SQL. Upgrading..."

            Invoke-SQLAutomatedUpgrade -WorkingDirectory $WorkingDirectory -SQLMajorVersion $ExpectedMajorVersion -SQLInstallFile "$($ISOMountDiskLetter):\setup.exe"

            Write-Host "[INFO]: Dismounting ISO File"
            Dismount-DiskImage -ImagePath $ISOFile | Out-Null
        }
   
    }

}
Catch {
    If (Test-Path $ISOMountDiskLetter) {
        Write-Host "[INFO]: Dismounting ISO File"
        Dismount-DiskImage -ImagePath $ISOFile | Out-Null

        Throw $_;
    }
}