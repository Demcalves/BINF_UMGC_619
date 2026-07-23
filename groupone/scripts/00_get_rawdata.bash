#!/usr/bin/env bash
set -eou pipefail

PROJ_DIR=$(pwd)

SRA=$1
# set directory

RAW_DATA="${PROJ_DIR}/data/raw"
SRX_LIST="${PROJ_DIR}/sraToAdd.txt"
# get length of entries in SRX_LIST
SRX_DEPTH=$(grep -c -v -E "^\s*$" $SRX_LIST)
# calculate number of available threads for concurrent download
MAX_THREAD=8
THREAD_COUNT=$(($SRX_DEPTH > 0 ? $MAX_THREAD / $SRX_DEPTH : 1))
# gather raw_data read
prefetch "${SRA}" -O "${RAW_DATA}"
fasterq-dump "${SRA}" -O "${RAW_DATA}" --split-files --threads "${THREAD_COUNT}" # this download might be slow
