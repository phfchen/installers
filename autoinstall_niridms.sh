#!/bin/bash

# Define variables
GREEN="$(tput setaf 2)[OK]$(tput sgr0)"
RED="$(tput setaf 1)[ERROR]$(tput sgr0)"
YELLOW="$(tput setaf 3)[NOTE]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
LOG="/home/$(whoami)/install.log"

# Set the script to exit on error
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

# Ask for password once
sudo -v

# Keep sudo alive with a longer interval
while true; do
    sleep 60   # 1 minutes
    sudo -n true
done 2>/dev/null &

# Define the config path
PACMAN_CONF="/etc/pacman.conf"

# Multilib Repository 
printf "${GREEN} Checking multilib repository status...\n"
# Check if multilib is already uncommented
if grep -q "^\[multilib\]" "$PACMAN_CONF"; then
    printf "${GREEN} Multilib is already enabled in $PACMAN_CONF.\n"
else
    printf "${GREEN} Enabling multilib...\n"
    # Match the multilib block range and strip the leading '#' comment symbol
    sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman\.d\/mirrorlist/ s/^#//' "$PACMAN_CONF"
    
    printf "${GREEN} Synchronizing package databases...\n"
    sudo pacman -Sy
    print_success "Multilib repository successfully activated!"

    printf "${GREEN} Upgrading existing packages prior for autoinstaller.\n"
    sudo pacman -Syyu
fi

# AUR Helper 
ISgit=/sbin/git
if [ -f "$ISgit" ]; then
    printf "${GREEN} - AUR Helper dependencies found. Moving on!\n"
else
    printf "${GREEN} - AUR Helper dependencies NOT found.\n"
    read -n1 -rep "${CAT} Would you like to install git and dependencies? (y/n)" GIT
    if [[ $GIT =~ ^[Yy]$ ]]; then
        printf "${GREEN} Installing git and dependencies.\n"
        sudo pacman -S --noconfirm --needed git base-devel 2>&1 | tee -a $LOG
        sleep 3
    else
        printf "${RED} git and dependencies are needed for AUR Helper installation. Goodbye!\n"
        exit
    fi
fi

# Check if paru is installed
ISparu=/sbin/paru

if [ -f "$ISparu" ]; then
    printf "${GREEN} - paru found. Moving on!\n"
    aur=paru
else
    printf "${YELLOW} - paru NOT found.\n"
    read -n4 -rep "${CAT} paru is needed, would you like to install paru? (y/n)" AUR
    if [[ $AUR =~ ^[Yy]$ ]]; then
        mkdir -p ~/Documents/git 2>&1 | tee -a $LOG
        cd ~/Documents/git
        git clone https://aur.archlinux.org/paru.git
        cd paru
        makepkg -si --noconfirm --needed 2>&1 | tee -a $LOG
        cd ..
	    rm -rf paru 2>&1 | tee -a $LOG
        aur=paru
        # Perform system update
        printf "${YELLOW} Upgrading AUR packages to avoid issue.\n"
        $aur -Syyu --noconfirm 2>&1 | tee -a $LOG
    else
        printf "${RED} - paru is required for auto-installation. Goodbye!\n"
        exit
    fi
fi

# Install packages
read -n1 -rep "${CAT} Would you like to install the packages? (y/n)" PKGS
if [[ $PKGS =~ ^[Yy]$ ]]; then
    dms_pkgs="cava cups-pk-helper kimageformats power-profiles-daemon swayimg wev"
    app_pkgs="kitty vlc zathura zathura-pdf-mupdf zathura-ps"
    util_pkgs="brightnessctl fzf ffmpeg grim gvfs-nfs gvfs-smb gparted lf neofetch networkmanager nwg-look polkit polkit-gnome sbctl slurp smbclient usbutils thunar thunar-archive-plugin thunar-volman thunar-media-tags-plugin tigervnc vlc-plugin-ffmpeg tumbler yt-dlp xorg-xhost xdg-desktop-portal-gtk"
    font_pkgs="noto-fonts noto-fonts-cjk noto-fonts-emoji"
    theme_pkgs=""
    extra_pkgs="brave-bin firefox gimp joplin-desktop libreoffice signal-desktop spotify-launcher"
    if ! $aur -S --noconfirm --needed $dms_pkgs $app_pkgs $util_pkgs $font_pkgs $theme_pkgs $extra_pkgs 2>&1 | tee -a $LOG; then
        print_error " Failed to install additional packages - please check ${LOG}"
        exit 1
    fi
    print_success "All necessary packages installed successfully."
