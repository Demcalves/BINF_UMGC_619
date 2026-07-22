#!/usr/bin/env bash
set -eou pipefail

PROJ_DIR=$(pwd)
## enter the reference directory
cd "${PROJ_DIR}/data/reference"

# download the reference genome for bacillus subtilis from NCBI https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000009045.1/
# downloading only the GFF + GTF files
if [ ! -f "bsubtilis_genome.gtf" ]; then

    wget -w 10 https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/009/045/GCF_000009045.1_ASM904v1/GCF_000009045.1_ASM904v1_genomic.gff.gz
    wget -w 10 https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/009/045/GCF_000009045.1_ASM904v1/GCF_000009045.1_ASM904v1_genomic.gtf.gz
    
    # unpack and rename files
    gunzip GCF_000009045.1_ASM904v1_genomic.gff.gz
    gunzip GCF_000009045.1_ASM904v1_genomic.gtf.gz
    
    mv GCF_000009045.1_ASM904v1_genomic.gff bsubtilis_genome.gff
    mv GCF_000009045.1_ASM904v1_genomic.gtf bsubtilis_genome.gtf

fi
echo "reference genomes for B. Subtilis can be found in groupone/data/reference"
# reset directoy back to PROJ_DIR
cd ../..
