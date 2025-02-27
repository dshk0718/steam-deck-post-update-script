#!/bin/sh

SCRIPTS_DIR=/home/deck/.scripts

# Create a folder for storing logs and downloaded repos/files
mkdir -p ${SCRIPTS_DIR}

# Set the log and error file paths
LOG_FILE=${SCRIPTS_DIR}/post-update.log

# Create the log and error files
touch ${LOG_FILE}

# Change to `SCRIPTS_DIR` directory before installing any user apps
cd ${SCRIPTS_DIR}
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
echo y | yay -S progress >> ${LOG_FILE} 2>&1
if [ $? -ne 0 ]; then
	echo "Error installing progress via yay."
	exit 1
fi
rm -rf ./yay-bin

exit 0
