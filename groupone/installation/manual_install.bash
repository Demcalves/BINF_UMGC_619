# first install python
sudo apt-get update
sudo apt-get install -y python3 python3-venv python3-dev
python3 --version

# Install pip for other binary downloads like for multiqc or python based tools
sudo apt-get update
sudo apt-get install -y python3-pip
pip3 --version 

cd /opt
wget https://ftp-trace.ncbi.nlm.nih.gov/sra-pub/sdk/current/sratoolkit.current-ubuntu64.tar.gz
tar -xzf sratoolkit.current-ubuntu64.tar.gz
export PATH="/opt/sratoolkit.*-ubuntu64/bin:$PATH"   # add to ~/.bashrc to persist
prefetch --version   # confirm it works

sudo apt-get update
sudo apt-get install -y default-jre unzip
cd /opt
wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.12.1.zip
unzip fastqc_v0.12.1.zip
chmod +x FastQC/fastqc
export PATH="/opt/FastQC:$PATH"   # add to ~/.bashrc
fastqc --version

sudo mkdir -p /opt/fastp
sudo wget http://opengene.org/fastp/fastp -O /opt/fastp/fastp
sudo chmod +x /opt/fastp/fastp
export PATH="/opt/fastp:$PATH"   # add to ~/.bashrc
fastp --version

bash
pip3 install multiqc --break-system-packages
multiqc --version

cd /opt
wget https://github.com/COMBINE-lab/salmon/releases/download/v1.10.0/salmon-1.10.0_linux_x86_64.tar.gz
tar -xzf salmon-1.10.0_linux_x86_64.tar.gz
export PATH="/opt/salmon-1.10.0_linux_x86_64/bin:$PATH"   # add to ~/.bashrc
salmon --version

cd /opt
wget https://github.com/gpertea/gffread/releases/download/v0.12.7/gffread-0.12.7.Linux_x86_64.tar.gz
tar -xzf gffread-0.12.7.Linux_x86_64.tar.gz
export PATH="/opt/gffread-0.12.7.Linux_x86_64:$PATH"   # add to ~/.bashrc
gffread --version

pip3 install pandas seaborn tabulate --break-system-packages
python3 -c "import pandas, seaborn; print(pandas.__version__, seaborn.__version__)"

# move the path of all of the tools
cat >> ~/.bashrc << 'EOF'
export PATH="/opt/sratoolkit.*-ubuntu64/bin:$PATH"
export PATH="/opt/FastQC:$PATH"
export PATH="/opt/fastp:$PATH"
export PATH="/opt/salmon-latest_linux_x86_64/bin:$PATH"
export PATH="/opt/gffread-0.12.7.Linux_x86_64:$PATH"
EOF
source ~/.bashrc
