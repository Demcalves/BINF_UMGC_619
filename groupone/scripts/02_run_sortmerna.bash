#!/usr/bin/env bash
set -eou pipefail

PROJ_DIR=$(pwd)
# this step runs in following adapter and low quality read trimming to reduce bias during Salmon quant

TRIM_DIR="${PROJ_DIR}/results/trimmed" # pulling trimmed results from fastp
SORT_DIR="${PROJ_DIR}/results/sorted" # rna filtered results will go here
DB_DIR="${PROJ_DIR}/data/rnadb" # location of the rRNA database for sortmerna

SRA=$1 # SRR code

mkdir -p "${SORT_DIR}/${SRA}" # make directory for SRA subfolders

SORTRNA_LIST="${PROJ_DIR}/workflow_list.txt" # list of sra to run fastqc on, used for allocating resources for running multiple fastqc
# get length of entries in FASTQC_LIST
SORTRNA_DEPTH=$(grep -c -v -E "^\s*$" $SORTRNA_LIST)
# calculate number of available threads for concurrent processing
MAX_THREAD=8
THREAD_COUNT=$(($SORTRNA_DEPTH > 0 ? $MAX_THREAD / $SORTRNA_DEPTH : 1))

# since we have paired reads follow this format
sortmerna --ref "${DB_DIR}/smr_v4.3_default_db.fasta" \
        --reads "${TRIM_DIR}/${SRA}_trimmed_R1.fastq" \
        --reads  "${TRIM_DIR}/${SRA}_trimmed_R2.fastq" \
        --fastx --paired_in --out2 \
        --threads $THREAD_COUNT \
        --workdir "${SORT_DIR}/${SRA}" \
        --other "${SORT_DIR}/${SRA}/${SRA}_sorted"

# change all file path names to follow schema: ${SRA}_trimmed_R1_sorted.fastq for fwd and ${SRA}_trimmed_R2_sorted.fastq for rev
mv ${SORT_DIR}/${SRA}/${SRA}_sorted_fwd.fastq ${SORT_DIR}/${SRA}_trimmed_R1_sorted.fastq
mv ${SORT_DIR}/${SRA}/${SRA}_sorted_rev.fastq ${SORT_DIR}/${SRA}_trimmed_R2_sorted.fastq

# run cleanup by removing the temp files in created subdirectory
rm -rf ${SORT_DIR}/${SRA}