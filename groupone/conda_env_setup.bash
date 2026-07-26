#!/usr/bin/env bash
set -eo pipefail

path=$(pwd)

# install conda env for a new user if local environment does not have it
if ! command -v conda &> /dev/null; then
    echo "conda not found, installing..."
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh
    bash /tmp/miniconda.sh -b -p "$HOME/miniconda3"
    rm /tmp/miniconda.sh #remove the temporary script
fi

# locat and source conda's shell function so 'conda activate' works in this script
CONDA_BASE=$(conda info --base)
source "${CONDA_BASE}/etc/profile.d/conda.sh"

# Create and activate conda environment
conda create -n groupone -y python=3.11
set +u # set unbound variable
conda activate groupone

# Install tools
conda install -c bioconda -c conda-forge -y \
    sra-tools fastqc fastp salmon gffread pandas seaborn

set -u
# Verify installations
fasterq-dump --version
fastqc --version
fastp --version
salmon --version
gffread --version
# adding python and tools for visualization
python3 --version
pandas --version
seaborn --version

echo "help files for each tool downloaded are included in the main directory of this project for reference :)"

# create helper files for reference
# sortmerna -h > 'sortmerna --help'.txt
fastqc --help > 'fastqc --help'.txt
fastp --help > 'fastp --help'.txt
gffread --help > 'gffread --help'.txt
salmon index --help > 'salmon index --help'.txt
salmon quant --help > 'salmon quant --help'.txt
prefetch --help > 'prefetch --help'.txt
fasterq-dump --help > 'fasterq-dump --help'.txt