<#
.SYNOPSIS
    Installs the Splunk Universal Forwarder on Windows using msiexec.exe.

.DESCRIPTION
    - Downloads or references the Splunk UF MSI.
    - Installs Splunk Universal Forwarder silently.
    - (Optional) Sets up basic forwarding configurations in outputs.conf.
    - (Optional) Demonstrates how to configure HEC-based forwarding vs. TCP-based forwarding.

.PARAMETER Token
    Your Splunk Cloud HTTP Event Collector (HEC) token.

.PARAMETER Url
    Your Splunk Cloud base URL (for example, https://prd-p-pgr0a.splunkcloud.com).

.PARAMETER LogsUrl
    Your Splunk Cloud HEC endpoint (for example, https://prd-p-pgr0a.splunkcloud.com:8088).

.EXAMPLE
    .\Install-SplunkUF.ps1 -Token "13004da6-..." -Url "https://prd-p-pgr0a.splunkcloud.com" -LogsUrl "https://prd-p-pgr0a.splunkcloud.com:8088"
#>

param(
    [string]$Token = "13004da6-afa7-4fd9-b233-f6f27bce830b",
    [string]$Url   = "https://prd-p-pgr0a.splunkcloud.com",
    [string]$LogsUrl = "https://prd-p-pgr0a.splunkcloud.com:8088"
)

###############################################################################
# 1. Define local variables
###############################################################################
# Change these as appropriate for your environment
$MsiPath        = "C:\Temp\splunkforwarder-9.x.x64.msi"  # Path to the UF MSI you downloaded
$InstallLogFile = "C:\Temp\splunkUFInstall.log"
$SplunkHome     = "C:\Program Files\SplunkUniversalForwarder"
# If your system is 32-bit or you installed to a custom path, adjust accordingly.

###############################################################################
# 2. (Optional) Download the UF MSI (if not already downloaded)
###############################################################################
# Example using Invoke-WebRequest if you needed to pull from a direct download URL:
# $downloadUrl = "https://download.splunk.com/products/universalforwarder/releases/9.x.x/windows/splunkforwarder-9.x.x-xxxxxx-x64-release.msi"
# Write-Host "Downloading Splunk Universal Forwarder MSI..."
# Invoke-WebRequest -Uri $downloadUrl -OutFile $MsiPath

###############################################################################
# 3. Install the Universal Forwarder using msiexec
###############################################################################
Write-Host "Installing Splunk Universal Forwarder silently..."

# Here we do a silent install, agree to the license, and do NOT define special
# user credentials (so Splunk runs as Local System). Adjust flags as needed:
#   - If you want an admin username/password for the UF itself, add:
#       SPLUNKUSERNAME=<user> SPLUNKPASSWORD=<password>
#   - If you want the forwarder to run as a domain account, add:
#       LOGON_USERNAME="DOMAIN\username" LOGON_PASSWORD="secret" 
#   - If you want to define a receiving indexer or deployment server directly, 
#     add, for example: RECEIVING_INDEXER="myIndexer:9997" or DEPLOYMENT_SERVER="myDS:8089"
#
# For complete flags reference, see:
#   https://docs.splunk.com/Documentation/Forwarder/latest/Forwarder/Installanuniversalforwarderfromthecommandline

$arguments = @(
    "/i `"$MsiPath`"",            # /i = install
    "AGREETOLICENSE=Yes",         # Accept license
    "/quiet",                     # Silent mode
    "/L*v `"$InstallLogFile`""    # Log everything to this file
)

Start-Process "msiexec.exe" -Wait -ArgumentList $arguments
Write-Host "`n----- Splunk UF Installation Complete -----`n"

###############################################################################
# 4. (Optional) Create or modify outputs.conf for HEC or standard TCP forwarding
###############################################################################
# By default, Splunk forwards over TCP (9997) to Splunk Enterprise or Splunk Cloud.
# You gave a token (HEC) and LogsUrl(8088), which suggests you might want to forward
# data via HTTP Event Collector. This is less common for a universal forwarder, but
# here's an example of how it could be done.

#    A) For typical Splunk Cloud forwarding (TCP:9997) via outputs.conf:
#       (Requires your Splunk Cloud’s forwarder ingestion endpoint—something like "input-prd-p-pgr0a.cloud.splunk.com:9997")
#
#    B) For HEC-based forwarding, you’d set up an httpout stanza in outputs.conf,
#       as shown below. The universal forwarder can forward via HEC, but it’s more
#       typical to use the built-in forwarder-to-indexer approach. If you truly need
#       HEC, see Splunk Docs for "Configure forwarders with httpout" references.
#

# Path to the local Splunk config directory
$LocalConfigPath = Join-Path $SplunkHome "etc\system\local"
if (-Not (Test-Path $LocalConfigPath)) {
    Write-Warning "Splunk UF does not appear to be installed at $SplunkHome. Skipping config creation."
    return
}

# Example outputs.conf content for HEC-based forwarding:
# (Uncomment to enable)
# $outputsConfContent = @"
# [httpout]
# defaultGroup=my_hec_group
#
# [httpout:my_hec_group]
# server=${LogsUrl}  ; # e.g. https://prd-p-pgr0a.splunkcloud.com:8088
# httpEventCollectorToken=${Token}
# skipCertificateValidation=true
#"@

# Example outputs.conf content for standard TCP forwarding to Splunk Cloud:
# (Replace <your-cloud-host>:9997 with your actual forwarder ingestion endpoint)
$outputsConfContent = @"
[tcpout]
defaultGroup = splunkcloud-group

[tcpout:splunkcloud-group]
server = prd-p-pgr0a.splunkcloud.com:9997
sslVerifyServerCert = true
# For real-world Splunk Cloud, you'll typically get the correct server name/port
# from your Splunk Cloud "Forwarder" credentials page.

[serverClass:default]
stateOnClient = enabled
"@

$outputsConf = Join-Path $LocalConfigPath "outputs.conf"

Write-Host "Configuring $outputsConf with sample forwarding configuration..."
try {
    # If an existing outputs.conf exists, back it up
    if (Test-Path $outputsConf) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupPath = "$outputsConf.$timestamp.bak"
        Copy-Item $outputsConf $backupPath -Force
        Write-Host "Existing outputs.conf backed up to: $backupPath"
    }
    
    # Write new config (or overwrite old)
    $outputsConfContent | Out-File -FilePath $outputsConf -Encoding UTF8
    Write-Host "`n----- Updated outputs.conf -----"
    Get-Content $outputsConf
}
catch {
    Write-Warning "Failed to write outputs.conf. Error: $_"
}

###############################################################################
# 5. Restart SplunkForwarder service to load new configuration
###############################################################################
Write-Host "`nRestarting SplunkForwarder service to apply changes..."
try {
    # Stop the service if it’s running
    if (Get-Service SplunkForwarder -ErrorAction SilentlyContinue) {
        Stop-Service SplunkForwarder -Force
        Start-Sleep -Seconds 3
        Start-Service SplunkForwarder
        Write-Host "SplunkForwarder service restarted successfully."
    }
    else {
        Write-Host "SplunkForwarder service not found; it may not have been installed correctly."
    }
}
catch {
    Write-Warning "Could not restart SplunkForwarder service. Error: $_"
}

Write-Host "`n===== Splunk Universal Forwarder installation and configuration is complete! ====="
Write-Host "Token (if using HEC): $Token"
Write-Host "Splunk Cloud URL:     $Url"
Write-Host "Logs URL (HEC):       $LogsUrl"
