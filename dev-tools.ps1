# Check if the script is already running with administrative privileges

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # If not, relaunch the script with administrator privileges
    Write-Host "Requesting administrative privileges..."
    $arguments = "& { Start-Process PowerShell -ArgumentList '-NoExit -Command ""& {$PSCommand}""' -Verb RunAs }"
    Start-Process PowerShell -ArgumentList $arguments
    exit
} else {
    # If running with administrative privileges, execute the command
    Write-Host "Running with administrative privileges."
    Write-Host "Setting Execution Policy to RemoteSigned for the current user..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    if ($?) {
        Write-Host "Successfully set Execution Policy to RemoteSigned for the current user."
    } else {
        Write-Warning "Failed to set Execution Policy. Check for errors."
    }
}


# Winget script to install common web development tools and configure UI settings

# Define the list of applications to install
$applications = @(
    "Google.Chrome"
    "Microsoft.VisualStudioCode"
    "Postman.Postman"
    "Microsoft.VisualStudio.2022.Community" # Or Professional/Enterprise
    "Microsoft.SQLServerManagementStudio"
    "Microsoft.SQLServer.2022.Express"          # Or other SQL Server editions
    "Microsoft.DotNet.SDK.7"                # Replace with desired .NET SDK version
    "OpenJS.NodeJS"                  # Installs the latest LTS version of Node.js
    "Notion.Notion"
    "ApacheFriends.Xampp.8.2"
    "Git.Git"
    "GitHub.cli"
    "GitHub.GitHubDesktop"
    "Python.Python.3.9"                    # Replace with desired Python version
    "Oracle.JDK.23"
    "Docker.DockerCLI"
    "Docker.DockerDesktop"
)

# Define the URL for Flow Launcher
$flowLauncherUrl = "https://github.com/Flow-Launcher/Flow.Launcher/releases/download/v1.19.5/Flow-Launcher-Setup.exe"
$flowLauncherInstaller = "Flow-Launcher-Setup.exe"

# Function to set the Windows theme to dark
function Set-DarkTheme {
    Write-Host "Setting Windows theme to Dark..."
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    Set-ItemProperty -Path $registryPath -Name AppsUseLightTheme -Value 0 -Force
    Set-ItemProperty -Path $registryPath -Name SystemUsesLightTheme -Value 0 -Force
    Write-Host "Dark theme set successfully."
}

# Function to hide the Search icon and box from the Taskbar
function Hide-TaskbarSearch {
    Write-Host "Hiding Taskbar Search..."
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
    Set-ItemProperty -Path $registryPath -Name SearchboxTaskbarMode -Value 0 -Force
    Write-Host "Taskbar Search hidden."
}

# Function to hide Widgets from the Taskbar
function Hide-Widgets {
    Write-Host "Hiding Widgets from Taskbar..."
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty -Path $registryPath -Name ShowWidgets -Value 0 -Force
    Write-Host "Widgets hidden."
}

# Function to hide Task View button from the Taskbar
function Hide-TaskView {
    Write-Host "Hiding Task View button from Taskbar..."
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty -Path $registryPath -Name ShowTaskViewButton -Value 0 -Force
    Write-Host "Task View button hidden."
}

# Function to enable auto-hide Taskbar
function Enable-AutoHideTaskbar {
    Write-Host "Enabling auto-hide Taskbar..."
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3"
    $valueName = "Settings"

    try {
        $settings = Get-ItemProperty -Path $registryPath -Name $valueName
        $binaryData = [byte[]]$settings.Settings

        # Modify the 8th byte (index 8) to enable auto-hide
        $binaryData[8] = $binaryData[8] -bor 0x01

        Set-ItemProperty -Path $registryPath -Name $valueName -Value ([byte[]]$binaryData) -Force
        Write-Host "Auto-hide Taskbar enabled. You might need to restart Explorer for it to take full effect."
    }
    catch {
        Write-Error "An error occurred while enabling auto-hide Taskbar: $($_.Exception.Message)"
        Write-Warning "Manual restart of Explorer (via Task Manager) might be needed."
    }
}

# Function to download and install an executable
function Install-Executable {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        [Parameter(Mandatory=$true)]
        [string]$InstallerName
    )
    Write-Host "Downloading $($InstallerName) from $($Url)..."
    try {
        Invoke-WebRequest -Uri $Url -OutFile $InstallerName
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$($InstallerName) downloaded successfully."
            Write-Host "Installing $($InstallerName)..."
            Start-Process -FilePath "./$InstallerName" -ArgumentList "/S" -Wait -PassThru | Out-Null # /S for silent install (if supported)
            if ($LASTEXITCODE -eq 0) {
                Write-Host "$($InstallerName) installed successfully."
            } else {
                Write-Warning "Installation of $($InstallerName) failed with exit code: $($LASTEXITCODE). Check if silent install is supported."
            }
            Remove-Item -Path "./$InstallerName" -Force
        } else {
            Write-Warning "Failed to download $($InstallerName). Exit code: $($LASTEXITCODE)"
        }
    }
    catch {
        Write-Error "An error occurred while downloading or installing $($InstallerName): $($_.Exception.Message)"
    }
}

# Loop through the applications and attempt to install them via Winget
foreach ($app in $applications) {
    Write-Host "Attempting to install $($app) using Winget..."
    try {
        winget install --id "$app" --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$($app) installed successfully via Winget."
        } else {
            Write-Warning "Failed to install $($app) via Winget. Exit code: $($LASTEXITCODE)"
        }
    }
    catch {
        Write-Error "An error occurred during the Winget installation of $($app): $($_.Exception.Message)"
    }
}

# Download and install Flow Launcher
Install-Executable -Url $flowLauncherUrl -InstallerName $flowLauncherInstaller

# Configure UI settings
Set-DarkTheme
Hide-TaskbarSearch
Hide-Widgets
Hide-TaskView
Enable-AutoHideTaskbar

Write-Host "Installation and UI configuration completed."
