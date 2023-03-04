If (!(Get-Module sqlserver -ListAvailable)) {
    Write-Host "[INFO]: Installing sqlserver"
    Install-Module -Name SQLServer -Scope CurrentUser -Force -AllowClobber
}

Import-Module sqlserver

Function Get-DefaultSQLInstance {
    [cmdletbinding()]
    param()

    $InstalledSQLInstances = Get-ChildItem -Path "SQLSERVER:\SQL\$env:COMPUTERNAME" | Where-Object { $_.Name -eq $env:COMPUTERNAME }

    return $InstalledSQLInstances

}

Function Invoke-SQLMediaDownload {
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

Function Invoke-SQLAutomatedInstall {
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
        "/QuietSimple",
        "/IAcceptSQLServerLicenseTerms",
        "SQLSYSADMINACCOUNTS=$env:UserDomain\$env:UserName"
        "/ConfigurationFile=$WorkingDirectory\ConfigurationFiles\SQLMajorVersion$($SQLMajorVersion)Install.ini")

    $ExitCode = Start-Process -Wait $SQLInstallFile -Passthru -ArgumentList $DownloadParams

    If ($ExitCode.ExitCode -ne 0) {

        Throw "[ERROR]: Exit code was non zero logs located $InstallLogFileLocation"
    }
}

Function Invoke-SQLAutomatedUpgrade {
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
    Write-Host $ExitCode.ExitCode
    Return $ExitCode.ExitCode
}
