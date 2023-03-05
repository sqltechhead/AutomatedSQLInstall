Param(
    [Parameter(Mandatory = $true)]
    [String]$SQLInstallURI,
    [Parameter(Mandatory = $true)]
    [String]$SQLMajorVersion,
    [Parameter(Mandatory = $true)]
    [String]$WorkingDirectory
)
$ErrorActionPreference = "Stop"
Import-Module .\SQLAutomatedInstall.psm1

Try {
    $InstalledSQLInstances = Get-DefaultSQLInstance

    If ($InstalledSQLInstances.Version.Major -eq $SQLMajorVersion) {
        Write-Host "[INFO]: SQL Server is already at correct version." -ForegroundColor Green
        Read-Host "Press any key to exit"

        return
    }
    ElseIf ($InstalledSQLInstances.Version.Major -gt $SQLMajorVersion) {
        Write-Host "[INFO]: Detected that you are on a higher version of SQL. Uninstall in Installed Apps and rerun this script to install the correct version" -ForegroundColor DarkYellow
        Read-Host "Press any key to exit"
    }
    Else {
    
        Write-Host "[INFO]: Downloading SQL Installation Files" -ForegroundColor Green
        Invoke-SQLMediaDownload -WorkingDirectory $WorkingDirectory -SQLMajorVersion $SQLMajorVersion -SQLMajorURI $SQLInstallURI

        Write-Host "[INFO]: Mounting ISO File" -ForegroundColor Green
        $ISOFile = (Get-ChildItem -Path "$WorkingDirectory\Binaries\$SQLMajorVersion" | Where-Object { $_.Extension -eq ".iso" } | Select-Object -First 1).FullName
        $ISOMountDiskLetter = (Mount-DiskImage -ImagePath $ISOFile -passthru | Get-Volume).DriveLetter

        If (!$InstalledSQLInstances) {
            Write-Host "[INFO]: No SQL Instance Detected. Installing..." -ForegroundColor Green

            Invoke-SQLAutomatedInstall -WorkingDirectory $WorkingDirectory -SQLMajorVersion $SQLMajorVersion -SQLInstallFile "$($ISOMountDiskLetter):\setup.exe"

            Write-Host "[INFO]: Dismounting ISO File" -ForegroundColor Green
            Dismount-DiskImage -ImagePath $ISOFile | Out-Null

            Read-Host "[INFO]: Installation Successfull" -ForegroundColor Green
        }
        ElseIf ($InstalledSQLInstances.Version.Major -lt $SQLMajorVersion) {
            Write-Host "[INFO]: Detected that you are on a lower version of SQL. Upgrading..." -ForegroundColor Green

            Invoke-SQLAutomatedUpgrade -WorkingDirectory $WorkingDirectory -SQLMajorVersion $SQLMajorVersion -SQLInstallFile "$($ISOMountDiskLetter):\setup.exe"

            Write-Host "[INFO]: Dismounting ISO File" -ForegroundColor Green
            Dismount-DiskImage -ImagePath $ISOFile | Out-Null
        }
   
    }

}
Catch {
    If ($ISOMountDiskLetter) {
        If (Test-Path $ISOMountDiskLetter) {
            Write-Host "[INFO]: Dismounting ISO File" -ForegroundColor Green
            Dismount-DiskImage -ImagePath $ISOFile | Out-Null

            Throw $_;
        }
    }
}