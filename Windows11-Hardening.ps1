# Windows 11 Security Hardening Script
# Author: Max Haase - maxhaase@gmail.com
# Description: Improves security of Windows 11 systems
# DISCLAIMER: Use at your own risk. Test thoroughly before deployment.
#             The author is not responsible for any issues caused by this script.

param(
    [switch]$Rollback,
    [string]$BackupPath = "C:\Windows\Temp\Windows11-Hardening-Backup"
)

# Make sure the script is run with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as an Administrator. Exiting."
    exit 1
}

# Rollback function
if ($Rollback) {
    Write-Host "Starting rollback process..." -ForegroundColor Yellow
    if (Test-Path "$BackupPath\rollback.ps1") {
        try {
            & "$BackupPath\rollback.ps1"
            Write-Host "Rollback completed successfully." -ForegroundColor Green
        } catch {
            Write-Error "Rollback failed: $_"
        }
    } else {
        Write-Error "No rollback script found at $BackupPath\rollback.ps1"
        Write-Host "Please run the hardening script first to create a backup." -ForegroundColor Yellow
    }
    exit
}

# Confirmation prompt
Write-Host "=== WINDOWS 11 SECURITY HARDENING SCRIPT ===" -ForegroundColor Red
Write-Host "This script will make significant changes to your system configuration." -ForegroundColor Yellow
Write-Host "A rollback script will be created at: $BackupPath" -ForegroundColor Cyan
Write-Host "`nWARNING: This may affect system functionality and application compatibility." -ForegroundColor Red
Write-Host "It is recommended to:" -ForegroundColor Yellow
Write-Host "1. Test this script in a non-production environment first" -ForegroundColor White
Write-Host "2. Ensure you have backups of important data" -ForegroundColor White
Write-Host "3. Understand the changes being made" -ForegroundColor White

$confirmation = Read-Host "`nType 'yes' to proceed with hardening, or anything else to cancel"
if ($confirmation -ne 'yes') {
    Write-Host "Operation cancelled by user." -ForegroundColor Yellow
    exit 0
}

# Create backup directory and initialize rollback script
Write-Host "`nCreating backup and rollback script..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null

$rollbackScript = @"
# Windows 11 Hardening Rollback Script
# Auto-generated on $(Get-Date)
# Use: .\Windows11-Hardening.ps1 -Rollback

Write-Host "Starting rollback process..." -ForegroundColor Yellow

"@

# Save original settings and build rollback commands
function Backup-RegistryValue {
    param($Path, $Name, $DefaultValue = $null)
    
    try {
        $currentValue = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        if ($currentValue -ne $null) {
            $value = $currentValue.$Name
            return "Set-ItemProperty -Path `"$Path`" -Name `"$Name`" -Value `"$value`" -ErrorAction SilentlyContinue"
        } else {
            return "Remove-ItemProperty -Path `"$Path`" -Name `"$Name`" -ErrorAction SilentlyContinue"
        }
    } catch {
        return "Remove-ItemProperty -Path `"$Path`" -Name `"$Name`" -ErrorAction SilentlyContinue"
    }
}

function Backup-ServiceState {
    param($ServiceName)
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service) {
            $startupType = (Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'").StartMode
            return "Set-Service -Name `"$ServiceName`" -StartupType `"$startupType`" -ErrorAction SilentlyContinue"
        }
    } catch {
        return "# Could not backup service: $ServiceName"
    }
}

# Start main hardening process
Write-Host "`nStarting Windows 11 Security Hardening..." -ForegroundColor Green
Write-Host "This may take several minutes. Please do not interrupt the process." -ForegroundColor Yellow

# Create restore point
try {
    Write-Host "Creating system restore point..." -ForegroundColor Cyan
    Checkpoint-Computer -Description "Pre-Windows11-Hardening" -RestorePointType "MODIFY_SETTINGS"
    $rollbackScript += "`n# System Restore Point - manually delete if needed"
} catch {
    Write-Warning "Could not create restore point. Continuing anyway..."
}

