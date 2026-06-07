#!/bin/bash

# Define variables
GREEN="$(tput setaf 2)[OK]$(tput sgr0)"
RED="$(tput setaf 1)[ERROR]$(tput sgr0)"
YELLOW="$(tput setaf 3)[NOTE]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
LOG="/home/$(whoami)/install.log"
PACMAN_CONF="/etc/pacman.conf"

set -e

printf "$(tput setaf 2)Welcome to the Arch Linux auto package installer!\n$(tput sgr0)"
sleep 1

printf "$YELLOW PLEASE BACKUP YOUR FILES BEFORE PROCEEDING!
This script will overwrite some of your configs and files!\n"
sleep 1

printf "$YELLOW Some commands requires you to enter your password in order to execute
If you are worried about entering your password, you can cancel the script now with CTRL Q or CTRL C and review contents of this script.\n"
sleep 1

# Function to print error messages
print_error() {
    printf " %s%s\n" "$RED" "$1" "$NC" >&2
}

# Function to print success messages
print_success() {
    printf "%s%s%s\n" "$GREEN" "$1" "$NC"
}

# Ensure the script is run with root/sudo privileges
if [ "$EUID" -ne 0 ]; then
    print_error "${RED} Please run this script using sudo.\n"
    exit 1
fi

# G14 Repository
read -n1 -rep "${CAT} Would you like to activate Asus Strix G14 Laptop Repository? (y/n)" G14
if [[ $G14 =~ ^[Yy]$ ]]; then

    # 3. Prevent duplicate entries by checking if the [g14] block already exists
    if grep -q "^\[g14\]" "$PACMAN_CONF"; then
        printf "${YELLOW} The [g14] repository section is already present in $PACMAN_CONF.\n"
    else
        printf "${YELLOW} Appending [g14] repository block to $PACMAN_CONF...\n"
        # Append the custom repository block to the end of the file safely
        cat << 'EOF' >> "$PACMAN_CONF"

[g14]
SigLevel = DatabaseNever Optional TrustAll
Server = https://arch.asus-linux.org
EOF
        print_success "${GREEN} G14 Repository configuration appended successfully."
        echo "${GREEN} Synchronizing package databases..."
        pacman -Sy
    fi
else
    printf "${YELLOW} Asus Strix G14 Laptop Repository not activated. Moving on!\n"
fi

# G14 Custom Kernal
#read -n1 -rep "${CAT} Would you like to install Asus Strix G14 Custom Kernel packages? (y/n)" G14KERNEL
#if [[ $G14KERNEL =~ ^[Yy]$ ]]; then
#    g14kernel_pkgs="linux-g14 linux-g14-headers"
#    if ! $aur -S --noconfirm --needed $g14kernel_pkgs 2>&1 | tee -a $LOG; then
#        print_error " Failed to install Asus G14 Custom Kernel packages - please check ${LOG}\n"
#        exit 1
#    fi
#    print_success "All Asus G14 Custom Kernel packages installed successfully."
#else
#    printf "${YELLOW} No Asus G14 Custom Kernel packages installed. Moving on!\n"
#    sleep 1
#fi


































printf "${GREEN} Autoinstaller completed.\n"
