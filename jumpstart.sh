sudo apt update -y 
sudo apt full-upgrade -y
sudo mkdir -pm755 /etc/apt/keyrings
wget -O - https://dl.winehq.org/wine-builds/winehq.key | sudo gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key -
sudo dpkg --add-architecture i386
sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources
sudo apt update
sudo apt install --install-recommends winehq-stable -y
wget https://github.com/cyb3rw0lf-3D/crostini-jumpstart/raw/refs/heads/main/atlauncher-1.4-1.deb
sudo apt install ./atlauncher-1.4-1.deb -y
sudo apt install -y qbittorrent -y
wget https://www.crossftp.com/crossftp_1.99.9.deb
sudo apt install ./crossftp_1.99.9.deb -y
sudo apt install flatpak -y
flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.ultimaker.cura -y
flatpak install flathub so.libdb.dissent -y
flatpak install flathub org.olivevideoeditor.Olive -y
sudo apt remove vim -y 
sudo apt autoremove -y 
sudo apt install nano -y
sudo apt update -y
sudo apt install kmod -y
wget https://launchpad.net/~kxstudio-debian/+archive/kxstudio/+files/kxstudio-repos_11.2.0_all.deb
sudo dpkg -i kxstudio-repos_11.2.0_all.deb
sudo apt-get install lmms -y
sudo apt update
wget https://archive.org/download/hollow-knight-1.5.78.11833-linux-drmfree/Hollow_Knight_1.5.78.11833_LinuxDRMFree.zip
unzip Hollow_Knight_1.5.78.11833_LinuxDRMFree.zip -d /mnt/chromeos/removable/devSD/hollow
sudo rm -rf Hollow_Knight_1.5.78.11833_LinuxDRMFree.zip
sudo apt-get install zenity -y
wget 
sudo apt update -y
sudo apt upgrade -y
curl -L "https://go.microsoft.com/fwlink/?LinkID=760868" > /tmp/vscode.deb
sudo dpkg -i /tmp/vscode.deb 
sudo apt-get install -f
sudo sh -c 'echo "[Desktop Entry]
Name=Visual Studio Code
Comment=Code Editing. Redefined.
Exec=/usr/share/code/code --no-sandbox --unity-launch %F
Icon=com.visualstudio.code
Type=Application
StartupNotify=false
StartupWMClass=Code
Categories=TextEditor;Development;IDE;" > /usr/share/applications/vscode.desktop'
sudo apt update
sudo apt install nodejs npm -y
wget https://download1654.mediafire.com/n4inhziymkqgfOBfAAMs9Y-Mn73WcYH0UkCnJzPJFt4IhstA0qUcNVxSrdVJSGqr5Gg6P_byfQPaekaBk73i4h8fDObRbfA53Nzy2sW4h_I8wZhQIbJz4zvAxTEESfc7vU9ZwgBaldX98lQL4HqjTQzZ03RFzlLr6U0esT0dPvOL/eye8shb5mo3v5zd/Celeste_%28v1.4.0.0%29_%5BLinux%5D+%28extract.me%29.zip
mv Celeste_(v1.4.0.0)_[Linux]_(extract.me).zip celeste.zip
mkdir celeste
unzip celeste.zip -d /home/infernobook/celeste
clear
node -v
npm -v
sh -c "$(curl -fsSL https://raw.githubusercontent.com/cyb3rw0lf-3D/crostini-jumpstart/refs/heads/main/build_celeste.sh)"
exit
