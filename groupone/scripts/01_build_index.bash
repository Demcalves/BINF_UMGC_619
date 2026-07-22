#!/usr/bin/env bash
set -eou pipefail

# following an index building workflow for Salmon 
# https://bioinformatics-core-shared-training.github.io/Bulk_RNAseq_Course_2021/Markdowns/05_Quantification_with_Salmon_practical.html#:~:text=Indexing%20the%20transcriptome%20for%20Salmon,transcriptome%20rather%20than%20the%20genome.
# and https://salmon.readthedocs.io/en/latest/salmon.html

PROJ_DIR=$(pwd)
REF_DIR="${PROJ_DIR}/data/reference"
IDX_DIR="${PROJ_DIR}/data/index"

# make transcriptome file with gffread, stored in data/ref
if [ ! -f "${REF_DIR}/bsubtilis_transcriptome.fa" ]; then
    echo "B. subtilis transcriptome not found, building transcriptome with gffread!"
    gffread "${REF_DIR}/bsubtilis_genome.gff" -g "${REF_DIR}/bsubtilis_genome.fna" -w "${REF_DIR}/bsubtilis_transcriptome.fa"
fi
echo "B. subtilis transcriptome is present in the reference directory (${REF_DIR})"

# now build the index and store it in data/index
if [ ! -f "${IDX_DIR}/bsub_transcripts_index" ]; then
    # check if all of the necessary files for index building are present for Salmon.
    # For a decoys.txt, first create a new concatenated file of the genome and transcriptome
    # to make a "gentrome", which is really the transcripts with the decoys in there
    cat "${REF_DIR}/bsubtilis_transcriptome.fa" "${REF_DIR}/bsubtilis_genome.fna" > "${REF_DIR}/bsubtilis_gentrome.fa"
    
    # next we would need a FASTA index from the genome to act as a "decoy" which could be produced 
    # with some text search and stream editing along the bsubtilis.fna file such as the following
    #grep ">" bsubtilis.fna | sed 's/>//' > decoys.txt
    
    # however, gffread already provides a fasta index file when it generated the transcriptome :)
    # so that can be used as the decoy
    awk '{print $1}' "${REF_DIR}/bsubtilis_genome.fna.fai" > "${IDX_DIR}/decoys.txt"

    # build the salmon index and store it in data/index
    salmon index -t "${REF_DIR}/bsubtilis_gentrome.fa" \
                -i "${IDX_DIR}/bsub_transcripts_index" \
                --decoys "${IDX_DIR}/decoys.txt" \
                -k 31 # kmer size, this is already 31 as a default but this can be adjusted if necessary
fi
echo "B. subtilis index is complete and is stored in ${IDX_DIR}"
