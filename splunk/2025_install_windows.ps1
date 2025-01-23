
# Nate (Created Winter 2025)

<#
    .SYNOPSIS
        Installs the Splunk Universal Forwarder on Windows silently.

    .DESCRIPTION
        Downloads the specified Splunk Universal Forwarder MSI, then installs it
        with optional parameters for username, password, and event log monitoring.
        Optionally writes an outputs.conf to enable HEC forwarding using a token.

    .NOTES
        Run this script in a PowerShell console **as Administrator**.
        Adjust paths and credentials to match your environment.
#>

[CmdletBinding()]
param(
    [string]$SplunkMsiDownloadUrl = "https://download.splunk.com/products/universalforwarder/releases/9.4.0/windows/splunkforwarder-9.4.0-6b4ebe426ca6-windows-x64.msi",
    [string]$SplunkMsiPath        = "$env:TEMP\splunkforwarder-9.4.0-x64-release.msi",
    [string]$SplunkAdminUser      = "sc_admin",
    [string]$SplunkAdminPassword  = "nixceh-Tacper-3poqro",
    [string]$InstallDir           = "C:\Program Files\SplunkUniversalForwarder",
    
    # Adjust these if you want Splunk-to-Splunk (S2S) forwarding directly to Splunk Cloud
    [string]$ReceivingIndexer     = "prd-p-pgr0a.splunkcloud.com:9997",
    
    # If you prefer HEC-based forwarding instead, fill in these:
    [string]$HecToken             = "13004da6-afa7-4fd9-b233-f6f27bce830b",
    [string]$HecUrl               = "https://prd-p-pgr0a.splunkcloud.com:8088",

    # Toggle whether you want to enable Windows Security/System logs via MSI flags
    [switch]$EnableWinEventLogs
)

Write-Host "=== Downloading Splunk Universal Forwarder MSI ==="
Write-Host "From: $SplunkMsiDownloadUrl"
Write-Host "To:   $SplunkMsiPath"
try {
    Invoke-WebRequest -Uri $SplunkMsiDownloadUrl -OutFile $SplunkMsiPath -UseBasicParsing
}
catch {
    Write-Error "Failed to download the Splunk UF MSI. $_"
    exit 1
}

# Construct our MSI install arguments
# These are the basic flags; you can add or remove based on your needs.
# More flags documented at:
#   https://docs.splunk.com/Documentation/Forwarder/latest/Forwarder/InstallaWindowsuniversalforwarderfromthecommandline

$msiArgs = @(
    "/i `"$SplunkMsiPath`""                       # Path to the downloaded MSI
    "INSTALLDIR=`"$InstallDir`""                  # Where to install Splunk UF
    "AGREETOLICENSE=Yes"                          # Required for silent install
    "SPLUNKUSERNAME=$SplunkAdminUser"             # Initial admin user (UF local GUI/CLI)
    "SPLUNKPASSWORD=$SplunkAdminPassword"         # Initial password
    
    # If you want to forward directly to Splunk Cloud on port 9997:
    "RECEIVING_INDEXER=`"$ReceivingIndexer`""     

    # Optionally enable Windows Event logs at install time
    # (If $EnableWinEventLogs is set, we enable Security & System logs as an example)
    $(if ($EnableWinEventLogs) {"WINEVENTLOG_SEC_ENABLE=1"; "WINEVENTLOG_SYS_ENABLE=1"})

    # Run silently with no UI
    "/quiet"
)

Write-Host "=== Installing Splunk Universal Forwarder Silently ==="
Write-Host "Running: msiexec.exe $($msiArgs -join ' ')"
try {
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        Write-Error "Splunk UF installation failed with exit code $($process.ExitCode)"
        exit $process.ExitCode
    }
}
catch {
    Write-Error "Failed to start msiexec.exe for Splunk UF installation. $_"
    exit 1
}

Write-Host "`n=== Splunk Universal Forwarder Installed Successfully ==="
Write-Host "Install path: $InstallDir"

# --------------------------------------------------------------------------
# OPTIONAL STEP: Configure HTTP Event Collector (HEC) forwarding
# Note: This is *not* the typical method for a universal forwarder, because
#       forwarders usually send data via Splunk-to-Splunk (S2S) on port 9997.
#       However, if you do need HEC-based forwarding, you can drop an outputs.conf
#       that points to your Splunk Cloud HEC endpoint and references your token.
# --------------------------------------------------------------------------
$UseHec = $true  # <-- Toggle this if you actually want to use HEC forwarding
if ($UseHec) {
    Write-Host "`n=== Writing outputs.conf for HEC Forwarding ==="
    $OutputsConfPath = Join-Path -Path $InstallDir -ChildPath "etc\system\local\outputs.conf"
    
    # Basic example of an outputs.conf for HEC. Adjust as necessary.
    # This config:

    #   [httpout]
    #   disabled = 0
    #   httpEventCollectorToken = <token>

    #   [httpout:my_hec_target]
    #   server = <URL or Host>:<Port>
    #   useSSL = true

    $outputsConfContent = @"
[httpout]
disabled = 0
httpEventCollectorToken = $HecToken

[httpout:my_hec_target]
server = $HecUrl
useSSL = true
"@
    try {
        $outputsConfContent | Out-File -FilePath $OutputsConfPath -Encoding UTF8
        Write-Host "Created/updated $OutputsConfPath with HEC settings."
    }
    catch {
        Write-Error "Failed to write to $OutputsConfPath. $_"
    }

    # Restart the UF so the new config takes effect
    $splunkBin = Join-Path -Path $InstallDir -ChildPath "bin\splunk.exe"
    if (Test-Path $splunkBin) {
        Write-Host "`n=== Restarting the Splunk Universal Forwarder to load HEC config ==="
        & "$splunkBin" stop
        & "$splunkBin" start
        Write-Host "Splunk UF restarted."
    }
    else {
        Write-Error "Could not find Splunk executable at $splunkBin"
    }
}
else {
    Write-Host "`nNo HEC forwarding configured (using Splunk-to-Splunk or no forwarding)."
}

Write-Host "`n=== Done! ==="
