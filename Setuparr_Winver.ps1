<#
.SYNOPSIS
    Setuparr_Windows.ps1 - A script to manage and configure ARR tools and Tor with a kill-switch.
.DESCRIPTION
    This script allows users to install, update, and manage ARR tools (Sonarr, Radarr, etc.),
    install Tor, and configure a kill-switch to prevent leaks.
    Version 0.1b -(c) 2024 by suuhmer
#>


function Show-Banner {
    Write-Host "`n==================================================================`n" -ForegroundColor Cyan
    Write-Host "███████╗███████╗████████╗██╗   ██╗██████╗  █████╗ ██████╗ ██████╗ " -ForegroundColor Cyan
    Write-Host "██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗" -ForegroundColor Cyan
    Write-Host "███████╗█████╗     ██║   ██║   ██║██████╔╝███████║██████╔╝██████╔╝" -ForegroundColor Cyan
    Write-Host "╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝ ██╔══██║██╔══██╗██╔══██╗" -ForegroundColor Cyan
    Write-Host "███████║███████╗   ██║   ╚██████╔╝██║     ██║  ██║██║  ██║██║  ██║" -ForegroundColor Cyan
    Write-Host "╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝" -ForegroundColor Cyan
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host "           SETUPARR WINDOWS v0.1b  (c) 2024 by suuhmer            " -ForegroundColor Yellow
    Write-Host "==================================================================`n" -ForegroundColor Cyan
}


