#!/bin/sh

# Get the last update's build ID
LAST_BUILD_ID=$(cat /etc/post-update.last-release | grep -E "^BUILD_ID=" | cut -d'=' -f2)

# Get the current OS release info
source /etc/os-release

echo Last OS Build "${LAST_BUILD_ID}"
echo Current OS BUild "${BUILD_ID}"

if [ -n "${LAST_BUILD_ID}" ] && [ "${BUILD_ID}" == "${LAST_BUILD_ID}" ]; then
	echo "The system is up to date."
	exit 0 # Return out early if the system is up to date
fi

# Allow system file configurations
sudo -S steamos-readonly disable

# Set the default cursor; Uncomment if you wish to change your default cursor
# sudo cp -R ./Cursors/Breeze_Dark_Red /usr/share/icons
# sudo sed -i "s/^Inherits=Adwaita*/Inherits=Breeze_Dark_Red/" /usr/share/icons/default/index.theme

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

# Store the current OS update version to compare to later
echo Storing the current OS release info...
sudo tee /etc/post-update.last-release </etc/os-release

# Set the system back to read-only
sudo -S steamos-readonly enable