else
    printf "${YELLOW} No packages installed. Moving on!\n"
    sleep 1
fi

read -n1 -rep "${CAT} Would you like to install nVidia packages? (y/n)" NVIDIA
if [[ $NVIDIA =~ ^[Yy]$ ]]; then
    nvidia_pkgs="nvidia-open-dkms nvidia-utils lib32-nvidia-utils"
    if ! $aur -S --noconfirm --needed $nvidia_pkgs 2>&1 | tee -a $LOG; then
        print_error " Failed to install nVidia packages - please check ${LOG}"
        exit 1
    fi
    print_success "All nVidia packages installed successfully."
else
    printf "${YELLOW} No nVidia packages installed. Moving on!\n"
    sleep 1
fi

read -n1 -rep "${CAT} Would you like to install AMD packages? (y/n)" AMD
if [[ $AMD =~ ^[Yy]$ ]]; then
    amd_pkgs="amdgpu_top"
    if ! $aur -S --noconfirm --needed $amd_pkgs 2>&1 | tee -a $LOG; then
        print_error " Failed to install AMD packages - please check ${LOG}"
        exit 1
    fi
    print_success "All AMD packages installed successfully."
else
    printf "${YELLOW} No AMD packages installed. Moving on!\n"
    sleep 1
fi

read -n1 -rep "${CAT} Would you like to install PipeWire audio packages? (y/n)" AUDIO
if [[ $AUDIO =~ ^[Yy]$ ]]; then
    audio_pkgs="pipewire wireplumber piewire-pulse pipewire-alsa alsa-utils sof-firmware"
    if ! $aur -S --noconfirm --needed $audio_pkgs 2>&1 | tee -a $LOG; then
        print_error " Failed to install PipeWire audio packages - please check ${LOG}"
        exit 1
    fi
    print_success "All PipeWire audio packages installed successfully."
else
    printf "${YELLOW} No PipeWire audio packages installed. Moving on!\n"
    sleep 1
fi

read -n1 -rep "${CAT} Would you like to install Bluetooth packages? (y/n)" BLUETOOTH
if [[ $BLUETOOTH =~ ^[Yy]$ ]]; then
    bluetooth_pkgs="bluez bluez-utils"
    if ! $aur -S --noconfirm --needed $bluetooth_pkgs 2>&1 | tee -a $LOG; then
        print_error " Failed to install Bluetooth packages - please check ${LOG}"
        exit 1
    fi
    print_success "All Bluetooth packages installed successfully."
else
    printf "${YELLOW} No Bluetooth audio packages installed. Moving on!\n"
    sleep 1
fi