function Install-TorKillSwitch {
    $TOR_DIR="C:\Tor"

    Write-Host "Installing Tor with Kill-Switch..." -ForegroundColor Green
    
    if (!(Get-Command "tor" -ErrorAction SilentlyContinue) -and !(Test-Path "$TOR_DIR\tor\tor.exe")) {
        Write-Host "Downloading new Tor..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri 'https://archive.torproject.org/tor-package-archive/torbrowser/14.0.3/tor-expert-bundle-windows-i686-14.0.3.tar.gz' -OutFile "$env:Temp\tor.tar.gz"
        mkdir -Force "$TOR_DIR"
        tar -xzvf "$env:Temp\tor.tar.gz" -C "$TOR_DIR"
        Write-Host "Tor installed to $TOR_DIR" -ForegroundColor Green
    } else {
        Write-Host "Tor is already installed." -ForegroundColor Yellow
    }

    # Configure Kill-Switch
    Write-Host "Configuring Kill-Switch for Tor..." -ForegroundColor Cyan
    $firewallRules = Get-NetFirewallRule -DisplayName "Tor Kill-Switch" -ErrorAction SilentlyContinue
    if ($firewallRules) {
        Write-Host "Tor Kill-Switch is already configured. Do you want to reset it? (y/n)" -ForegroundColor Yellow
        $response = Read-Host
        if ($response -ne "y") {
            Write-Host "Skipping Kill-Switch configuration." -ForegroundColor Green
            return
        } else {
            Write-Host "Removing existing Kill-Switch..." -ForegroundColor Yellow
            Remove-NetFirewallRule -DisplayName "Tor Kill-Switch_PROG"
            Remove-NetFirewallRule -DisplayName "Tor Kill-Switch"
            Remove-NetFirewallRule -DisplayName "Block Non-Tor Traffic"
            return
        }
    }

    Start-Process -FilePath "$TOR_DIR\tor\tor.exe" -ArgumentList "-f $TOR_DIR\tor\torrc"

    Write-Host "Setting up Kill-Switch..." -ForegroundColor Cyan
    # Allow Tor (tor.exe) to use SOCKS5 port (9050)
    New-NetFirewallRule -DisplayName "Tor Kill-Switch" `
                        -Direction Outbound `
                        -Protocol TCP `
                        -LocalPort 9050 `
                        -Action Allow `
                        -Profile Any

    New-NetFirewallRule -DisplayName "Tor Kill-Switch_PROG" `
                        -Direction Outbound `
                        -Protocol TCP `
                        -Program $TOR_DIR\tor\tor.exe `
                        -Action Allow `
                        -Profile Any


    New-NetFirewallRule -DisplayName "Block Non-Tor Traffic" `
                        -Direction Outbound `
                        -Protocol TCP `
                        -RemotePort 1-8999, 9029,9049, 9052-40000 `
                        -Action Block `
                        -Profile Any



    Write-Host "Kill-Switch configured successfully!" -ForegroundColor Green
}


function Install-ARRTools {
    param (
        [string[]]$Tools
    )

    foreach ($Tool in $Tools) {
        switch ($Tool.ToLower()) {
            "sonarr" {
                Write-Host "Installing Sonarr..." -ForegroundColor Green
                Invoke-WebRequest -Uri "https://github.com/SonarrPVR/Sonarr/releases/download/4.0.11.2680/Sonarr.main.4.0.11.2680.win-x86-installer.exe" -OutFile "$env:Temp\Sonarr.exe"
                #Expand-Archive -Path "$env:Temp\Sonarr.zip" -DestinationPath "C:\Program Files\Sonarr"
                sleep 2
                & $env:Temp\Sonarr.exe
                Write-Host "Sonarr installed successfully." -ForegroundColor Green
            }
            "radarr" {
                Write-Host "Installing Radarr..." -ForegroundColor Green
                Invoke-WebRequest -Uri https://github.com/Radarr/Radarr/releases/download/v5.15.1.9463/Radarr.master.5.15.1.9463.windows-core-x86.zip -OutFile "$env:Temp\Radarr.zip"
                Expand-Archive -Path "$env:Temp\Radarr.zip" -DestinationPath "C:\Program Files\Radarr"
                sleep 2
                & "C:\Program Files\Radarr\Radarr\Radarr.Console.exe"
                Write-Host "Radarr installed successfully to C:\Program Files\Radarr." -ForegroundColor Green
            }
            "prowlarr" {
                Write-Host "Installing Prowlarr..." -ForegroundColor Green
                Invoke-WebRequest -Uri "https://github.com/Prowlarr/Prowlarr/releases/download/v1.27.0.4852/Prowlarr.master.1.27.0.4852.windows-core-x86-installer.exe" -OutFile "$env:Temp\Prowlarr.exe"
                & $env:Temp\Prowlarr.exe
                sleep 2
                Write-Host "Prowlarr installed successfully." -ForegroundColor Green
            }
            "readarr" {
                Write-Host "Installing Readarr..." -ForegroundColor Green
                Invoke-WebRequest -Uri "https://readarr.servarr.com/v1/update/develop/updatefile?os=windows&runtime=netcore&arch=x64" -OutFile "$env:Temp\Readarr.zip"
                Expand-Archive -Path "$env:Temp\Readarr.zip" -DestinationPath "C:\Program Files\Readarr"
                & "C:\Program Files\Readarr\Readarr\Readarr.Console.exe"
                sleep 3
                Write-Host "Readarr installed successfully to C:\Program Files\Readarr\Readarr." -ForegroundColor Green
            }
            default {
                Write-Host "Unknown tool: $Tool" -ForegroundColor Red
            }
        }
    }
}


function Update-ARRTools {
    Write-Host "Updating ARR tools..." -ForegroundColor Green
    Write-Host "For Windows, update ARR tools manually via their respective interfaces." -ForegroundColor Yellow
}

#
#PARAMS: Check-TorIP -UseTorify
#
function Check-TorIP {
    param (
        [switch]$UseTorify
    )

    Write-Host "`n[*] Checking current Tor IP address..." -ForegroundColor Yellow

    # Initialize variables
    $torIP = ""
    $domainName = ""

    # Check for Torify and system state
    if ($UseTorify -and (Get-Command "torify" -ErrorAction SilentlyContinue)) {
        Write-Host "Using torify to fetch Tor IP..." -ForegroundColor Green
        try {
            $torIP = torify curl -s https://check.torproject.org | Select-String -Pattern '(\d{1,3}\.){3}\d{1,3}' -AllMatches | ForEach-Object { $_.Matches.Value } -join ", "
        } catch {
            Write-Host "Error using torify: $_" -ForegroundColor Red
        }
    } elseif (Get-Command "curl.exe" -ErrorAction SilentlyContinue) {
        Write-Host "Attempting to use curl with Tor proxy settings..." -ForegroundColor Yellow
        try {
            # CURL BACKUP
            curl.exe --socks5-hostname 127.0.0.1:9050 -s https://myip.is | ForEach-Object {
                if ($_ -match 'ip address">(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})') {
                    $torIP = $matches[1]
                    #Write-Output "IP: $ip"
                }
                if ($_ -match 'hostname">([^<]+)') {
                    $domain = $matches[1]
                    #Write-Output "Domainname: $domain"
                }
            }

            #$torIP = curl.exe --socks5-hostname 127.0.0.1:9050 -s https://check.torproject.org | Select-String -Pattern '(\d{1,3}\.){3}\d{1,3}' -AllMatches #| ForEach-Object { $_.Matches.Value } -join ", "
        } catch {
            Write-Host "Error using curl: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Curl is not available. Please install curl and ensure Tor is running." -ForegroundColor Red
        return
    }

    # Output Tor IP
    if ($torIP) {
        Write-Host "`n[*] Tor IP Address: $torIP" -ForegroundColor Green

        # Perform reverse DNS lookup
        if (Get-Command "Resolve-DnsName" -ErrorAction SilentlyContinue) {
            Write-Host "`n[..] Performing reverse DNS lookup..." -ForegroundColor White
            try {
                $domainName = $domain 
                #Resolve-DnsName -Name $torIP -ErrorAction SilentlyContinue | Select-Object -ExpandProperty NameHost -First 1
            } catch {
                Write-Host "Error during reverse DNS lookup: $_" -ForegroundColor Yellow
            }
        } else {
            Write-Host "'Resolve-DnsName' is not available. Install DNS utilities to perform reverse DNS lookups." -ForegroundColor Yellow
        }

        if ($domainName) {
            Write-Host "[*] Associated Domain Name: $domainName`n" -ForegroundColor Cyan
        } else {
            Write-Host "No reverse DNS entry found for IP." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Failed to detect Tor IP." -ForegroundColor Red
    }
}


function Display-SystemInfo {
    Write-Host "Gathering system information..." -ForegroundColor Cyan

    try {
        $info = Get-ComputerInfo | Select-Object CsName, OsName, WindowsVersion, WindowsBuildLabEx
        if ($null -eq $info) {
            Write-Host "Failed to retrieve system information." -ForegroundColor Red
        } else {
            Write-Host "`nSystem Information:" -ForegroundColor Green
            Write-Host "-------------------" -ForegroundColor Cyan
            $info | Format-Table -AutoSize
        }
    } catch {
        Write-Host "An error occurred while fetching system information." -ForegroundColor Red
    }
}


function Restart-Services {
    Write-Host "Restarting ARR services..." -ForegroundColor Green
    $services = @("Sonarr", "Radarr", "Readarr")
    foreach ($service in $services) {
        if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
            Restart-Service -Name $service -Force
            Write-Host "$service restarted successfully." -ForegroundColor Green
        } else {
            Write-Host "$service is not installed or not running." -ForegroundColor Yellow
        }
    }
}


