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
wget https://cdn.akamai.steamstatic.com/client/installer/steam.deb
sudo apt install ./steam.deb -y
sudo apt install flatpak -y
flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.ultimaker.cura -y
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
sudo apt update -y
sudo apt upgrade -y
curl -L "https://go.microsoft.com/fwlink/?LinkID=760868" > /tmp/vscode.deb
sudo dpkg -i /tmp/vscode.deb 
sudo apt-get install -f
wget https://download1654.mediafire.com/jdai2nq84ahg2hrbcG-MWIBH30P0SAuDH1pQcGaCoHXlZFWzsXLfgb9vYac6QfMyFNKTjmktQJPqxlWffzk7hUMic_KIHu8YFL8xYUHt0zszdxFG0yOYHRHDErIPQR0wFCSmhfIQcswCTqMUywgMOhbhrQT8p-nqnrnsv_5_0VFgvg/eye8shb5mo3v5zd/Celeste_v1.4.zip
mv Celeste_v1.4.zip celeste.zip
mkdir celeste
unzip celeste.zip -d /home/infernobook/celeste
sudo rm -rf celeste.zip
clear
