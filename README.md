# Steam Deck Post Update Script
Script for auto-reinstalling user installed apps like Tailscale and Warp Terminal on SteamOS after OS update due to its "immutable" OS structure.

Tailscale is very useful for creating your own VPN so that you can connect to your home network and essentially access all your home network devices and machines. For example, with Tailscale, MoonDeck, and Sunshine, you can remotely stream from your PC to your Steam Deck potentially anywhere. See more about Tailscale here: https://tailscale.com/.

Warp Terminal is an AI-powered terminal that can assist you with any terminal/script related things and more. It's very helpful to do things within the SteamOS desktop mode especially when you don't know the ins-and-outs of the Arch Linux and the basic Linux commands. See more about Warp Terminal here: https://www.warp.dev/.

Note that this script does alter your system (while only minimally in terms of installing user apps), so run this script at your own discretion.
I am not responsible for any issues that this script may cause on your Steam Deck.

## Prerequisites
  1. Password must be set beforehand.
  ```bash
  sudo passwd  
  ```
  2. Git must be installed on your Steam Deck.
  ```bash
  sudo pacman -S git
  ```

## Steps for Running
  1. Clone this repo.
  ```bash
  git clone https://github.com/dshk0718/steam-deck-post-update-script.git
  ```
  2. Move into the cloned repo directory.
  ```bash
  cd steam-deck-post-update-script
  ```
  3. Run the script. You must enter your password when prompted to run this shell script.
  ```bash
  ./post-update.sh
  ```
  4. Altogether.
  ```bash
  git clone https://github.com/dshk0718/steam-deck-post-update-script.git
  cd steam-deck-post-update-script
  ./post-update.sh
  ```

## Custom Settings
  * Within the `post-script.sh`, there is this part where it sets the default cursor for all windows that are open on the Steam Deck (even applies to your open windows of Non-Steam apps in the Game Mode using `gamescope`).
  ```bash
  sudo cp -R ./Cursors/Breeze_Dark_Red /usr/share/icons
  sudo sed -i "s/^Inherits=Adwaita*/Inherits=Breeze_Dark_Red/" /usr/share/icons/default/index.theme
  ```
  You can change which cursor pack to use as default by installing the cursor pack from the KDE settings > Appearance > Cursors > Get New Cursors and then copying the folder of the installed custom cursor pack from `/home/deck/.icons` to the repo's directory `Cursors`. Once copied, you can replace the `Breeze_Dark_Red` in these commands with the name of the cursor pack you just installed.
  If you wish to keep your current cursor settings, you can disable these lines by commenting them out with `#` at the front of these commands.
