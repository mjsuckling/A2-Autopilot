# A2 Autopilot OOBE Bootstrap
# Registers a new Windows device into the HG Group / Attach2 Autopilot tenant.
# No credentials or secrets are stored in this script.

$ErrorActionPreference = "Stop"

$TenantId = "ed373f7d-2faf-41ff-a881-d3388923e455"
$ExpectedAdmin = "mjs.admin@hggroupltd.com"
$ScriptName = "Get-WindowsAutopilotInfo"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Fail {
    param([string]$Message)
    Write-Host ""
    Write-Host "ERROR: $Message" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to close..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

try {
    Write-Host ""
    Write-Host "A2 Autopilot Registration" -ForegroundColor Green
    Write-Host "Tenant: $TenantId"
    Write-Host "Authenticate with: $ExpectedAdmin"
    Write-Host ""

    Write-Step "Checking internet connectivity"
    try {
        Invoke-WebRequest -UseBasicParsing -Uri "https://www.powershellgallery.com" -Method Head -TimeoutSec 20 | Out-Null
    }
    catch {
        Fail "Internet access check failed. Connect the device to Wi-Fi or Ethernet and try again."
    }

    Write-Step "Enabling TLS 1.2 for PowerShell Gallery"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Write-Step "Preparing PowerShell package provider"
    try {
        if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
        }
    }
    catch {
        Fail "Could not install or load the NuGet package provider. $($_.Exception.Message)"
    }

    Write-Step "Trusting PowerShell Gallery for this session"
    try {
        $repo = Get-PSRepository -Name PSGallery -ErrorAction Stop
        if ($repo.InstallationPolicy -ne "Trusted") {
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        }
    }
    catch {
        Fail "Could not access PowerShell Gallery configuration. $($_.Exception.Message)"
    }

    Write-Step "Installing latest Microsoft Autopilot registration script"
    try {
        Install-Script -Name $ScriptName -Force -Scope AllUsers
    }
    catch {
        Fail "Could not install $ScriptName from PowerShell Gallery. $($_.Exception.Message)"
    }

    $installed = Get-InstalledScript -Name $ScriptName -ErrorAction SilentlyContinue
    if ($installed) {
        Write-Host "Installed $ScriptName version $($installed.Version)" -ForegroundColor DarkGray
    }

    Write-Step "Starting online Autopilot registration"
    Write-Host "A Microsoft sign-in window or device login prompt will appear." -ForegroundColor Yellow
    Write-Host "Use: $ExpectedAdmin" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "The Microsoft script will upload the hardware hash, wait for import/profile assignment, and reboot when ready." -ForegroundColor DarkGray
    Write-Host ""

    # TenantId binds the registration flow to the intended tenant.
    # -Assign waits for Autopilot profile assignment.
    # -Reboot restarts the machine after successful registration/assignment.
    & Get-WindowsAutopilotInfo.ps1 -Online -TenantId $TenantId -Assign -Reboot

    # The Microsoft script should reboot before reaching this point.
    Write-Host ""
    Write-Host "Registration command completed without triggering an automatic reboot." -ForegroundColor Yellow
    Write-Host "Review the output above before restarting the device."
}
catch {
    Fail $_.Exception.Message
}
