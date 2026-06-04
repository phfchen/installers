#!/bin/bash

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
    echo "${RED} Please run this script using sudo."
    exit 1
fi

# Define the pacman config path
PACMAN_CONF="/etc/pacman.conf"

# G14 Repository
read -n1 -rep "${CAT} Would you like to activate Asus Strix G14 Laptop Repository? (y/n)" G14
if [[ $G14 =~ ^[Yy]$ ]]; then

    # 3. Prevent duplicate entries by checking if the [g14] block already exists
    if grep -q "^\[g14\]" "$PACMAN_CONF"; then
        printf "${YELLOW} The [g14] repository section is already present in $PACMAN_CONF."
    else
        printf "${YELLOW} Appending [g14] repository block to $PACMAN_CONF..."
        # Append the custom repository block to the end of the file safely
        cat << 'EOF' >> "$PACMAN_CONF"

[g14]
SigLevel = DatabaseNever Optional TrustAll
Server = https://arch.asus-linux.org
EOF
        echo "${GREEN} G14 Repository configuration appended successfully."
        echo "${GREEN} Synchronizing package databases..."
        pacman -Sy
    fi
else
    printf "${YELLOW} Asus Strix G14 Laptop Repository not activated. Moving on!\n"
fi

# Asus ROG G14 packages
read -n1 -rep "${CAT} OPTIONAL - Would you like to install Asus ROG laptop packages? (y/n)" ASUS
if [[ $ASUS =~ ^[Yy]$ ]]; then
    printf "${YELLOW} Installing Asus ROG laptop packages...\n"
    asus_pkgs="asusctl rog-control-center supergfxctl"
    if ! $aur -S --noconfirm --needed $asus_pkgs 2>&1 | tee -a $LOG; then
        print_error " Failed to install Asus ROG laptop packages - please check ${LOG}\n"
    else
        printf "${YELLOW} Activating Asus services...\n"
        systemctl enable --now asusd.service 2>&1 | tee -a $LOG
        sleep 1
        systemctl enable --now supergfxd.service 2>&1 | tee -a $LOG
        sleep 1
    fi
else
    printf "${YELLOW} No Asus ROG laptop packages installed. Moving on!\n"
fi

# Blackarch Packages
read -n1 -rep "${CAT} OPTIONAL - Would you like to install Blackarch Packages? (y/n)" BLACKARCH
if [[ $BLACKARCH =~ ^[Yy]$ ]]; then
    curl -O https://blackarch.org/strap.sh 2>&1 | tee -a $LOG
    chmod +x strap.sh 2>&1 | tee -a $LOG
    ./strap.sh 2>&1 | tee -a $LOG
    printf "${GREEN} Installing Blackarch packages...\n"
    blackedarch_pkgs="blackarch-officials burpsuite dirbuster gnu-netcat less netdiscover sublist3r whatweb"
    if ! $aur -S --noconfirm --needed $blackedarch_pkgs 2>&1 | tee -a $LOG; then
        print_error " Failed to install BlackArch packages - please check ${LOG}\n"
        sleep 1
    fi
    rm -rf ./strap.sh
else
    printf "${YELLOW} No Blackarch Packages installed. Moving on!\n"
fi

printf "${GREEN} Autoinstaller completed.\n"
