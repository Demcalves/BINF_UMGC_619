#!/usr/bin/env bash
set -euo pipefail

# run the conda_env_setup
#bash conda_env_setup.bash


BASE_DIR=$(pwd)
PROJ_DIR="${BASE_DIR}/groupone"
RAW_DATA="${PROJ_DIR}/rawdata/raw"
SRA_LIST="${PROJ_DIR}/sra.txt"

# get raw data using xargs
cat sraToAdd.txt
while read LINE; do
    if [ ! -d "${RAW_DATA}/$LINE" ]; then
        echo "${LINE} is not downloaded, adding to textfile for download"
        echo $LINE >> sraToAdd.txt
    else
        echo "${LINE} is already downloaded in ${RAW_DATA}"
done < sra.txt