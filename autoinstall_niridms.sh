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

printf "${GREEN} Upgrading existing packages prior for autoinstaller.\n"
sudo pacman -Syyu

ISgit=/sbin/git
if [ -f "$ISgit" ]; then
    printf "${GREEN} - AUR Helper dependencies found. Moving on!\n"
else
    printf "${GREEN} - AUR Helper dependencies NOT found.\n"
    read -n1 -rep "${CAT} Would you like to install git and dependencies? (y/n)" GIT
    if [[ $GIT =~ ^[Yy]$ ]]; then
        printf "${GREEN} Installing git and dependencies.\n"
        sudo pacman -S --noconfirm --needed git base-devel
        sleep 3
    else
        printf "${RED} git and dependencies are needed for AUR Helper installation. Goodbye!\n"
        exit
    fi
fi

# Check if yay is installed
ISparu=/sbin/paru

if [ -f "$ISparu" ]; then
    printf "${GREEN} - paru found. Moving on!\n"
    aur=paru
else
    printf "${YELLOW} - paru NOT found.\n"
    read -n4 -rep "${CAT} paru is needed, would you like to install paru? (y/n)" AUR
    if [[ $AUR =~ ^[Yy]$ ]]; then
        mkdir -p ~/Documents/git
        cd ~/Documents/git
        git clone https://aur.archlinux.org/paru.git
        cd paru
        makepkg -si --noconfirm --needed 2>&1 | tee -a $LOG
        cd ..
	    rm -rf paru
        aur=paru
        # Perform system update
        printf "${YELLOW} Upgrading AUR packages to avoid issue.\n"
        $aur -Syyu --noconfirm 2>&1 | tee -a $LOG
    else
        printf "${RED} - paru is required for auto-installation. Goodbye!\n"
        exit
    fi
fi

### Install packages ####
read -n1 -rep "${CAT} Would you like to install the packages? (y/n)" PKGS
if [[ $PKGS =~ ^[Yy]$ ]]; then
    dms_pkgs="cava cups-pk-helper kimageformats power-profiles-daemon swayimg wev"
    app_pkgs="vlc zathura zathura-pdf-mupdf zathura-ps"
    util_pkgs="brightnessctl fzf ffmpeg grim gvfs-nfs gparted lf neofetch networkmanager nwg-look polkit polkit-gnome slurp usbutils thunar thunar-archive-plugin thunar-volman thunar-media-tags-plugin vlc vlc-plugin-ffmpeg tumbler yt-dlp xorg-xhost xdg-desktop-portal-gtk"
    font_pkgs="noto-fonts noto-fonts-cjk noto-fonts-emoji"
    theme_pkgs=""
    extra_pkgs="brave-bin gimp joplin-desktop libreoffice signal-desktop spotify-launcher"
    if ! $aur -S --noconfirm --needed $dms_pkgs $app_pkgs $util_pkgs $font_pkgs $theme_pkgs $extra_pkgs 2>&1 | tee -a $LOG; then
        print_error " Failed to install additional packages - please check ${LOG}\n"
        exit 1
    fi
    print_success " All necessary packages installed successfully.\n"
else
    printf "${YELLOW} No packages installed. Moving on!\n"
    sleep 1
fi

read -n1 -rep "${CAT} Would you like to install AMD packages? (y/n)" AMD
if [[ $AMD =~ ^[Yy]$ ]]; then
    amd_pkgs="amdgpu_top"
    if ! $aur -S --noconfirm --needed $amd_pkgs 2>&1 | tee -a $LOG; then
        print_error " Failed to install AMD packages - please check ${LOG}\n"
        exit 1
    fi
    print_success " All AMD packages installed successfully.\n"
else
    printf "${YELLOW} No AMD packages installed. Moving on!\n"
    sleep 1
fi

