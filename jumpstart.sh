sudo apt update -y 
sudo apt full-upgrade -y
sudo mkdir -pm755 /etc/apt/keyrings
wget -O - https://dl.winehq.org/wine-builds/winehq.key | sudo gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key -
sudo dpkg --add-architecture i386
sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources
sudo apt update
sudo apt install --install-recommends winehq-stable -y
sudo apt install fuse -y
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:qbittorrent-team/qbittorrent-stable
sudo apt install qbittorrent -y
sudo add-apt-repository ppa:libretro/stable 
sudo apt-get update 
sudo apt-get install retroarch
sudo apt install flatpak -y
flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub org.prismlauncher.PrismLauncher -y -v
flatpak install flathub ru.linux_gaming.PortProton -y -v
flatpak install flathub com.vysp3r.ProtonPlus -y -v
flatpak install flathub com.ultimaker.cura
sudo apt remove vim -y 
sudo apt autoremove -y 
sudo apt install nano -y
sudo apt update -y
sudo apt install kmod -y
wget https://launchpad.net/~kxstudio-debian/+archive/kxstudio/+files/kxstudio-repos_11.2.0_all.deb
sudo dpkg -i kxstudio-repos_11.2.0_all.deb
sudo apt-get install lmms -y
wget https://archive.org/download/hollow-knight-1.5.78.11833-linux-drmfree/Hollow_Knight_1.5.78.11833_LinuxDRMFree.zip
unzip Hollow_Knight_1.5.78.11833_LinuxDRMFree.zip -d /mnt/chromeos/removable/devSD/hollow
sudo rm -rf Hollow_Knight_1.5.78.11833_LinuxDRMFree.zip
sudo apt-get install zenity -y
sudo apt update -y
sudo apt update -y
sudo apt upgrade -y
curl -L "https://go.microsoft.com/fwlink/?LinkID=760868" > /tmp/vscode.deb
sudo dpkg -i /tmp/vscode.deb 
sudo apt-get install -f
sudo echo -e "[Desktop Entry]\nName=VSCode\nComment=Visual Studio Code\nExec=/opt/vscode/Code\nIcon=/opt/vscode/resources/app/resources/linux/code.png\nType=Application\nVersion=1.0\nTerminal=false\nCategories=Development" > /usr/share/applications/vscode.desktop
sudo apt install libfuse2
wget https://github.com/kleineluka/burial/releases/download/release-1.5/burial_1.5.0_LINUX_amd64.AppImage
mv burial_1.5.0_LINUX_amd64.AppImage burial.AppImage
sudo apt install libopengl0 -y
chmod +x burial.AppImage
./burial.AppImage
git clone https://github.com/joedefen/crostini-kde-setup.git
bash crostini-kde-setup/kde-setup.sh
curl -L https://pokemmo.com/download_file/1/ > PokeMMO.zip
sudo unzip PokeMMO.zip /pokemmo/
unzip Pokemon_Black_Version.zip -d /home/xj439912/pokemon/
chmod +x PokeMMO.sh
sh PokeMMO.sh
unzip undertale.zip -d /home/xj439912/undertale
clear
echo Setup finished! Rebooting in 5 seconds...
sleep 5s
logout
