sudo apt update -y 
sudo apt full-upgrade -y
sudo mkdir -pm755 /etc/apt/keyrings
wget -O - https://dl.winehq.org/wine-builds/winehq.key | sudo gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key -
sudo dpkg --add-architecture i386
sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources
sudo apt update
sudo apt install --install-recommends winehq-stable -y
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install wine32 wine64 wine
nano ~/undertale.sh
chmod +x ~/undertale.sh
echo 'export PATH="$PATH:$HOME"' >> ~/.bashrc
source ~/.bashrc
sudo dpkg --add-architecture i386
sudo apt update -y
sudo apt install wine wine32 wine64 winbind -y
wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
chmod +x winetricks
sudo mv winetricks /usr/local/bin/
sudo apt update -y 
wine --version
winetricks --version
winecfg
winetricks corefonts vcrun2015
sudo apt update -y
sudo apt install innoextract unzip p7zip-full wine winetricks -y
bash gog_undertale_2.0.0.1.sh --unpack
wine ~/data/noarch/game/UNDERTALE.exe
wget https://github.com/NoRiskClient/noriskclient-launcher/releases/latest/download/NoRiskClient-Linux.deb
sudo apt install ./NoRiskClient-Linux.deb -y
sudo apt install -y qbittorrent -y
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
curl -L https://pokemmo.com/download_file/1/ > PokeMMO.zip
sudo unzip PokeMMO.zip /pokemmo/
unzip Pokemon_Black_Version.zip -d /home/xj439912/pokemon/
chmod +x PokeMMO.sh
sh PokeMMO.sh
unzip undertale.zip -d /home/xj439912/undertale
sudo apt update -y 
sudo apt upgrade -y 
sudo apt install wget tar maven -y 
wget https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.9%2B10/OpenJDK21U-jdk_x64_linux_hotspot_21.0.9_10.tar.gz
sudo mkdir -p /opt/java
sudo tar -xzf OpenJDK21U-jdk_x64_linux_hotspot_21.0.9_10.tar.gz -C /opt/java && \
sudo update-alternatives --install /usr/bin/java java /opt/java/jdk-21.0.9+10/bin/java 1 && \
sudo update-alternatives --install /usr/bin/javac javac /opt/java/jdk-21.0.9+10/bin/javac 1 && \
sudo update-alternatives --config java && \
sudo update-alternatives --config javac && \
echo 'export JAVA_HOME=/opt/java/jdk-21.0.9+10' >> ~/.bashrc && \
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> ~/.bashrc && \
source ~/.bashrc && \
java -version && \
mvn -version
wget https://github.com/cyb3rw0lf-3D/crostini-jumpstart/raw/refs/heads/main/ProjectVenom-source-1.0.0.zip
unzip ProjectVenom-source-1.0.0.zip -d /home/xj439912/project-venom
cd project-venom
mvn clean package -DskipTests
wget https://github.com/webtorrent/webtorrent-desktop/releases/download/v0.24.0/webtorrent-desktop_0.24.0_amd64.deb
sudo apt install ./webtorrent-desktop_0.24.0_amd64.deb -y
echo Setup finished! Rebooting in 5 seconds...
echo You can now also play Undertale! Execute ~/undertale.sh to start the game up!
sleep 5s
exit
