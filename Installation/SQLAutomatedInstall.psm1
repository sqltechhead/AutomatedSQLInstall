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
    Try {

    
        $InstallLogFileLocation = "C:\Program Files\Microsoft SQL Server\$($SQLMajorVersion)0\Setup Bootstrap\Log"
        $SQLInstallFile = "$($WorkingDirectory)\Binaries\$($SQLMajorVersion)\SQLDeveloper_MajorVersion_$($SQLMajorVersion).exe"

        If (!(Test-Path "$($WorkingDirectory)\Binaries\$($SQLMajorVersion)")) {
            New-Item -Path "$($WorkingDirectory)\Binaries\$($SQLMajorVersion)" -ItemType Directory | Out-Null
        }

        If (!(Test-Path $SQLInstallFile)) {
            Write-Host "[INFO]: Downloading SQL Executable"
            Invoke-Webrequest -Uri $SQLMajorURI -OutFile $SQLInstallFile -Verbose
        }
        Else {
            Write-Host "[INFO]: SQL Executable already exists. Continuing."
        }

        [Array]$DownloadParams = @(
            "/Action=Download",
            "/MEDIAPATH=$($WorkingDirectory)\Binaries\$($SQLMajorVersion)",
            "/Quiet",
            "/MediaType=ISO")

        $Response = Start-Process -Wait $SQLInstallFile -Passthru -ArgumentList $DownloadParams 2>&1

        ## If not 0 (successfull)
        If ($Response.ExitCode -ne 0) {
            Throw $_;
        }
    }
    Catch {
        Write-Error "[ERROR]: Exit code was non zero, investigate logs located $($InstallLogFileLocation)" 
        

        Throw $_;
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
    Try {

    
        $InstallLogFileLocation = "C:\Program Files\Microsoft SQL Server\$($SQLMajorVersion)0\Setup Bootstrap\Log"
        [Array]$DownloadParams = @(
            "/Action=Install",
            "/QuietSimple",
            "/IAcceptSQLServerLicenseTerms",
            "/SQLSYSADMINACCOUNTS=$env:UserDomain\$env:UserName"
            "/ConfigurationFile=$WorkingDirectory\ConfigurationFiles\SQLMajorVersion$($SQLMajorVersion)Install.ini")

        $Response = Start-Process -Wait $SQLInstallFile -Passthru -ArgumentList $DownloadParams 2>&1
        
        ## If not 0 (successfull) and not 3010 (Passed but reboot required)
        If (($Response.ExitCode -ne 0) -and ($Response.ExitCode -ne 3010)) {
            Throw $_;
        }
        ElseIf ($Response.ExitCode -eq 3010) {
            Write-Host "[INFO]: Restart is needed, ensure you restart your computer" -BackgroundColor DarkYellow
        }
    }
    Catch {
        Write-Error "[ERROR]: Exit code was non zero, investigate logs located $($InstallLogFileLocation)" 

        Throw $_;
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
    Try {
        $InstallLogFileLocation = "C:\Program Files\Microsoft SQL Server\$($SQLMajorVersion)0\Setup Bootstrap\Log"

        [Array]$DownloadParams = @(
            "/Action=Upgrade",
            "/QuietSimple",
            "/IAcceptSQLServerLicenseTerms"
            "/ConfigurationFile=$WorkingDirectory\ConfigurationFiles\SQLMajorVersion$($SQLMajorVersion)Upgrade.ini")

        $Response = Start-Process -Wait $SQLInstallFile -Passthru -ArgumentList $DownloadParams 2>&1

        ## If not 0 (successfull) and not 3010 (Passed but reboot required)
        If (($Response.ExitCode -ne 0) -and ($Response.ExitCode -ne 3010)) {
            Throw $_;
        }
        ElseIf ($Response.ExitCode -eq 3010) {
            Write-Host "[INFO]: Restart is needed, ensure you restart your computer" -BackgroundColor DarkYellow
        }

    }
    Catch {
        Write-Error "[ERROR]: Exit code was non zero, investigate logs located $($InstallLogFileLocation)" 

        Throw $_;
    }
}