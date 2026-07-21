#!/usr/bin/env bash

set -eou pipefail
PROJ_DIR=$(pwd)

SRA=$1
# set directory

RAW_DATA="${PROJ_DIR}/rawdata/raw"
SRX_LIST="${PROJ_DIR}/sraToAdd.txt"
# get length of entries in SRX_LIST
SRX_DEPTH=$(grep -v "\s*$" $SRX_LIST | wc -l)
# calculate number of available threads for concurrent download
MAX_THREAD=8
THREAD_COUNT=$(($MAX_THREAD / $SRX_DEPTH))
# gather raw_data read
prefetch $SRA -O $RAW_DATA
fasterq-dump $SRA -O $RAW_DATA --split-files --threads $THREAD_COUNT # this download might be slow
