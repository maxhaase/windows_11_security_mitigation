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

## 📋 Prerequisites

- Windows 11 operating system
- PowerShell 5.1 or later
- **Administrative privileges**
- Execution policy allowing script execution

## 🚀 Installation & Usage

### Method 1: Direct Execution
1. Download the `Windows11-Hardening.ps1` script
2. Open PowerShell as Administrator
3. Navigate to the script directory
4. Run:
   ```powershell
   .\Windows11-Hardening.ps1
