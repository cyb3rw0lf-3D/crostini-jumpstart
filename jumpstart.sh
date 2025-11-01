sudo apt update -y 
sudo apt full-upgrade -y
sudo mkdir -pm755 /etc/apt/keyrings
wget -O - https://dl.winehq.org/wine-builds/winehq.key | sudo gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key -
sudo dpkg --add-architecture i386
sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources
sudo apt update
sudo apt install --install-recommends winehq-stable -y
sudo apt update -y 
sudo apt install -y qbittorrent
sudo apt install retroarch -y
sudo apt install flatpak -y
bash -ci "$(wget -qO - 'https://shlink.makedeb.org/install')"
wget -qO - 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | sudo tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg 1> /dev/null
echo "deb [arch=all,$(dpkg --print-architecture) signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr $(lsb_release -cs)" | sudo tee /etc/apt/sources.list.d/prebuilt-mpr.list
sudo apt update -y
sudo apt install prismlauncher -y
flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub ru.linux_gaming.PortProton -y
flatpak install flathub ru.linux_gaming.PortProton -y
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
sudo apt install libopengl0 -y
git clone https://github.com/joedefen/crostini-kde-setup.git
bash crostini-kde-setup/kde-setup.sh
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
clear
echo Setup finished! Rebooting in 5 seconds...
sleep 5s
logout
