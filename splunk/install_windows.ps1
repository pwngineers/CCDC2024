# Define variables
$SplunkUFVersion = "9.0.0"  # Specify the desired version
$SplunkUFBuild = "x64"      # Specify the build architecture (x64 or x86)
$SplunkUFURL = "https://download.splunk.com/products/universalforwarder/releases/$SplunkUFVersion/windows/splunkforwarder-$SplunkUFVersion-$SplunkUFBuild-release.msi"
$InstallerPath = "$env:TEMP\splunkforwarder-$SplunkUFVersion-$SplunkUFBuild-release.msi"
$InstallDir = "C:\Program Files\SplunkUniversalForwarder"
$SplunkToken = "13004da6-afa7-4fd9-b233-f6f27bce830b"
$SplunkHECURL = "https://prd-p-pgr0a.splunkcloud.com:8088"
$SplunkHECHost = "prd-p-pgr0a.splunkcloud.com"
$SplunkHECPort = "9997"  # Default receiving port for Splunk

# Download the Splunk Universal Forwarder installer
Write-Host "Downloading Splunk Universal Forwarder..."
Invoke-WebRequest -Uri $SplunkUFURL -OutFile $InstallerPath

# Install the Universal Forwarder
Write-Host "Installing Splunk Universal Forwarder..."
Start-Process msiexec.exe -ArgumentList "/i `"$InstallerPath`" AGREETOLICENSE=Yes INSTALLDIR=`"$InstallDir`" /quiet" -Wait

# Configure the Universal Forwarder to send data to Splunk Cloud
Write-Host "Configuring Splunk Universal Forwarder..."

# Create outputs.conf for forwarding data
$OutputsConfPath = Join-Path -Path $InstallDir -ChildPath "etc\system\local\outputs.conf"
$OutputsConfContent = @"
[tcpout]
defaultGroup = splunk-cloud

[tcpout:splunk-cloud]
server = $SplunkHECHost:$SplunkHECPort
token = $SplunkToken
"@
$OutputsConfContent | Out-File -FilePath $OutputsConfPath -Encoding ASCII

# Create inputs.conf to specify data inputs
$InputsConfPath = Join-Path -Path $InstallDir -ChildPath "etc\system\local\inputs.conf"
$InputsConfContent = @"
[default]
host = $env:COMPUTERNAME

[monitor://C:\Windows\System32\winevt\Logs\Security.evtx]
disabled = 0
index = main
sourcetype = WinEventLog:Security
"@
$InputsConfContent | Out-File -FilePath $InputsConfPath -Encoding ASCII

# Restart the Splunk Forwarder service to apply changes
Write-Host "Restarting Splunk Universal Forwarder service..."
Start-Process -FilePath "$InstallDir\bin\splunk.exe" -ArgumentList "restart" -Wait

Write-Host "Splunk Universal Forwarder installation and configuration completed."
