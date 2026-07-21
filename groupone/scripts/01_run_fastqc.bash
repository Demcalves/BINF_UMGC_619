#!/usr/bin/env bash

set -eou pipefail
PROJ_DIR=$(pwd)

SRA=$1
# set directory

RAW_DATA="${PROJ_DIR}/rawdata/raw"
SRX_LIST="${PROJ_DIR}/sraToAdd.txt" # list of sra to run fastqc on, used for allocating resources for running multiple fastqc
# get length of entries in SRX_LIST
SRX_DEPTH=$(grep -v "\s*$" $SRX_LIST | wc -l)
# calculate number of available threads for concurrent download
MAX_THREAD=8
THREAD_COUNT=$(($MAX_THREAD / $SRX_DEPTH))
# gather raw_data read
fastqc "$RAW_DATA/${LINE}_1.fastq" "$RAW_DATA/${LINE}_2.fastq" \
            -o "$PROJ_DIR/results/qc" -t $THREAD_COUNT
