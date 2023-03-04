Param(
    [Parameter(Mandatory = $true)]
    [String]$SQLInstallURI,
    [Parameter(Mandatory = $true)]
    [String]$ExpectedMajorVersion
)
$ErrorActionPreference = "Stop"
Import-Module .\SQLAutomatedInstall.psm1

$WorkingDirectory = "C:\Projects\AutomatedSQLInstall\AutomatedSQLInstall"
$InstallLogFileLocation = "C:\Program Files\Microsoft SQL Server\$($ExpectedMajorVersion)0\Setup Bootstrap\Log"


Try {
    $InstalledSQLInstances = Get-DefaultSQLInstance

    If ($InstalledSQLInstances.Version.Major -eq $ExpectedMajorVersion) {
        Write-Host "[INFO]: SQL Server is already at correct version. Exiting."
        Read-Host

        return
    }
    ElseIf ($InstalledSQLInstances.Version.Major -gt $ExpectedMajorVersion) {
        Write-Host "[INFO]: Detected that you are on a higher version of SQL. Uninstall in Installed Apps and rerun this script to install the correct version"
        Read-Host
    }
    Else {
    
        Write-Host "[INFO]: Downloading SQL Installation Files"
        $ExitCode = Invoke-SQLMediaDownload -WorkingDirectory $WorkingDirectory -SQLMajorVersion $ExpectedMajorVersion -SQLMajorURI $SQLInstallURI

        Write-Host "[INFO]: Mounting ISO File"
        $ISOFile = (Get-ChildItem -Path "$WorkingDirectory\Binaries" | Where-Object { $_.Extension -eq ".iso" } | Select-Object -First 1).FullName
        $ISOMountDiskLetter = (Mount-DiskImage -ImagePath $ISOFile -passthru | Get-Volume).DriveLetter

        If (!$InstalledSQLInstances) {
            Write-Host "[INFO]: No SQL Instance Detected. Installing..."

            $ExitCode = Invoke-SQLAutomatedInstall -WorkingDirectory $WorkingDirectory -SQLMajorVersion $ExpectedMajorVersion -SQLInstallFile "$($ISOMountDiskLetter):\setup.exe"

            Write-Host "[INFO]: Dismounting ISO File"
            Dismount-DiskImage -ImagePath $ISOFile | Out-Null

            Read-Host "[INFO]: Installation Successfull"
        }
        ElseIf ($InstalledSQLInstances.Version.Major -lt $ExpectedMajorVersion) {
            Write-Host "[INFO]: Detected that you are on a lower version of SQL. Upgrading..."

            $ExitCode = Invoke-SQLAutomatedUpgrade -WorkingDirectory $WorkingDirectory -SQLMajorVersion $ExpectedMajorVersion -SQLInstallFile "$($ISOMountDiskLetter):\setup.exe"

            Write-Host "[INFO]: Dismounting ISO File"
            Dismount-DiskImage -ImagePath $ISOFile | Out-Null
        }
   
    }
    Write-Host $ExitCode
Throw
    If ($ExitCode -ne 0) {

        Write-Error "[ERROR]: Exit code was non zero, investigate logs located $InstallLogFileLocation" -ErrorAction Stop
    }

}
Catch {
    If (Test-Path $ISOMountDiskLetter) {
        Write-Host "[INFO]: Dismounting ISO File"
        Dismount-DiskImage -ImagePath $ISOFile | Out-Null

        Throw $_;
    }
}