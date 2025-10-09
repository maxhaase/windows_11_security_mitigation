# Windows 11 Security Hardening Script

A comprehensive PowerShell script designed to enhance the security of Windows 11 systems by applying industry-standard security configurations and best practices.

## 🛡️ Features

### Security Enhancements
- **Account Security**: Strong password policies, account lockout, Guest account disablement
- **Network Security**: Windows Firewall configuration, SMBv1 disablement
- **Malware Protection**: Windows Defender hardening with real-time protection
- **System Hardening**: UAC enforcement, unnecessary service disablement
- **Audit & Monitoring**: Comprehensive audit policy configuration
- **Data Protection**: BitLocker readiness checks

### Safety Features
- **Rollback Functionality**: Automatically creates a rollback script to revert changes
- **Backup Creation**: Backs up original settings before modification
- **User Confirmation**: Requires explicit confirmation before execution
- **Error Handling**: Continues execution even if some steps fail
- **System Restore Point**: Creates a restore point before making changes

### 📋 Prerequisites

- Windows 11 operating system
- PowerShell 5.1 or later
- **Administrative privileges**
- Execution policy allowing script execution

### 🚀 Installation & Usage

### Method 1: Direct Execution
1. Download the `Windows11-Hardening.ps1` script
2. Open PowerShell as Administrator
3. Navigate to the script directory
4. Run: ```powershell .\Windows11-Hardening.ps1```
5. Type yes when prompted to confirm

## Method 2: With Parameters
# Run hardening script
.\Windows11-Hardening.ps1

# Rollback changes
.\Windows11-Hardening.ps1 -Rollback

# Specify custom backup location
.\Windows11-Hardening.ps1 -BackupPath "D:\MyBackups"

## 🔧 What This Script Does
## Account Policies
 Sets minimum password length to 14 characters

 Enables password complexity requirements

Configures account lockout after 5 failed attempts

Disables Guest account

Removes auto-login credentials

## System Security
Enables and configures Windows Firewall

Disables SMBv1 protocol

Configures Windows Defender with maximum protection
 
Enables UAC with secure settings

Disables unnecessary services (Telemetry, Xbox, etc.)

## Audit & Monitoring
Enables comprehensive auditing for security events

Configures login/logoff auditing

Sets up policy change monitoring

## Additional Hardening
Disables AutoRun for all drives

Configures secure remote desktop settings

Hardens registry settings

Disables unnecessary scheduled tasks

### 📁 File Structure

  <img width="623" height="195" alt="image" src="https://github.com/user-attachments/assets/17bd75b1-2cec-4a77-8bd4-5cf0de6f46b7" />

## 🔄 Rollback Process
### The script automatically creates a rollback script that can revert most changes. To use it:

# Method 1: Use the main script with rollback parameter
.\Windows11-Hardening.ps1 -Rollback

# Method 2: Run the generated rollback script directly
.\C:\Windows\Temp\Windows11-Hardening-Backup\rollback.ps1

⚠️ Important Notes
Before Running
Test in non-production environment first

Ensure you have data backups

Verify application compatibility

Understand that some changes may affect system functionality

After Running
Reboot your system to apply all changes

Verify that essential applications work correctly

Check Windows Update for any pending updates

Monitor system logs for any issues

Limitations
Some enterprise features require Windows 11 Pro/Enterprise

BitLocker requires TPM and appropriate licensing

Some settings may be overridden by Group Policy in domain environments

### 🛠️ Troubleshooting

##  Common Issues

Script won't run:

Ensure PowerShell execution policy allows scripts

Run PowerShell as Administrator

Check that the script isn't blocked by Windows

Rollback doesn't work perfectly:

Some settings may require manual restoration

Check the backup files in the backup directory

Use System Restore if available

Applications stop working:

Check if specific services were disabled

Review the rollback script for service re-enablement commands

Some security settings may need adjustment for specific applications

### 📝 License
This project is provided as-is for educational and security improvement purposes. Users are responsible for testing and understanding the changes before deployment in their environments.

### 🤝 Contributing
Contributions, issues, and feature requests are welcome! Feel free to check the issues page.

### ⚠️ Disclaimer
This script makes significant changes to your system configuration. The author is not responsible for any issues caused by running this script. Always test in a non-production environment first and ensure you have proper backups.

Note: This script is designed for security-conscious environments and may need adjustment for specific use cases. Always review and understand the changes before implementation.
