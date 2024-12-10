#!/bin/bash

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m[*] '
YELLOW='\033[0;33m[*] '
RESET='\033[0m'

# Dynamically find Tor user
TOR_USER=$(grep -Po '(?<=^User ).*' /etc/tor/torrc | head -n 1)
if [ -z "$TOR_USER" ]; then
    echo "Tor user not found in /etc/tor/torrc. Falling back to default: debian-tor."
    TOR_USER="debian-tor"
fi

add_rules() {
	echo "Using Tor user: $TOR_USER"

	# Set up Kill-Switch
	echo -e "${YELLOW}Applying iptables rules...${RESET}"
	sudo iptables -A OUTPUT -m owner --uid-owner "$TOR_USER" -j ACCEPT
	sudo iptables -A OUTPUT -d 127.0.0.1 -j ACCEPT
	sudo iptables -A OUTPUT -j REJECT

echo -e "${GREEN}iptables rules applied successfully.${RESET}"
}


# Function to remove iptables rules
delete_rules() {
    echo -e "${YELLOW}Removing iptables rules...${RESET}"
    sudo iptables -F
    echo -e "${GREEN}Rules removed.${RESET}"
}

# Function to check for iptables rules
check_rules() {
    echo -e "${YELLOW}Checking iptables rules...${RESET}"
    if sudo iptables -L OUTPUT -v -n | grep -q "REJECT"; then
        echo -e "${RED}Rules already exist!${RESET}"
        read -p "Do you want to delete these? (y/n): " choice
        if [[ $choice == "y" || $choice == "Y" ]]; then
            delete_rules
        else
            echo -e "${GREEN}Keeping existing rules.${RESET}"
            exit 0
        fi
    else
        echo -e "${GREEN}No iptables rules found.${RESET}"
        add_rules
    fi
}

# Function to check if Tor is installed, running, or needs action
check_tor() {
    echo -e "${YELLOW}Checking if Tor is installed...${RESET}"
    if ! command -v tor &> /dev/null; then
        echo -e "${RED}Tor is not installed. Installing Tor...${RESET}"
        sudo apt update && sudo apt install -y tor iptables-persistent
        sudo systemctl enable --now tor
        echo -e "${GREEN}Tor installed and started.${RESET}"
    else
        echo -e "${GREEN}Tor is already installed.${RESET}"
        if systemctl is-active --quiet tor; then
            echo -e "${YELLOW}Tor is running.${RESET}"
            read -p "Do you want to stop Tor and remove iptables rules? (y/n): " choice
            if [[ $choice == "y" || $choice == "Y" ]]; then
                sudo systemctl stop tor
                #delete_rules
                echo -e "${RED}Tor stopped and iptables rules removed.${RESET}"
            else
                echo -e "${GREEN}Keeping Tor running and existing rules intact.${RESET}"
            fi
        else
            echo -e "${GREEN}Tor is installed but not running.${RESET}"
            read -p "Do you want to start Tor? (y/n): " choice
            if [[ $choice == "y" || $choice == "Y" ]]; then
            	systemctl start tor
            fi
        fi
    fi
}

echo -e "${YELLOW}Setting up Tor Kill-Switch...${RESET}"

check_tor
check_rules

read -p "Save these rules permanently? (y/n): " save_choice
if [[ $save_choice == "y" || $save_choice == "Y" ]]; then
    echo -e "${YELLOW}Saving rules...${RESET}"
    sudo sh -c "iptables-save > /etc/iptables/rules.v4"
    sudo sh -c "iptables-save > /etc/iptables/rules.v6"
    echo -e "${GREEN}Rules saved.${RESET}"
else
    echo -e "${RED}Rules will not be saved to persist.${RESET}"
fi
