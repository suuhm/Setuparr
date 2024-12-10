# Setuparr
Easy to use tool for manage and installing the arr stack like Sonarr, Radarr, Prowlarr, Readarr etc included a Tor with Killswitch function

`SetupARR` is a collection of Bash and Powershell scripts designed to simplify the installation and configuration of various media management tools like Sonarr, Radarr, and Readarr. It also includes functionality to install Tor with a kill switch for secure downloads.

### Linux OS Bash 
![grafik](https://github.com/user-attachments/assets/b9cf6d9a-4e1a-42c0-9907-e50558f140bf)

### Windows Powershell
![grafik](https://github.com/user-attachments/assets/325cb46f-06a5-43a8-9e1b-99871b5f4a58)

---

## Features

### Interactive Setup Menu
- **Install ARR Tools:** Install individual tools or all tools at once.
- **Install Tor with Kill-Switch:** Ensure secure and anonymous network traffic.
- **Update Tools:** Keep all installed tools up to date.
- **System Information:** Display detailed system information, including OS, CPU, memory, and disk usage.
- **Restart Services:** Restart any installed ARR tool services.
- **Quit:** Exit the setup script.

### Supported ARR Tools
- **Sonarr:** Manage TV show libraries.
- **Radarr:** Manage movie libraries.
- **Readarr:** Manage book libraries.
- **Lidarr:** Manage music libraries.
- **Prowlarr:** Centralized indexer manager.

---

## Prerequisites Linux
- **Operating Systems:** Debian, Ubuntu, or any generic Linux (not testet cause of beta!) distribution.
- **Dependencies:** 
  - `curl`
  - `wget`
  - `gnupg`
  - `software-properties-common`
  - `iptables` (for Tor kill switch)

## Prerequisites Windows
- **Operating Systems:** Windows 7,8,10,11.
- **Dependencies:** 
  - `Powershell >= 5.x`
  - `Admin rights`

---

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/setuparr.git
   cd setuparr && chmod +x *.sh
   ```
2. Now simply run the script on Linux:
   ```bash
   ./setuparr.sh
   ```
2. Now simply run the script on Windows:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\Setuparr_Winver.ps1
   ```

---

## For any questions write me an issue!

   