# Backup and disable Guest Account
try {
    Write-Host "Backing up and disabling Guest Account..." -ForegroundColor Cyan
    $guestState = (Get-LocalUser -Name "Guest" -ErrorAction SilentlyContinue).Enabled
    if ($guestState) {
        $rollbackScript += "`n# Guest Account`nSet-LocalUser -Name `"Guest`" -Enabled `$true -ErrorAction SilentlyContinue"
    }
    Set-LocalUser -Name "Guest" -Enabled $false -ErrorAction Stop
    Write-Host "Guest account disabled successfully." -ForegroundColor Green
} catch {
    Write-Warning "Failed to disable Guest account: $_"
}

# Backup and configure Password Policies
try {
    Write-Host "Backing up and configuring password policies..." -ForegroundColor Cyan
    
    # Backup current password policy
    $currentPolicy = net accounts
    $currentPolicy | Out-File -FilePath "$BackupPath\password_policy_backup.txt"
    
    $rollbackScript += @"

# Password Policies
`$backupPolicy = @`
$currentPolicy
`@
# Note: Manual restoration of password policies may be required
# Original settings saved to: $BackupPath\password_policy_backup.txt
"@

    # Set new policy
    net accounts /maxpwage:90 /minpwage:1 /minpwlen:14 /uniquepw:24
    Write-Host "Password policies configured successfully." -ForegroundColor Green
} catch {
    Write-Warning "Failed to configure password policies: $_"
}

# Backup and disable SMBv1
try {
    Write-Host "Backing up and disabling SMBv1..." -ForegroundColor Cyan
    $smbv1State = Get-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -ErrorAction SilentlyContinue
    if ($smbv1State.State -eq "Enabled") {
        $rollbackScript += "`n# SMBv1`nEnable-WindowsOptionalFeature -Online -FeatureName `"SMB1Protocol`" -NoRestart -ErrorAction SilentlyContinue"
    }
    
    Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -NoRestart -ErrorAction Stop
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -ErrorAction Stop
    Write-Host "SMBv1 disabled successfully." -ForegroundColor Green
} catch {
    Write-Warning "Failed to disable SMBv1: $_"
}

# Backup and configure Windows Firewall
try {
    Write-Host "Backing up and configuring Windows Firewall..." -ForegroundColor Cyan
    
    # Backup current firewall profiles
    $fwDomain = (Get-NetFirewallProfile -Profile Domain).Enabled
    $fwPrivate = (Get-NetFirewallProfile -Profile Private).Enabled
    $fwPublic = (Get-NetFirewallProfile -Profile Public).Enabled
    
    $rollbackScript += @"
`n# Windows Firewall
Set-NetFirewallProfile -Profile Domain -Enabled `$$fwDomain -ErrorAction SilentlyContinue
Set-NetFirewallProfile -Profile Private -Enabled `$$fwPrivate -ErrorAction SilentlyContinue
Set-NetFirewallProfile -Profile Public -Enabled `$$fwPublic -ErrorAction SilentlyContinue
"@

    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True -ErrorAction Stop
    Write-Host "Windows Firewall configured successfully." -ForegroundColor Green
} catch {
    Write-Warning "Failed to configure Windows Firewall: $_"
}

# Backup Windows Defender settings
try {
    Write-Host "Backing up Windows Defender settings..." -ForegroundColor Cyan
    $defenderSettings = Get-MpPreference
    $defenderSettings | ConvertTo-Json | Out-File -FilePath "$BackupPath\defender_settings_backup.json"
    
    $rollbackScript += @"
`n# Windows Defender
# Original settings saved to: $BackupPath\defender_settings_backup.json
# Manual restoration may be required for specific Defender settings
"@

    Write-Host "Configuring Windows Defender..." -ForegroundColor Cyan
    Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop
    Set-MpPreference -MAPSReporting 2 -ErrorAction Stop
    Set-MpPreference -PUAProtection 1 -ErrorAction Stop
    Write-Host "Windows Defender configured successfully." -ForegroundColor Green
} catch {
    Write-Warning "Failed to configure Windows Defender: $_"
}

# Backup and disable unnecessary services
try {
    Write-Host "Backing up and disabling unnecessary services..." -ForegroundColor Cyan
    $servicesToDisable = @(
        "XboxGipSvc", "XboxNetApiSvc", "DiagTrack", 
        "WMPNetworkSvc", "RemoteRegistry", "Fax"
    )
    
    $rollbackScript += "`n# Services"
    foreach ($service in $servicesToDisable) {
        if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
            $serviceBackup = Backup-ServiceState -ServiceName $service
            $rollbackScript += "`n$serviceBackup"
            
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "Disabled service: $service" -ForegroundColor Yellow
        }
    }
    Write-Host "Unnecessary services disabled." -ForegroundColor Green
} catch {
    Write-Warning "Failed to disable some services: $_"
}