# Symbolic linking Config Files 
read -n1 -rep "${CAT} Would you like to git clone and symbolic link config files? (y/n)" GITCFG
if [[ $GITCFG =~ ^[Yy]$ ]]; then
    printf "${YELLOW} Git cloning GitHub files...\n"
    mkdir -p ~/Desktop ~/Documents ~/Downloads ~/Music ~/Pictures ~/Projects ~/Public ~/Temp ~/Templates ~/Videos 2>&1 | tee -a $LOG
    mkdir -p ~/Documents/git/phfchen 2>&1 | tee -a $LOG
    cd ~/Documents/git/phfchen
    git clone https://github.com/phfchen/dotfiles.git 2>&1 | tee -a $LOG
    git clone https://github.com/phfchen/installers.git 2>&1 | tee -a $LOG
    git clone https://github.com/phfchen/wallpapers.git 2>&1 | tee -a $LOG
    printf "${YELLOW} Removing existing conflict config files...\n"
    rm -rf ~/.config/alacritty 2>&1 | tee -a $LOG
    rm -rf ~/.config/DankMaterialShell 2>&1 | tee -a $LOG
    rm -rf ~/.config/dunst 2>&1 | tee -a $LOG
    rm -rf ~/.config/kitty 2>&1 | tee -a $LOG
    rm -rf ~/.config/lf 2>&1 | tee -a $LOG
    rm -rf ~/.config/neofetch 2>&1 | tee -a $LOG
    rm -rf ~/.config/niri 2>&1 | tee -a $LOG
    rm -rf ~/.config/xfce4 2>&1 | tee -a $LOG
    rm -rf ~/.config/zathura 2>&1 | tee -a $LOG
    rm -rf ~/.bashrc 2>&1 | tee -a $LOG
    rm -rf ~/.zshrc 2>&1 | tee -a $LOG
    rm -rf ~/.vimrc 2>&1 | tee -a $LOG
    printf "${YELLOW} Symbolic linking config files...\n"
    ln -s ~/Documents/git/phfchen/dotfiles/configs/alacritty ~/.config/ 2>&1 | tee -a $LOG
    ln -s ~/Documents/git/phfchen/dotfiles/configs/DankMaterialShell ~/.config/ 2>&1 | tee -a $LOG
    ln -s ~/Documents/git/phfchen/dotfiles/configs/dunst ~/.config/ 2>&1 | tee -a $LOG
    ln -s ~/Documents/git/phfchen/dotfiles/configs/kitty ~/.config/ 2>&1 | tee -a $LOG
    ln -s ~/Documents/git/phfchen/dotfiles/configs/lf ~/.config/ 2>&1 | tee -a $LOG
    ln -s ~/Documents/git/phfchen/dotfiles/configs/neofetch ~/.config/ 2>&1 | tee -a $LOG
    ln -s ~/Documents/git/phfchen/dotfiles/configs/niri ~/.config/ 2>&1 | tee -a $LOG
    ln -s ~/Documents/git/phfchen/dotfiles/configs/xfce4 ~/.config/ 2>&1 | tee -a $LOG
    ln -s ~/Documents/git/phfchen/dotfiles/configs/zathura ~/.config/ 2>&1 | tee -a $LOG
    ln -s ~/Documents/git/phfchen/dotfiles/configs/.bashrc ~/ 2>&1 | tee -a $LOG
    ln -s ~/Documents/git/phfchen/dotfiles/configs/.zshrc ~/ 2>&1 | tee -a $LOG
    ln -s ~/Documents/git/phfchen/dotfiles/configs/.vimrc ~/ 2>&1 | tee -a $LOG

    # Symbolic linking Pipewire upmix for 7.1 Surround Sound
    mkdir -p ~/.config/pipewire/pipewire-pulse.conf.d 2>&1 | tee -a $LOG
    ln -s /usr/share/pipewire/pipewire.conf.avail/20-upmix.conf ~/.config/pipewire/pipewire-pulse.conf.d/ 2>&1 | tee -a $LOG
    sudo ln -s /usr/share/pipewire/pipewire.conf.avail/20-upmix.conf /etc/pipewire/pipewire-pulse.conf.d/ 2>&1 | tee -a $LOG
else
    printf "${YELLOW} No symbolic link created. Moving on!\n"
    sleep 1
fi

# SUNSHINE
read -n1 -rep "${CAT} OPTIONAL - Would you like to install Sunshine RD/Game streaming packages? (y/n)" SUNSHINE
if [[ $SUNSHINE =~ ^[Yy]$ ]]; then
    printf "${YELLOW} Installing Sunshine packages...\n"
    rds_pkgs="sunshine"
    if ! $aur -S --noconfirm --needed $rds_pkgs 2>&1 | tee -a $LOG; then
       	print_error " Failed to install remote desktop streaming packages - please check ${LOG}"
    else
        printf "${YELLOW} Activating avahi-daemon services for Sunshine...\n"
        sudo systemctl enable --now avahi-daemon 2>&1 | tee -a $LOG
        sleep 1
        systemctl --user --now enable app-dev.lizardbyte.app.Sunshine 2>&1 | tee -a $LOG
    fi
