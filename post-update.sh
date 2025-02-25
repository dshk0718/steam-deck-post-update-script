#!/bin/sh

# Allow system file configurations
sudo -S steamos-readonly disable

# Set the default cursor
sudo cp -R ./Cursors/Breeze_Dark_Red /usr/share/icons
sudo sed -i "s/^Inherits=Adwaita*/Inherits=Breeze_Dark_Red/" /usr/share/icons/default/index.theme

# Populate Pacman keys
echo y | sudo pacman-key --init
echo y | sudo pacman-key --populate

# Install Crypto Filesystem for enabling vault and Disk Quota
echo y | sudo pacman -S cryfs quota-tools
# echo y | sudo pacman -Syyu # Enable this if you want to update the system

# Install Yay for easy installation of Arch User apps
echo y | sudo pacman -S fakeroot
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
sed -i -e 's/pacman>6.1/pacman>6/g' PKGBUILD # Pacman version fix for installing Yay
echo y | makepkg -si
cd ..
rm -rf ./yay-bin
sudo ln -s /usr/lib/libalpm.so /usr/lib/libalpm.so.15 # Link fix for Yay
echo y | yay -S progress

# Install Tailscale (See more here https://tailscale.com/)
mkdir -p /home/deck/Scripts
cd /home/deck/Scripts
rm -rf ./deck-tailscale
git clone https://github.com/tailscale-dev/deck-tailscale.git
cd ./deck-tailscale
sudo bash ./tailscale.sh
source /etc/profile.d/tailscale.sh

# Install Warp Terminal (See more here https://www.warp.dev/)
sudo rm -R /opt/warpdotdev/warp-terminal
wget -O /home/deck/Scripts/warp-terminal.pkg.tar.zst https://app.warp.dev/download?package=pacman
echo y | sudo pacman -U /home/deck/Scripts/warp-terminal.pkg.tar.zst

# Set the system back to read-only
sudo steamos-readonly enable