function Main-Menu {
    while ($true) {
        Show-Banner
        Write-Host "1. Install ARR Tools (Sonarr, Radarr, Readarr)" -ForegroundColor Cyan
        Write-Host "2. Install Tor with Kill-Switch" -ForegroundColor Cyan
        Write-Host "3. Update ARR Tools" -ForegroundColor Cyan
        Write-Host "4. Check Tor connectivity" -ForegroundColor Cyan
        Write-Host "5. Display System Information" -ForegroundColor Cyan
        Write-Host "6. Restart Services" -ForegroundColor Cyan
        Write-Host "7. Quit" -ForegroundColor Cyan
        $choice = Read-Host "Choose an option (1-6)"

        switch ($choice) {
            "1" {
                $tools = Read-Host "Enter tools to install (e.g., sonarr, radarr, prowlarr, readarr) separated by commas"
                $toolList = $tools -split ",\s*"
                Install-ARRTools -Tools $toolList
            }
            "2" {
                Install-TorKillSwitch
            }
            "3" {
                Update-ARRTools
            }
            "4" {
                Check-TorIP
            }
            "5" {
                Display-SystemInfo
            }
            "6" {
                Restart-Services
            }
            "7" {
                Write-Host "Exiting SetupARR. Goodbye!" -ForegroundColor Green
                exit
            }
            default {
                Write-Host "Invalid option. Please try again." -ForegroundColor Red
            }
        }
    }
}

Main-Menu
