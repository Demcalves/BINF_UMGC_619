#!/usr/bin/env bash
set -eou pipefail

PROJ_DIR=$(pwd)

SRA=$1
# set directory

RAW_DATA="${PROJ_DIR}/rawdata/raw"
FASTQC_LIST="${PROJ_DIR}/workflow_list.txt" # list of sra to run fastqc on, used for allocating resources for running multiple fastqc
# get length of entries in FASTQC_LIST
FASTQC_DEPTH=$(grep -c -v -E "^\s*$" $FASTQC_LIST)
# calculate number of available threads for concurrent download
MAX_THREAD=8
THREAD_COUNT=$(($FASTQC_DEPTH > 0 ? $MAX_THREAD / $FASTQC_DEPTH : 1))
# gather raw_data read
fastqc "$RAW_DATA/${LINE}_1.fastq" "$RAW_DATA/${LINE}_2.fastq" \
            -o "$PROJ_DIR/results/qc" -t $THREAD_COUNT