### Symbolic linking Config Files ###
read -n1 -rep "${CAT} Would you like to git clone and symbolic link config files? (y/n)" GITCFG
if [[ $GITCFG =~ ^[Yy]$ ]]; then
    printf "${YELLOW} Git cloning GitHub files...\n"
    mkdir -p ~/Temp
    mkdir -p ~/Documents/git/fphchen/
    cd ~/Documents/git/fphchen
    git clone https://github.com/fphchen/dotfiles.git 2>&1 | tee -a $LOG
    git clone https://github.com/fphchen/installers.git 2>&1 | tee -a $LOG
    git clone https://github.com/fphchen/wallpapers.git 2>&1 | tee -a $LOG
    printf "${YELLOW} Removing existing conflict config files...\n"
    rm -rf ~/.config/alacritty 2>&1 | tee -a $LOG
    rm -rf ~/.config/DankMaterialShell 2>&1 | tee -a $LOG
    rm -rf ~/.config/dunst 2>&1 | tee -a $LOG
    rm -rf ~/.config/kitty 2>&1 | tee -a $LOG
    rm -rf ~/.config/lf 2>&1 | tee -a $LOG
    rm -rf ~/.config/neofetch 2>&1 | tee -a $LOG
    rm -rf ~/.config/niri 2>&1 | tee -a $LOG
    rm -rf ~/.config/zathura 2>&1 | tee -a $LOG
    rm -rf ~/.config/xfce4 2>&1 | tee -a $LOG
    rm -rf ~/.bashrc 2>&1 | tee -a $LOG
    rm -rf ~/.zshrc 2>&1 | tee -a $LOG
    rm -rf ~/.vimrc 2>&1 | tee -a $LOG
    printf "${YELLOW} Symbolic linking config files...\n"
    ln -s ~/Documents/git/fphchen/dotfiles/configs/alacritty ~/.config/ 2>&1 | tee -a $LOG
    ln -s ~/Documents/git/fphchen/dotfiles/configs/DankMaterialShell ~/.config/ 2>&1 | tee -a $LOG
    ln -s ~/Documents/git/fphchen/dotfiles/configs/dunst ~/.config/ 2>&1 | tee -a $LOG
    ln -s ~/Documents/git/fphchen/dotfiles/configs/kitty ~/.config/ 2>&1 | tee -a $LOG
    ln -s ~/Documents/git/fphchen/dotfiles/configs/lf ~/.config/ 2>&1 | tee -a $LOG
    ln -s ~/Documents/git/fphchen/dotfiles/configs/neofetch ~/.config/ 2>&1 | tee -a $LOG
    ln -s ~/Documents/git/fphchen/dotfiles/configs/niri ~/.config/ 2>&1 | tee -a $LOG
    ln -s ~/Documents/git/fphchen/dotfiles/configs/zathura ~/.config/ 2>&1 | tee -a $LOG
    ln -s ~/Documents/git/fphchen/dotfiles/configs/xfce4 ~/.config/ 2>&1 | tee -a $LOG
    ln -s ~/Documents/git/fphchen/dotfiles/configs/.bashrc ~/ 2>&1 | tee -a $LOG
    ln -s ~/Documents/git/fphchen/dotfiles/configs/.zshrc ~/ 2>&1 | tee -a $LOG
    ln -s ~/Documents/git/fphchen/dotfiles/configs/.vimrc ~/ 2>&1 | tee -a $LOG

    ### Symbolic linking Pipewire upmix for 7.1 Surround Sound ###
    mkdir -p ~/.config/pipewire/pipewire-pulse.conf.d
    ln -s /usr/share/pipewire/pipewire.conf.avail/20-upmix.conf ~/.config/pipewire/pipewire-pulse.conf.d/ 2>&1 | tee -a $LOG
    sudo ln -s /usr/share/pipewire/pipewire.conf.avail/20-upmix.conf /etc/pipewire/pipewire-pulse.conf.d/ 2>&1 | tee -a $LOG
else
    printf "${YELLOW} No symbolic link created. Moving on!\n"
    sleep 1
fi

# ACPI
read -n1 -rep "${CAT} OPTIONAL - Would you like to install ACPI packages? (y/n)" ACPI
if [[ $ACPI =~ ^[Yy]$ ]]; then
    printf "${GREEN} Installing ACPI packages...\n"
    acpi_pkgs="acpid"
    if ! $aur -S --noconfirm --needed $acpi_pkgs 2>&1 | tee -a $LOG; then
        print_error "Failed to install ACPI packages - please check ${LOG}\n"
    else
        printf " Activating ACPI services...\n"
        sudo systemctl enable --now acpid.service
        sleep 1
    fi
else
    printf "${YELLOW} No ACPI packages installed. Moving on!\n"
fi

# SUNSHINE
read -n1 -rep "${CAT} OPTIONAL - Would you like to install Sunshine RD/Game streaming packages? (y/n)" SUNSHINE
if [[ $SUNSHINE =~ ^[Yy]$ ]]; then
    printf "${GREEN} Installing Sunshine packages...\n"
    rds_pkgs="sunshine"
    if ! $aur -S --noconfirm --needed $rds_pkgs 2>&1 | tee -a $LOG; then
       	print_error "Failed to install remote desktop streaming packages - please check ${LOG} \n"
    else
        printf " Activating avahi-daemon services for Sunshine...\n"
        sudo systemctl enable --now avahi-daemon 2>&1 | tee -a $LOG
        sleep 1
        systemctl --user enable --now sunshine.service 2>&1 | tee -a $LOG
    fi
else
    printf "${YELLOW} No remote desktop streaming packages installed. Goodbye!\n"
fi

