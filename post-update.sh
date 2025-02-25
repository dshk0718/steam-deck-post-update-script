#!/bin/sh

# Allow system file configurations
sudo -S steamos-readonly disable

# Set the default cursor
sudo cp -R ./Cursors/Breeze_Dark_Red /usr/share/icons
sudo sed -i "s/^Inherits=Adwaita*/Inherits=Breeze_Dark_Red/" /usr/share/icons/default/index.theme

# Populate Pacman keys and install necessary tools
echo y | sudo pacman-key --init
echo y | sudo pacman-key --populate
# echo y | sudo pacman -Syyu
echo y | sudo pacman -S cryfs quota-tools fakeroot

# Install Yay for easy installation of Arch User apps
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
sed -i -e 's/pacman>6.1/pacman>6/g' PKGBUILD
echo y | makepkg -si
cd ..
rm -rf ./yay-bin
sudo ln -s /usr/lib/libalpm.so /usr/lib/libalpm.so.15
echo y | yay -S progress

# Install Tailscale
cd /home/deck/Scripts
rm -rf ./deck-tailscale
git clone https://github.com/tailscale-dev/deck-tailscale.git
cd ./deck-tailscale
sudo bash ./tailscale.sh
source /etc/profile.d/tailscale.sh

# Install Warp Terminal
sudo rm -R /opt/warpdotdev/warp-terminal
wget -O /home/deck/Scripts/warp-terminal.pkg.tar.zst https://app.warp.dev/download?package=pacman
echo y | sudo pacman -U /home/deck/Scripts/warp-terminal.pkg.tar.zst

# Set the system back to read-only
sudo steamos-readonly enable
