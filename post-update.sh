#!/bin/sh

# Get the last update's build ID; ignore outputs
cat /etc/post-update.last-release > /dev/null 2>&1
if [ $? -eq 0 ]; then
	LAST_BUILD_ID=$(cat /etc/post-update.last-release | grep -E "^BUILD_ID=" | cut -d'=' -f2)
fi

# Get the current OS release info
source /etc/os-release

if [ -n "${LAST_BUILD_ID}" ] && [ "${BUILD_ID}" == "${LAST_BUILD_ID}" ]; then
	echo "The post-update has already been run for this build."
	echo Last SteamOS Build "${LAST_BUILD_ID}"
	echo Current SteamOS Build "${BUILD_ID}"
	exit 0 # Return out early if the system is up to date
elif [ -n "${LAST_BUILD_ID}" ] && [ "${BUILD_ID}" != "${LAST_BUILD_ID}" ]; then
	echo "The post-update has not been run for this build."
	echo Last SteamOS Build "${LAST_BUILD_ID}"
	echo Current SteamOS Build "${BUILD_ID}"
else
	echo "The post-update has not been run before."
	echo Current SteamOS Build "${BUILD_ID}"
fi

# Get the current user
CURRENT_USER=$(whoami)

# Prompt for password if only if the current user is `deck`
# If the current user is root, there's no need for the password prompt
# This is because the script is most likely running as a service
# and the service is already running as root
if [ "${CURRENT_USER}" == "deck" ]; then
	PASSWORD=$(ksshaskpass -- "Please enter your password for sudo operations:" 2> /dev/null)
	echo "Validating sudo password..."
	if echo "$PASSWORD" | sudo -S -k -p "" echo "success" &> /dev/null; then
		echo "Successfully validated sudo password. Continuing..."
	else
		echo "Password failed to validate or the user ${CURRENT_USER} does not have sudo privileges."
		exit 1
	fi
fi

# Create reusable function to run sudo commands with password and yes flag
run_sudo() {
	if [ -n "${PASSWORD}" ] && [ "${CURRENT_USER}" == "deck" ]; then
		echo $PASSWORD | sudo -S -k -p "" $@
	else
		# Password was not prompted; run the command without password
		# This is most likely because this script ran from the service as root
		sudo -n $@ # Make sure to run the command without password prompt
	fi
}

# Scripts directory
SCRIPTS_DIR=/home/deck/.scripts

# Create a folder for storing logs and downloaded repos/files
mkdir -p ${SCRIPTS_DIR}

# Set the log and error file paths
LOG_FILE=${SCRIPTS_DIR}/post-update.log

# Create the log and error files
touch ${LOG_FILE}

# Allow system file configurations
run_sudo steamos-readonly disable

# Set the default cursor; Uncomment if you wish to change your default cursor
# run_sudo cp -R ./Cursors/Breeze_Dark_Red /usr/share/icons
# run_sudo sed -i "s/^Inherits=Adwaita*/Inherits=Breeze_Dark_Red/" /usr/share/icons/default/index.theme

# Populate Pacman keys
run_sudo pacman-key --init > ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error initializing Pacman keys."
	exit 1
fi
run_sudo pacman-key --populate >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error populating Pacman keys."
	exit 1
fi

# Install Crypto Filesystem for enabling vault and Disk Quota
run_sudo pacman --noconfirm --noprogressbar -S cryfs quota-tools >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error installing cryfs and quota-tools."
	exit 1
fi

# Uncomment below to do full system upgrade
# run_sudo pacman --noconfirm --noprogressbar -Syyu >> ${LOG_FILE} 2>&1
# if [ $? -ne 0 ]; then
# 	echo "Error updating the system."
# 	exit 1
# fi

# Install Yay for easy installation of Arch User apps
# Install fakeroot dependency for Yay
run_sudo pacman --noconfirm --noprogressbar -S fakeroot >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error installing fakeroot."
	exit 1
fi
# Link fix for Yay
run_sudo ln -sf /usr/lib/libalpm.so /usr/lib/libalpm.so.15 >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error linking libalpm.so to libalpm.so.15."
	exit 1
fi

# Create a function to force run the command `deck` user if ran by root
# Otherwise, run the command as is
run_as_user() {
	if [ "${CURRENT_USER}" != "deck" ]; then
		# Run the script as the `deck` user for installing Yay due to the `makepkg` limitation
		run_sudo -i -u deck $@
	else
		echo $PASSWORD | $@
	fi
}

YAY_BIN_DIR=${SCRIPTS_DIR}/yay-bin
run_sudo rm -rf ${YAY_BIN_DIR}
run_as_user git clone https://aur.archlinux.org/yay-bin.git ${YAY_BIN_DIR} >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error cloning yay-bin repository."
	exit 1
fi
cd ${YAY_BIN_DIR}
# # Pacman version fix for installing Yay
run_as_user sed -i -e 's/pacman>6.1/pacman>6/g' ${YAY_BIN_DIR}/PKGBUILD >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error fixing the PKGBUILD file for yay."
	exit 1
fi
run_as_user makepkg --noconfirm -si >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error building yay package."
	exit 1
fi
cd ${SCRIPTS_DIR}
run_sudo rm -rf ${YAY_BIN_DIR}
# run_sudo chown deck:deck /usr/bin/yay >> ${LOG_FILE} 2>&1
# Install progress using yay
run_as_user yay --noconfirm -S progress >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error installing progress via yay."
	exit 1
fi

# Install Tailscale (See more here https://tailscale.com/)
TAILSCALE_DIR=${SCRIPTS_DIR}/deck-tailscale
cd ${SCRIPTS_DIR}
rm -rf ${TAILSCALE_DIR}
run_as_user git clone https://github.com/tailscale-dev/deck-tailscale.git ${TAILSCALE_DIR} >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error cloning deck-tailscale repository."
	exit 1
fi
cd ${TAILSCALE_DIR}
sed -i "s/^wget -q --show-progress*/wget -q/" ./tailscale.sh >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error modifying the tailscale.sh script."
	exit 1
fi
run_sudo bash ./tailscale.sh >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error installing Tailscale."
	exit 1
fi
source /etc/profile.d/tailscale.sh >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error sourcing Tailscale profile."
	exit 1
fi
cd ${SCRIPTS_DIR}
rm -rf ${TAILSCALE_DIR}

# Install Warp Terminal (See more here https://www.warp.dev/)
run_sudo rm -rf /opt/warpdotdev/warp-terminal
wget -q -O ${SCRIPTS_DIR}/warp-terminal.pkg.tar.zst https://app.warp.dev/download?package=pacman >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error downloading Warp Terminal package."
	exit 1
fi
run_sudo pacman --noconfirm --noprogressbar -U ${SCRIPTS_DIR}/warp-terminal.pkg.tar.zst >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error installing Warp Terminal."
	exit 1
fi
rm ${SCRIPTS_DIR}/warp-terminal.pkg.tar.zst

# Store the current OS update version to compare to later; ignore output
sudo -S tee /etc/post-update.last-release < /etc/os-release 1> /dev/null

# Set the system back to read-only
run_sudo steamos-readonly enable

echo "SteamOS post-update process completed successfully."

exit 0
