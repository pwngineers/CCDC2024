<#
.SYNOPSIS
    Installs and configures the Splunk Universal Forwarder on Windows.

.DESCRIPTION
    1. Downloads the specified Splunk Universal Forwarder MSI.
    2. Performs a silent install.
    3. Configures outputs.conf for HEC using the provided token and URL.
    4. (Optional) Configures basic inputs.conf to collect Windows event logs.
    5. Starts the SplunkForwarder service.

.NOTES
    Run as Administrator.

.PARAMETER SplunkUFVersion
    The version of the Universal Forwarder to install (e.g., 9.0.4.1).

.PARAMETER Token
    The HEC token used to authenticate data ingestion in Splunk Cloud.

.PARAMETER SplunkCloudUrl
    The main Splunk Cloud URL (for reference or if you need it in config).

.PARAMETER LogsUrl
    The HEC endpoint URL, typically <SplunkCloudUrl>:8088.
#>

param (
    [string]$SplunkUFVersion = "9.0.4.1",
    [string]$Token = "13004da6-afa7-4fd9-b233-f6f27bce830b",
    [string]$SplunkCloudUrl = "https://prd-p-pgr0a.splunkcloud.com",
    [string]$LogsUrl = "https://prd-p-pgr0a.splunkcloud.com:8088"
)

# --- 1. Check for Administrative Privileges ---
If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Error "You must run this script as an Administrator!"
    return
}

# --- 2. Define Download & Install Paths ---
$TempDir = "$env:TEMP\SplunkUFInstall"
if (!(Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir | Out-Null
}

# Construct the download URL for the Universal Forwarder MSI.
# Check Splunk download site for the specific architecture/versions you need:
# https://www.splunk.com/en_us/download/universal-forwarder.html
$UFFileName = "splunkuniversalforwarder-$SplunkUFVersion-x64-release.msi"
$UFDownloadUrl = "https://download.splunk.com/products/universalforwarder/releases/$SplunkUFVersion/windows/$UFFileName"
$LocalMsiPath = Join-Path $TempDir $UFFileName

Write-Host "Downloading Splunk Universal Forwarder MSI..."
Write-Host "URL: $UFDownloadUrl"
Try {
    Invoke-WebRequest -Uri $UFDownloadUrl -OutFile $LocalMsiPath -UseBasicParsing
    Write-Host "Download completed: $LocalMsiPath"
}
Catch {
    Write-Error "Failed to download Splunk Universal Forwarder. $($_.Exception.Message)"
    return
}

# --- 3. Silent Install of the Splunk Universal Forwarder ---
# Adjust additional properties as needed. For example:
#   - WINEVENTLOG_APP_ENABLE=1
#   - WINEVENTLOG_SEC_ENABLE=1
#   - WINEVENTLOG_SYS_ENABLE=1
#
# For details on msiexec forwarder parameters:
# https://docs.splunk.com/Documentation/Forwarder/latest/Forwarder/Installanixdfwd#Using_the_command_line
Write-Host "Installing Splunk Universal Forwarder (silent install)..."
$msiArguments = @(
    "/i `"$LocalMsiPath`"",
    "/qn",                        # Silent install (no UI)
    "AGREETOLICENSE=Yes",         # Accept EULA
    "LAUNCHSPLUNK=0",             # Don't launch automatically yet
    "INSTALL_SHORTCUT=0",         # No Start Menu shortcuts
    "NO_SERVICE_AUTO_START=1"     # Do not start as soon as install finishes
)

$process = Start-Process msiexec.exe -ArgumentList $msiArguments -Wait -PassThru
if ($process.ExitCode -ne 0) {
    Write-Error "Splunk UF MSI installation failed with exit code $($process.ExitCode)."
    return
}
Write-Host "Splunk Universal Forwarder installation completed."

# --- 4. Configure Splunk Forwarder to use HEC (Optional Approach) ---
# By default, Universal Forwarders typically send data using Splunk's proprietary
# forwarder protocol (TCP/9997). If you specifically want to use HEC, you can
# configure outputs.conf with httpout stanzas, as shown here.
#
# Alternatively, if you want to do standard forwarding to Splunk Cloud over 9997,
# refer to Splunk docs for "outputs.conf" configuration using [tcpout].
#
# This example sets up a minimal "outputs.conf" for HEC on Splunk Cloud.

$SplunkHome = "C:\Program Files\SplunkUniversalForwarder"  # Adjust if installed elsewhere
$SystemLocalDir = Join-Path $SplunkHome "etc\system\local"
if (!(Test-Path $SystemLocalDir)) {
    New-Item -ItemType Directory -Path $SystemLocalDir | Out-Null
}

$outputsConfPath = Join-Path $SystemLocalDir "outputs.conf"
Write-Host "Updating outputs.conf with HEC configuration..."

# If you already have other outputs in outputs.conf, you might want to append
# or merge them. For simplicity, we're overwriting with minimal content here.
@"
[httpout]
disabled = false

[httpout:SplunkCloud]
server = $($LogsUrl -replace "https?://","")
httpEventCollectorToken = $Token
"@ | Set-Content -Path $outputsConfPath -Force

Write-Host "outputs.conf updated."

# --- 5. (Optional) Configure inputs.conf to collect Windows Logs ---
# Below is a simple example that enables the collection of Application,
# Security, and System Event Logs. Adjust as needed for your environment.
$inputsConfPath = Join-Path $SystemLocalDir "inputs.conf"
Write-Host "Creating a basic inputs.conf for Windows Event Logs..."

@"
[WinEventLog://Application]
disabled = 0

[WinEventLog://Security]
disabled = 0

[WinEventLog://System]
disabled = 0
"@ | Set-Content -Path $inputsConfPath -Force

Write-Host "inputs.conf created."

# --- 6. Enable and Start the SplunkForwarder service ---
Write-Host "Starting SplunkForwarder service..."
Start-Service -Name "SplunkForwarder" -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5

# Verify service is running
$service = Get-Service -Name "SplunkForwarder" -ErrorAction SilentlyContinue
if ($service.Status -eq "Running") {
    Write-Host "SplunkForwarder service is running."
} else {
    Write-Warning "SplunkForwarder service could not be started. Check Splunk logs."
}

Write-Host "`nInstallation and configuration complete."
Write-Host "Splunk Universal Forwarder is installed and configured to send logs via HEC to:"
Write-Host "  URL:    $LogsUrl"
Write-Host "  Token:  $Token"
