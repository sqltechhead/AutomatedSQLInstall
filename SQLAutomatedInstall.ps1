If (!(Get-Module sqlserver -ListAvailable)) {
    Write-Host "[INFO]: Installing sqlserver"
    Install-Module -Name SQLServer -Scope CurrentUser -Force -AllowClobber
}

Import-Module sqlserver
Import-Module SQLPS

Function Get-InstalledSQLInstances {
    [cmdletbinding()]
    param()

    $InstalledSQLInstances = Get-ChildItem -Path "SQLSERVER:\SQL\$env:COMPUTERNAME" | Where-Object { $_.Name -eq $env:COMPUTERNAME }

    return $InstalledSQLInstances

}

Function Invoke-SQLMediaDownload{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True )]
        [ValidateNotNullOrEmpty()]
        [String]$WorkingDirectory,
        [Parameter(Mandatory = $True )]
        [ValidateNotNullOrEmpty()]
        [Int]$SQLMajorVersion,
        [Parameter(Mandatory = $True )]
        [ValidateNotNullOrEmpty()]
        [String]$SQLMajorURI
    )

    $SQLInstallFile = "$WorkingDirectory\Binaries\SQLDeveloper_MajorVersion_$($SQLMajorVersion).exe"
    If (!(Test-Path $SQLInstallFile)) {
        Write-Host "[INFO]: Downloading SQL Executable"
        Invoke-Webrequest -Uri $SQLMajorURI -OutFile $SQLInstallFile -Verbose
    }
    Else {
        Write-Host "[INFO]: SQL Executable already exists. Continuing."
    }
    
    [Array]$DownloadParams = @(
        "/Action=Download",
        "/MEDIAPATH=$WorkingDirectory\Binaries",
        "/Quiet",
        "/MediaType=ISO")

    $ExitCode = Start-Process -Wait $SQLInstallFile -Passthru -ArgumentList $DownloadParams

    If ($ExitCode.ExitCode -ne 0) {

        Throw "[ERROR]: Exit code was non zero logs located $InstallLogFileLocation"
    }
}

Function Invoke-SQLAutomatedInstall{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True )]
        [ValidateNotNullOrEmpty()]
        [String]$WorkingDirectory,
        [Parameter(Mandatory = $True )]
        [ValidateNotNullOrEmpty()]
        [Int]$SQLMajorVersion,
        [Parameter(Mandatory = $True )]
        [ValidateNotNullOrEmpty()]
        [String]$SQLInstallFile

        
    )

    [Array]$DownloadParams = @(
        "/Action=Install",
        "/Quiet",
        "/IAcceptSQLServerLicenseTerms"
        "/ConfigurationFile=$WorkingDirectory\ConfigurationFiles\SQLMajorVersion$($SQLMajorVersion)Install.ini")

    $ExitCode = Start-Process -Wait $SQLInstallFile -Passthru -ArgumentList $DownloadParams

    If ($ExitCode.ExitCode -ne 0) {

        Throw "[ERROR]: Exit code was non zero logs located $InstallLogFileLocation"
    }
    E:\setup.exe /Action=Upgrade /Quiet /IAcceptSQLServerLicenseTerms /ConfigurationFile="C:\SQLInstall\UpgradeConfigurationFile.ini"
}

Function Invoke-SQLAutomatedUpgrade{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True )]
        [ValidateNotNullOrEmpty()]
        [String]$WorkingDirectory,
        [Parameter(Mandatory = $True )]
        [ValidateNotNullOrEmpty()]
        [Int]$SQLMajorVersion,
        [Parameter(Mandatory = $True )]
        [ValidateNotNullOrEmpty()]
        [String]$SQLInstallFile
    )

    [Array]$DownloadParams = @(
        "/Action=Upgrade",
        "/QuietSimple",
        "/IAcceptSQLServerLicenseTerms"
        "/ConfigurationFile=$WorkingDirectory\ConfigurationFiles\SQLMajorVersion$($SQLMajorVersion)Upgrade.ini")

    $ExitCode = Start-Process -Wait $SQLInstallFile -Passthru -ArgumentList $DownloadParams

    If ($ExitCode.ExitCode -ne 0) {

        Throw "[ERROR]: Exit code was non zero logs located $InstallLogFileLocation"
    }
}

$SQLInstallURI = "https://go.microsoft.com/fwlink/p/?linkid=2215158"
$WorkingDirectory = "C:\Projects\AutomatedSQLInstall\AutomatedSQLInstall"
$ExpectedMajorVersion = 16 ##SQL 2019
$InstallLogFileLocation = "C:\Program Files\Microsoft SQL Server\$($ExpectedMajorVersion)0\Setup Bootstrap\Log"

$InstalledSQLInstances = Get-InstalledSQLInstances

If ($InstalledSQLInstances.Version.Major -eq $ExpectedMajorVersion) {
    Write-Host "[INFO]: SQL Server is already at correct version. Exiting."

    return
}
Else
{
    # Download SQL ISO
    Invoke-SQLMediaDownload -WorkingDirectory $WorkingDirectory -SQLMajorVersion $ExpectedMajorVersion -SQLMajorURI $SQLInstallURI

    $ISOFile = (Get-ChildItem -Path "$WorkingDirectory\Binaries" | Where-Object {$_.Extension -eq ".iso"} | Select-Object -First 1).FullName
    $ISOMountDiskLetter = (Mount-DiskImage -ImagePath $ISOFile -passthru | Get-Volume).DriveLetter

    If (!$SQLInstance) {
        Write-Host "[INFO]: No SQL Instance Detected. Installing..."

        Invoke-SQLAutomatedInstall -WorkingDirectory $WorkingDirectory -SQLMajorVersion $ExpectedMajorVersion -SQLInstallFile "$($ISOMountDiskLetter):\setup.exe"
    }
    ElseIf ($SQLInstance.Version.Major -lt $ExpectedMajorVersion) {
        Write-Host "[INFO]: Detected that you are on a lower version of SQL. Upgrading..."

        Invoke-SQLAutomatedUpgrade -WorkingDirectory $WorkingDirectory -SQLMajorVersion $ExpectedMajorVersion -SQLInstallFile "$($ISOMountDiskLetter):\setup.exe"
    }
   
}

