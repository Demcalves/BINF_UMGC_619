#!/usr/bin/env bash

set -eou pipefail
path=$(pwd)
echo "${path}"

SRA=$1
# set directory

PROJ_DIR="${path}/groupone"
RAW_DATA="${PROJ_DIR}/00_rawdata/raw"

# gather raw_data read
if [ ! -d "${SRA}" ]; then
    prefetch ${SRA}
    fasterq-dump ${SRA} -O ${RAW_DATA} --split-files --threads 2 # this download might be slow
fi