#!/bin/bash
#
# setuparr.sh - A script to manage and configure ARR tools and Tor with a kill-switch.
#
# DESCRIPTION
# -----------
# This script allows users to install, update, and manage ARR tools (Sonarr, Radarr, etc.),
# install Tor, and configure a kill-switch to prevent leaks.
#
# Version 0.1b -(c) 2024 by suuhmer
#

set -e

# Color Codes
BLUE='\033[0;34m'
GREEN='\033[0;32m[+] '
YELLOW='\033[0;33m'
RED='\033[0;31m[!] '
RESET='\033[0m'


display_banner() {
    echo -e "${BLUE}"
    echo "███████╗███████╗████████╗██╗   ██╗██████╗  █████╗ ██████╗ ██████╗ "
    echo "██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗"
    echo "███████╗█████╗     ██║   ██║   ██║██████╔╝███████║██████╔╝██████╔╝"
    echo "╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝ ██╔══██║██╔══██╗██╔══██╗"
    echo "███████║███████╗   ██║   ╚██████╔╝██║     ██║  ██║██║  ██║██║  ██║"
    echo "╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝"
    echo "=================================================================="
    echo -e "\n${YELLOW}\t\tSETUPARR v0.2.3  (c) 2024 by suuhmer          ${RESET}"
    echo "=================================================================="
}


main_menu() {
    while true; do
        #clear
        display_banner
        echo -e "${YELLOW}"
        echo "1) Install ARR Tools (Sonarr, Radarr, etc.)"
        echo "2) Install, Enable/Disable Tor Proxy /w Kill-Switch"
        echo "3) Update ARR Tools"
        echo "4) Check Tor IP Security"
        echo "5) Display System Information"
        echo "6) Restart ARR Services"
        echo "7) Quit"
        echo -e "${RESET}"
        read -rp "Choose an option [1-7]: " choice

        case $choice in
        1)
            ./lib_installarr.sh
            ;;
        2)
            ./lib_tor_proxy_ks.sh
            ;;
        3)
            update_arr_tools
            ;;
        4)
            clear; check_tor_ip
            ;;
        5)
            clear; display_system_info
            ;;
        6)
            clear; restart_services
            ;;
        7)
            echo -e "${GREEN}Exiting SetupARR. Goodbye!${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${RESET}"
            sleep 1
            ;;
        esac
    done
}

update_arr_tools() {
    echo -e "${YELLOW}Starting ARR Tools Update...${RESET}"
    ARR_TOOLS=("sonarr" "radarr" "prowlarr" "lidarr" "readarr")
    for TOOL in "${ARR_TOOLS[@]}"; do
        if systemctl is-active --quiet "$TOOL"; then
            echo -e "${GREEN}Updating $TOOL...${RESET}"
            sudo apt update && sudo apt install -y "$TOOL"
            sudo systemctl restart "$TOOL"
            echo -e "${GREEN}$TOOL successfully updated.${RESET}"
        else
            echo -e "${RED}$TOOL is not installed.${RESET}"
        fi
    done
    echo -e "${GREEN}All updates completed.${RESET}"
}

# Tor IP and perform a reverse DNS lookup
check_tor_ip() {
    echo -e "${YELLOW}Checking current Tor IP address...${RESET}"
    
    if command -v torify &> /dev/null && systemctl is-active --quiet tor; then
        echo -e "${GREEN}Using torify to fetch Tor IP...${RESET}"
        ip_address=$(torify curl -s https://check.torproject.org | grep -oP '(\d{1,3}\.){3}\d{1,3}' | sed ':a;N;$!ba;s/\n/, /g') 
        # Got the sed from Stackoverflow: 
        # (https://stackoverflow.com/questions/1251999/how-can-i-replace-each-newline-n-with-a-space-using-sed)
        # a create a label 'a'
		# N append the next line to the pattern space
		# $! if not the last line, ba branch (go to) label 'a'
		# s substitute, /\n/ regex for new line, / / by a space, /g global match (as many times as it can)
    elif command -v curl &> /dev/null && ! systemctl is-active --quiet tor; then
        echo -e "${YELLOW}Attempting to use curl without Tor proxy settings...${RESET}"
        ip_address=$(curl -s https://check.torproject.org | grep -oP '(\d{1,3}\.){3}\d{1,3}' | sed ':a;N;$!ba;s/\n/, /g')
    elif command -v curl &> /dev/null; then
        echo -e "${YELLOW}torify not found. Attempting to use curl with Tor proxy settings...${RESET}"
        ip_address=$(curl --socks5-hostname 127.0.0.1:9050 -s https://check.torproject.org | grep -oP '(\d{1,3}\.){3}\d{1,3}' | sed ':a;N;$!ba;s/\n/, /g')
    else
        echo -e "${RED}Curl is not available. Please install curl and ensure Tor is running.${RESET}"
        return
    fi

    # Output RL
    if [[ -n "$ip_address" ]]; then
        echo -e "${GREEN}Tor IP Address: ${ip_address}${RESET}"

        # reverse lookup for tor exitnodes..
        if command -v dig &> /dev/null; then
        	if systemctl is-active --quiet tor; then
        		domain_name=$(curl --socks5-hostname 127.0.0.1:9050 -sqk https://myip.is | sed -n 's/.*title="copy hostname">\(.*\)<\/a>.*/\1/p')
        	else
            	domain_name=$(dig +short -x "$ip_address")
            fi

            if [[ -n "$domain_name" ]]; then
                echo -e "\n${BLUE}[*] Associated Domain Name: ${domain_name}${RESET}\n"
            else
                echo -e "${YELLOW}No reverse DNS entry found for IP.${RESET}"
            fi
        else
            echo -e "${YELLOW}'dig' is not available. Install it to perform reverse DNS lookups.${RESET}"
        fi
    else
        echo -e "${RED}Failed to detect Tor IP.${RESET}"
    fi
}


# Display System Information
display_system_info() {
    echo -e "${YELLOW}Fetching system information...${RESET}"
    echo -e "${BLUE}System Info:${RESET}"
    echo "----------------------------------------------------"
    lsb_release -a || cat /etc/os-release
    echo "Kernel Version: $(uname -r)"
    echo "CPU Info: $(lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs)"
    echo "Memory Usage: $(free -h | awk '/Mem:/ {print $2}')"
    echo "Disk Usage:"
    df -h
    echo "----------------------------------------------------"
}

# Restart ARR Services
restart_services() {
    echo -e "${YELLOW}Attempting to restart ARR services...${RESET}"
    ARR_TOOLS=("sonarr" "radarr" "prowlarr" "lidarr" "readarr")
    for TOOL in "${ARR_TOOLS[@]}"; do
        if systemctl is-active --quiet "$TOOL"; then
            sudo systemctl restart "$TOOL"
            echo -e "${GREEN}$TOOL restarted successfully.${RESET}"
        else
            echo -e "${RED}$TOOL is not active or installed.${RESET}"
        fi
    done
}

main_menu