else
    printf "${YELLOW} No remote desktop streaming packages installed. Goodbye!\n"
fi

# SDDM Packages
read -n1 -rep "${CAT} OPTIONAL - Would you like to install SDDM Login Manager? (y/n)" LOGINMAN
if [[ $LOGINMAN =~ ^[Yy]$ ]]; then
    printf "${YELLOW} Installing SDDM packages...\n"
    loginman_pkgs="sddm qt5-declarative qt5-graphicaleffects qt5-quickcontrols qt5-quickcontrols2 qt5-svg qt5-multimedia gst-libav gst-plugins-good phonon-qt5-gstreamer"
    if ! $aur -S --noconfirm --needed $loginman_pkgs 2>&1 | tee -a $LOG; then
        print_error " Failed to install SDDM packages - please check ${LOG}"
    else
        printf " Copying SDDM config files, themes, icons from cloned git repositories"
        sudo cp -r ~/Documents/git/phfchen/dotfiles/configs/sddm/NiriDMS/sddm.conf /etc/sddm.conf 2>&1 | tee -a $LOG
        sudo cp -r ~/Documents/git/phfchen/dotfiles/configs/sddm/NiriDMS/sddm.conf.d /etc/sddm.conf.d 2>&1 | tee -a $LOG
        sudo cp -r ~/Documents/git/phfchen/dotfiles/configs/sddm/themes/archcraft /usr/share/sddm/themes/archcraft 2>&1 | tee -a $LOG
        sudo cp -r ~/Documents/git/phfchen/dotfiles/images/.face  ~/.face 2>&1 | tee -a $LOG
        printf " Activating SDDM services...\n"
        sudo systemctl enable sddm.service 2>&1 | tee -a $LOG
        sleep 1
    fi
else
    printf "${YELLOW} No SDDM packages installed. Moving on!\n"
fi

# Enable SDDM Autologin
read -n1 -rep "${CAT} OPTIONAL - Would you like to enable SDDM autologin? (y/n)" SDDM
if [[ $SDDM =~ ^[Yy]$ ]]; then
    sudo mkdir -p /etc/sddm.conf.d 2>&1 | tee -a $LOG
    LOC="/etc/sddm.conf.d/autologin.conf"
    printf "The following has been added to $LOC."
    printf "[Autologin]\nUser=$(whoami)\nSession=niri" | tee -a $LOC
    printf "Restarting SDDM service...\n"
    sudo systemctl reload-or-restart sddm 2>&1 | tee -a $LOG
    sleep 1
else
    printf "${YELLOW} SDDM Autologin NOT enabled. Moving on!\n"
fi

# Asus ROG Laptop packages
read -n1 -rep "${CAT} OPTIONAL - Would you like to install Asus ROG laptop packages? (y/n)" ASUS
if [[ $ASUS =~ ^[Yy]$ ]]; then
    printf "${YELLOW} Installing Asus ROG laptop packages...\n"
    asus_pkgs="asusctl rog-control-center supergfxctl"
    if ! $aur -S --noconfirm --needed $asus_pkgs 2>&1 | tee -a $LOG; then
        print_error " Failed to install Asus ROG laptop packages - please check ${LOG}"
    else
        printf "${YELLOW} Activating Asus services...\n"
        sudo systemctl enable --now asusd.service 2>&1 | tee -a $LOG
        sleep 1
        sudo systemctl enable --now supergfxd.service 2>&1 | tee -a $LOG
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
    sudo ./strap.sh 2>&1 | tee -a $LOG
    printf "${GREEN} Installing Blackarch packages...\n"
    blackedarch_pkgs="blackarch-officials burpsuite dirbuster openbsd-netcat less netdiscover sublist3r whatweb"
    if ! $aur -S --noconfirm --needed $blackedarch_pkgs 2>&1 | tee -a $LOG; then
        print_error " Failed to install BlackArch packages - please check ${LOG}"
        sleep 1
    fi
else
    printf "${YELLOW} No Blackarch Packages installed. Moving on!\n"
fi

print_success "Autoinstaller completed."
