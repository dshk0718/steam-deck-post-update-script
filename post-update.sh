#!/bin/sh

# Create a folder for storing logs and downloaded repos/files
mkdir -p /home/deck/.scripts

# Set the log and error file paths
LOG_FILE=/home/deck/.scripts/post-update.log

# Get the last update's build ID; ignore outputs
cat /etc/post-update.last-release > /dev/null 2>&1
if [ $? -eq 0 ]; then
	LAST_BUILD_ID=$(cat /etc/post-update.last-release | grep -E "^BUILD_ID=" | cut -d'=' -f2)
fi

# Get the current OS release info
source /etc/os-release

if [ -n "${LAST_BUILD_ID}" ] && [ "${BUILD_ID}" == "${LAST_BUILD_ID}" ]; then
	echo "The post-update has already been run for this build."
	echo Last OS Build "${LAST_BUILD_ID}"
	echo Current OS BUild "${BUILD_ID}"
	exit 0 # Return out early if the system is up to date
elif [ -n "${LAST_BUILD_ID}" ] && [ "${BUILD_ID}" != "${LAST_BUILD_ID}" ]; then
	echo "The post-update has not been run for this build."
	echo Last OS Build "${LAST_BUILD_ID}"
	echo Current OS BUild "${BUILD_ID}"
else
	echo "The post-update has not been run before."
	echo Current OS BUild "${BUILD_ID}"
fi

# Create the log and error files
touch ${LOG_FILE}

# Allow system file configurations
sudo steamos-readonly disable

# Set the default cursor; Uncomment if you wish to change your default cursor
# sudo cp -R ./Cursors/Breeze_Dark_Red /usr/share/icons
# sudo sed -i "s/^Inherits=Adwaita*/Inherits=Breeze_Dark_Red/" /usr/share/icons/default/index.theme

# Populate Pacman keys
echo y | sudo pacman-key --init > ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error initializing Pacman keys."
	exit 1
fi
echo y | sudo pacman-key --populate >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error populating Pacman keys."
	exit 1
fi

# Install Crypto Filesystem for enabling vault and Disk Quota
echo y | sudo pacman -S cryfs quota-tools >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error installing cryfs and quota-tools."
	exit 1
fi

# Uncomment below to do full system upgrade
# echo y | sudo pacman -Syyu >> ${LOG_FILE} 2>&1
# if [ $? -ne 0 ]; then
# 	echo "Error updating the system."
# 	exit 1
# fi

# Install Yay for easy installation of Arch User apps
echo y | sudo pacman -S fakeroot >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error installing fakeroot."
	exit 1
fi
# Change to `/home/deck/.scripts` directory before installing any user apps
cd /home/deck/.scripts
rm -rf ./yay-bin
git clone https://aur.archlinux.org/yay-bin.git >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error cloning yay-bin repository."
	exit 1
fi
cd yay-bin
# Pacman version fix for installing Yay
sed -i -e 's/pacman>6.1/pacman>6/g' PKGBUILD >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error fixing the PKGBUILD file for Yay."
	exit 1
fi
echo y | makepkg -si >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error installing Yay."
	exit 1
fi
cd ..
# Link fix for Yay
sudo ln -sf /usr/lib/libalpm.so /usr/lib/libalpm.so.15 >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error linking libalpm.so to libalpm.so.15."
	exit 1
fi
echo y | yay -S progress >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error installing progress via yay."
	exit 1
fi
rm -rf ./yay-bin

# Install Tailscale (See more here https://tailscale.com/)
rm -rf ./deck-tailscale
git clone https://github.com/tailscale-dev/deck-tailscale.git >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error cloning deck-tailscale repository."
	exit 1
fi
cd deck-tailscale
sudo bash ./tailscale.sh >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error installing Tailscale."
	exit 1
fi
source /etc/profile.d/tailscale.sh >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error sourcing Tailscale profile."
	exit 1
fi
rm -rf ./deck-tailscale

# Install Warp Terminal (See more here https://www.warp.dev/)
sudo rm -rf /opt/warpdotdev/warp-terminal
wget -O /home/deck/.scripts/warp-terminal.pkg.tar.zst https://app.warp.dev/download?package=pacman >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error downloading Warp Terminal package."
	exit 1
fi
echo y | sudo pacman -U /home/deck/.scripts/warp-terminal.pkg.tar.zst >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error installing Warp Terminal."
	exit 1
fi
rm /home/deck/.scripts/warp-terminal.pkg.tar.zst

# Store the current OS update version to compare to later; ignore output
sudo tee /etc/post-update.last-release < /etc/os-release 1> /dev/null

# Set the system back to read-only
sudo steamos-readonly enable

exit 0