# Asus ROG G14 packages
read -n1 -rep "${CAT} OPTIONAL - Would you like to install Asus ROG laptop packages? (y/n)" ASUS
if [[ $ASUS =~ ^[Yy]$ ]]; then
    printf "${GREEN} Installing Asus ROG laptop packages...\n"
    asus_pkgs="asusctl rog-control-center supergfxctl"
    if ! $aur -S --noconfirm --needed $asus_pkgs 2>&1 | tee -a $LOG; then
        print_error "Failed to install Asus ROG laptop packages - please check ${LOG}\n"
    else
        printf " Activating Asus services...\n"
        sudo systemctl enable --now asusd.service 2>&1 | tee -a $LOG
        sleep 1
        sudo systemctl enable --now supergfxd.service 2>&1 | tee -a $LOG
        sleep 1
    fi
else
    printf "${YELLOW} No Asus packages installed. Moving on!\n"
fi

# Asus Rog G14 Fingerprint Scanner packages
read -n1 -rep "${CAT} OPTIONAL - Would you like to install Asus ROG G14 fingerprint packages? (y/n)" ASUSFINGERPRINT
if [[ $ASUSFINGERPRINT =~ ^[Yy]$ ]]; then
    printf "${YELLOW} Removing libfprint package conflicts.\n"
    $aur -Rns libfprint fprintd 2>&1 | tee -a $LOG
    printf "${GREEN} Installing Asus ROG G14 fingerprint packages...\n"
    asusfp_pkgs="libfprint-goodix-521d fprintd"
    if ! $aur -S --noconfirm --needed $asusfp_pkgs 2>&1 | tee -a $LOG; then
        print_error "Failed to install Asus ROG G14 fingerprint packages - please check ${LOG}\n"
    else
        printf " Activating Asus ROG G14 fingerprint services...\n"
        sudo systemctl enable --now asusd.service 2>&1 | tee -a $LOG
        sleep 1
    fi
else
    printf "${YELLOW} No Asus packages installed. Moving on!\n"
fi

### SDDM Packages ###
read -n1 -rep "${CAT} OPTIONAL - Would you like to install SDDM Login Manager? (y/n)" LOGINMAN
if [[ $LOGINMAN =~ ^[Yy]$ ]]; then
    printf "${GREEN} Removing existing LightDM packages...\n"
    sudo systemctl disable lightdm.service 2>&1 | tee -a $LOG
    $aur -Rns --noconfirm lightdm lightdm-gtk-greeter 2>&1 | tee -a $LOG

    printf "${GREEN} Installing SDDM packages...\n"
    loginman_pkgs="sddm qt5-declarative qt5-graphicaleffects qt5-quickcontrols qt5-quickcontrols2 qt5-svg qt5-multimedia gst-libav gst-plugins-good phonon-qt5-gstreamer"
    if ! $aur -S --noconfirm --needed $loginman_pkgs 2>&1 | tee -a $LOG; then
        print_error "Failed to install SDDM packages - please check ${LOG}\n"
    else
        printf " Copying SDDM config files, themes, icons from cloned git repositories"
        sudo cp -r ~/Documents/git/fphchen/dotfiles/configs/sddm/NiriDMS/sddm.conf /etc/sddm.conf >&1 | tee -a $LOG
        sudo cp -r ~/Documents/git/fphchen/dotfiles/configs/sddm/NiriDMS/sddm.conf.d /etc/sddm.conf.d >&1 | tee -a $LOG
        sudo cp -r ~/Documents/git/fphchen/dotfiles/configs/sddm/themes/archcraft /usr/share/sddm/themes/archcraft >&1 | tee -a $LOG
        sudo cp -r ~/Documents/git/fphchen/dotfiles/images/.face  ~/.face >&1 | tee -a $LOG
        printf " Activating SDDM services...\n"
        sudo systemctl enable sddm.service >&1 | tee -a $LOG
        sleep 1
    fi
else
    printf "${YELLOW} No SDDM packages installed. Moving on!\n"
fi

### Enable SDDM Autologin ###
read -n1 -rep "${CAT} OPTIONAL - Would you like to enable SDDM autologin? (y/n)" SDDM
if [[ $SDDM =~ ^[Yy]$ ]]; then
    sudo mkdir -p /etc/sddm.conf.d
    LOC="/etc/sddm.conf.d/autologin.conf"
    echo -e "The following has been added to $LOC."
    echo -e "[Autologin]\nUser=$(whoami)\nSession=niri" | sudo tee -a $LOC
    #echo -e "Restarting SDDM service...\n"
    #sudo systemctl reload-or-restart sddm
    sleep 1
else
    printf "${YELLOW} SDDM Autologin NOT enabled. Moving on!\n"
fi

printf "${GREEN} Autoinstaller completed.\n"