# Backup and configure registry settings
try {
    Write-Host "Backing up and configuring registry settings..." -ForegroundColor Cyan
    
    $registrySettings = @(
        @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name="NoDriveTypeAutoRun"; Value=255},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"; Name="fDenyTSConnections"; Value=1},
        @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name="EnableLUA"; Value=1},
        @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name="ConsentPromptBehaviorAdmin"; Value=2},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"; Name="NoLMHash"; Value=1},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"; Name="LmCompatibilityLevel"; Value=5}
    )
    
    $rollbackScript += "`n`n# Registry Settings"
    foreach ($setting in $registrySettings) {
        $rollbackCmd = Backup-RegistryValue -Path $setting.Path -Name $setting.Name
        $rollbackScript += "`n$rollbackCmd"
        
        Set-ItemProperty -Path $setting.Path -Name $setting.Name -Value $setting.Value -ErrorAction SilentlyContinue
    }
    Write-Host "Registry settings configured." -ForegroundColor Green
} catch {
    Write-Warning "Failed to configure some registry settings: $_"
}

# Configure Account Lockout Policy
try {
    Write-Host "Configuring account lockout policy..." -ForegroundColor Cyan
    net accounts /lockoutthreshold:5 /lockoutduration:30 /lockoutwindow:30
    Write-Host "Account lockout policy configured (5 attempts, 30 minute lockout)." -ForegroundColor Green
} catch {
    Write-Warning "Failed to set account lockout policy: $_"
}

# Disable unnecessary scheduled tasks
try {
    Write-Host "Backing up and disabling unnecessary scheduled tasks..." -ForegroundColor Cyan
    $tasksToDisable = @(
        "\Microsoft\Windows\Customer Experience Improvement Program\",
        "\Microsoft\Windows\Diagnosis\Scheduled",
        "\Microsoft\Windows\Feedback\Siuf\DmClient"
    )
    
    $rollbackScript += "`n`n# Scheduled Tasks"
    foreach ($taskPath in $tasksToDisable) {
        Get-ScheduledTask | Where-Object {$_.TaskPath -like "$taskPath*"} | ForEach-Object {
            $task = $_
            if ($task.State -ne "Disabled") {
                $rollbackScript += "`nEnable-ScheduledTask -TaskName `"$($task.TaskName)`" -TaskPath `"$($task.TaskPath)`" -ErrorAction SilentlyContinue"
                Disable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction SilentlyContinue
                Write-Host "Disabled task: $($task.TaskPath)$($task.TaskName)" -ForegroundColor Yellow
            }
        }
    }
    Write-Host "Unnecessary scheduled tasks disabled." -ForegroundColor Green
} catch {
    Write-Warning "Failed to disable some scheduled tasks: $_"
}

# Save rollback script
$rollbackScript += "`n`nWrite-Host 'Rollback completed successfully.' -ForegroundColor Green"
$rollbackScript | Out-File -FilePath "$BackupPath\rollback.ps1" -Encoding UTF8

# Final Summary
Write-Host "`n`n=== WINDOWS 11 SECURITY HARDENING COMPLETE ===" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Yellow
Write-Host "Rollback script created at: $BackupPath\rollback.ps1" -ForegroundColor Cyan
Write-Host "`nTo rollback changes, run:" -ForegroundColor White
Write-Host ".\Windows11-Hardening.ps1 -Rollback" -ForegroundColor White
Write-Host "`nRecommended next steps:" -ForegroundColor Cyan
Write-Host "1. Reboot the system to apply all changes" -ForegroundColor White
Write-Host "2. Verify no critical functionality is affected" -ForegroundColor White
Write-Host "3. Check Windows Update for latest security patches" -ForegroundColor White
Write-Host "4. Test your essential applications" -ForegroundColor White

Write-Host "`nHardening script execution completed successfully!" -ForegroundColor Green
