#!/usr/bin/env bash
set -eou pipefail

PROJ_DIR=$(pwd)
# this step runs in following adapter and low quality read trimming to reduce bias during Salmon quant

TRIM_DIR="${PROJ_DIR}/results/trimmed"
SORT_DIR="${PROJ_DIR}/results/sorted" # rna filtered results will go here

SRA=$1

SORTRNA_LIST="${PROJ_DIR}/workflow_list.txt" # list of sra to run fastqc on, used for allocating resources for running multiple fastqc
# get length of entries in FASTQC_LIST
SORTRNA_DEPTH=$(grep -v "\s*$" $SORTRNA_LIST | wc -l)
# calculate number of available threads for concurrent processing
MAX_THREAD=8
THREAD_COUNT=$(($MAX_THREAD / $SORTRNA_DEPTH))

# since we have paired reads follow this format
sortmerna --ref "${TRIM_DIR}/${SRA}_trimmed_R1.fastq" \
        --ref "${TRIM_DIR}/${SRA}_trimmed_R2.fastq" \
        --reads "${SORT_DIR}/${SRA}_trimmed_sorted_r1.fastq" \
        --reads "${SORT_DIR}/${SRA}_trimmed_sorted_r2.fastq"
