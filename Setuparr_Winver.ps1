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
    Write-Host "Installing Tor with Kill-Switch..." -ForegroundColor Green
    
    if (!(Get-Command "tor" -ErrorAction SilentlyContinue)) {
        Write-Host "Downloading Tor..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri https://www.torproject.org/dist/torbrowser/12.0.1/tor-win32.zip -OutFile "$env:Temp\tor.zip"
        Expand-Archive -Path "$env:Temp\tor.zip" -DestinationPath "C:\Tor"
        Write-Host "Tor installed to C:\Tor" -ForegroundColor Green
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
            Remove-NetFirewallRule -DisplayName "Tor Kill-Switch"
        }
    }

    Write-Host "Setting up Kill-Switch..." -ForegroundColor Cyan
    New-NetFirewallRule -DisplayName "Tor Kill-Switch" `
                        -Direction Outbound `
                        -Protocol TCP `
                        -RemotePort 9050 `
                        -Action Allow `
                        -Profile Any

    New-NetFirewallRule -DisplayName "Block Non-Tor Traffic" `
                        -Direction Outbound `
                        -Protocol TCP `
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
                Invoke-WebRequest -Uri https://sonarr.tv/v3/branch/develop/windows -OutFile "$env:Temp\Sonarr.zip"
                Expand-Archive -Path "$env:Temp\Sonarr.zip" -DestinationPath "C:\Program Files\Sonarr"
                Write-Host "Sonarr installed successfully." -ForegroundColor Green
            }
            "radarr" {
                Write-Host "Installing Radarr..." -ForegroundColor Green
                Invoke-WebRequest -Uri https://radarr.video/v3/branch/develop/windows -OutFile "$env:Temp\Radarr.zip"
                Expand-Archive -Path "$env:Temp\Radarr.zip" -DestinationPath "C:\Program Files\Radarr"
                Write-Host "Radarr installed successfully." -ForegroundColor Green
            }
            "readarr" {
                Write-Host "Installing Readarr..." -ForegroundColor Green
                Invoke-WebRequest -Uri https://readarr.com/v3/branch/develop/windows -OutFile "$env:Temp\Readarr.zip"
                Expand-Archive -Path "$env:Temp\Readarr.zip" -DestinationPath "C:\Program Files\Readarr"
                Write-Host "Readarr installed successfully." -ForegroundColor Green
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

function Display-SystemInfo {
    Write-Host "Gathering system information..." -ForegroundColor Cyan

    try {
        $info = Get-ComputerInfo | Select-Object CsName, OsName, WindowsVersion, WindowsBuildLabEx
        if ($null -eq $info) {
            Write-Host "Failed to retrieve system information." -ForegroundColor Red
        } else {
            Write-Host "System Information:" -ForegroundColor Green
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
        Write-Host "4. Display System Information" -ForegroundColor Cyan
        Write-Host "5. Restart Services" -ForegroundColor Cyan
        Write-Host "6. Quit" -ForegroundColor Cyan
        $choice = Read-Host "Choose an option (1-6)"

        switch ($choice) {
            "1" {
                $tools = Read-Host "Enter tools to install (e.g., sonarr, radarr, readarr) separated by commas"
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
                Display-SystemInfo
            }
            "5" {
                Restart-Services
            }
            "6" {
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