# making a directory to handle all tools
cd /opt

# first install python, sudo apt versions are a behind compared to anaconda's repository
echo "installing python3 and pip3"
sudo apt-get update
sudo apt-get install -y python3
python3 --version # this sudo apt function at least gets python >= 3.11

# Install pip for other binary downloads like for multiqc or python based tools
sudo apt-get install -y python3-pip
pip3 --version 

# pause between installations to give user an opportunity to monitor
sleep 5s

# Installing SRA-Tools. Code snippet below follows instructions from NCBI https://github.com/ncbi/sra-tools/wiki/01.-Downloading-SRA-Toolkit
# install perl and dependencies
sudo apt-get --quiet install --yes libxml-libxml-perl
echo "installing sra toolkit to /usr/local/ncbi"

sudo rm -rf .ncbi /usr/local/ncbi /etc/ncbi /etc/profile.d/sra-tools* # remove old install if any
wget https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/3.4.1/sratoolkit.3.4.1-ubuntu64.tar.gz
sudo tar -xzf /opt/sratoolkit.3.4.1-ubuntu64.tar.gzz # unzips to salmon-latest_linux_x86_64
sudo mv salmon-latest_linux_x86_64 sratoolkit-3.4.1 # rename the version to a different name
export PATH="/opt/sratoolkit-3.4.1/bin:$PATH"   # add to ~/.bashrc
sudo vdbconfig --interactive # the user will need to confirm. Default parameters for NCBI sra-tools is suffice
prefetch --version   # confirm it works
fasterq-dump --version

# fastqc installation block // defaulting to sudo apt-get install
sleep 5s
echo "Preparing to install FastQc version 0.11.9 and JDK 11 binaries for tool function from Debian"
sudo apt-get install fastqc -y
fastqc --version

# fastp installation block
sleep 5s
echo "Preparing to install fastp version 0.20.1 from Debian"
sudo apt-get install fastp -y
fastp --version

# installation block for Salmon
sleep 5s
echo "Preparing to install Salmon from COMBINE lab, version 2.3.4"
sudo wget https://github.com/COMBINE-lab/salmon/releases/download/v2.3.4/salmon-cli-x86_64-unknown-linux-gnu.tar.xz 
sudo tar -xf salmon-cli-x86_64-unknown-linux-gnu.tar.xz # unzips to salmon-latest_linux_x86_64
sudo mv salmon-latest_linux_x86_64 salmon-2.3.4
export PATH="/opt/salmon-2.3.4:$PATH"   # add to ~/.bashrc
salmon --version

# installation block for gffread
sleep 5
echo "Preparing to install gffread version 0.12.7 from Debian"
sleep 5s
echo "Preparing to install gffread version 0.11.9 and JDK 11 binaries for tool function"
sudo apt-get install gffread -y
gffread --version

sleep 5
echo "Preparing to install additional python tools: multiqc pandas seaborn tabulate"
pip3 install multiqc pandas seaborn tabulate --break-system-packages
python3 -c "import pandas, seaborn; print(pandas.__version__, seaborn.__version__)"

# move the path of all of the tools installed manually without pip or debian
cat >> ~/.bashrc << 'EOF'
export PATH="/opt/sratoolkit-3.4.1/bin:$PATH"
export PATH="/opt/salmon-2.3.4/bin:$PATH"
export PATH="/opt/gffread-0.12.7:$PATH"
EOF
source ~/.bashrc
