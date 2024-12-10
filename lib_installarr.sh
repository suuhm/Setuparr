#!/bin/bash

set -e

ARR_TOOLS=("sonarr" "radarr" "prowlarr" "lidarr" "readarr")

BLUE='\033[0;34m[>] '
GREEN='\033[0;32m[>] '
YELLOW='\033[0;33m[*] '
RED='\033[0;31m[>] '
RESET='\033[0m'

# Old installer
install_tool() {
    local tool=$1
    echo -e "${GREEN}Installing ${tool}...${RESET}"
    case $tool in
        sonarr)
            echo -e "${YELLOW}Attempting to install Sonarr...${RESET}"
            curl -fsSL https://services.sonarr.tv/v1/develop/debian/ | sudo tee /etc/apt/sources.list.d/sonarr.list
            curl -fsSL https://services.sonarr.tv/sonarr.asc | sudo tee /etc/apt/trusted.gpg.d/sonarr.asc
            sudo apt update && sudo apt install -y sonarr || {
                echo -e "${RED}Sonarr repository failed. Downloading the latest .deb file...${RESET}"
                wget -q https://services.sonarr.tv/v1/develop/debian/sonarr-latest.deb -O sonarr.deb
                sudo apt install -y ./sonarr.deb
                rm -f sonarr.deb
            }
            sudo systemctl enable --now sonarr
            ;;
        radarr)
            echo -e "${YELLOW}Attempting to install Radarr...${RESET}"
            curl -fsSL https://apt.radarr.video/radarr.asc | sudo tee /etc/apt/trusted.gpg.d/radarr.asc
            echo "deb https://apt.radarr.video/develop focal main" | sudo tee /etc/apt/sources.list.d/radarr.list
            sudo apt update && sudo apt install -y radarr
            sudo systemctl enable --now radarr
            ;;
        prowlarr)
            echo -e "${YELLOW}Attempting to install Prowlarr...${RESET}"
            curl -fsSL https://apt.prowlarr.com/prowlarr.asc | sudo tee /etc/apt/trusted.gpg.d/prowlarr.asc
            echo "deb https://apt.prowlarr.com/develop focal main" | sudo tee /etc/apt/sources.list.d/prowlarr.list
            sudo apt update && sudo apt install -y prowlarr
            sudo systemctl enable --now prowlarr
            ;;
        lidarr)
            echo -e "${YELLOW}Attempting to install Lidarr...${RESET}"
            curl -fsSL https://apt.lidarr.video/lidarr.asc | sudo tee /etc/apt/trusted.gpg.d/lidarr.asc
            echo "deb https://apt.lidarr.video/develop focal main" | sudo tee /etc/apt/sources.list.d/lidarr.list
            sudo apt update && sudo apt install -y lidarr
            sudo systemctl enable --now lidarr
            ;;
        readarr)
            echo -e "${YELLOW}Attempting to install Readarr...${RESET}"
            curl -fsSL https://apt.readarr.com/readarr.asc | sudo tee /etc/apt/trusted.gpg.d/readarr.asc
            echo "deb https://apt.readarr.com/develop focal main" | sudo tee /etc/apt/sources.list.d/readarr.list
            sudo apt update && sudo apt install -y readarr
            sudo systemctl enable --now readarr
            ;;
        *)
            echo -e "${RED}Invalid choice: ${tool}${RESET}"
            ;;
    esac
}

update_and_prepare_system() {
    echo -e "${YELLOW}Preparing system and dependencies...${RESET}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl wget apt-transport-https software-properties-common gnupg
}

display_available_tools() {
    echo -e "${YELLOW}Available ARR Tools:${RESET}"
    for i in "${!ARR_TOOLS[@]}"; do
        echo -e "${BLUE}$((i + 1)). ${ARR_TOOLS[i]}${RESET}"
    done
}

install_sonarr() {
    echo -e "${YELLOW}Installing Sonarr...${RESET}"
    # Deprecated atm
    # wget -qO - https://apt.sonarr.tv/sonarr.asc | sudo tee /usr/share/keyrings/sonarr.asc
    # echo "deb [signed-by=/usr/share/keyrings/sonarr.asc] https://apt.sonarr.tv/debian buster main" | sudo tee /etc/apt/sources.list.d/sonarr.list
    # sudo apt update 
    sudo apt install -y sonarr || { 
        curl -o- https://raw.githubusercontent.com/Sonarr/Sonarr/develop/distribution/debian/install.sh | sudo bash
    }
    sudo systemctl enable --now sonarr
    echo -e "${GREEN}Sonarr installation complete.${RESET}"
}

# Install Radarr
install_radarr() {
    echo -e "${YELLOW}Installing Radarr on device...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/Servarr/Wiki/refs/heads/master/servarr/servarr-install-script.sh)
    #sudo systemctl enable --now radarr
    echo -e "${GREEN}Radarr installation complete.${RESET}"
}

# Install Servarr
install_readarr() {
    echo -e "${YELLOW}Installing Prowlarr, Lidarr or Readarr...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/Servarr/Wiki/refs/heads/master/servarr/servarr-install-script.sh)
    #sudo systemctl enable --now readarr
    echo -e "${GREEN}Readarr installation complete.${RESET}"
}

install_all() {
    echo -e "${YELLOW}Installing all tools (Sonarr, Radarr, Lidarr Prowlarr and Readarr)...${RESET}"
    install_sonarr
    install_radarr
    install_readarr
}

# Function to handle user selection
install_tool_menu() {
    local choice=$1
    case $choice in
        1)
            install_sonarr
            ;;
        2)
            install_radarr
            ;;
        3 | 4 | 5)
            install_readarr
            ;;
        6)
            install_all
            ;;
        *)
            echo -e "${RED}Invalid choice.${RESET}"
            ;;
    esac
}

main_menu() {
    while true; do
        clear
        echo -e "${YELLOW}ARR Installation Menu${RESET}\n"
        display_available_tools
        echo -e "${GREEN}6. Install All Tools${RESET}"
        echo -e "${GREEN}7. Update Package Systems${RESET}"
        echo -e "${RED}8. Quit${RESET}"
        read -rp "$(echo -e "\n${YELLOW}Choose an option: ${RESET}")" choice

        case $choice in
        1 | 2 | 3 | 4| 5)
            install_tool_menu "${choice}"
            ;;
        6)
            install_all
            ;;
        7)
            echo -e "${GREEN}Update system${RESET}"
            update_and_prepare_system && exit 0
            ;;
        8)
            echo -e "${GREEN}Exiting. Goodbye!${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${RESET}"
            ;;
        esac
        read -rp "$(echo -e "${YELLOW}Press Enter to return to menu...${RESET}")"
    done
}

main_menu
