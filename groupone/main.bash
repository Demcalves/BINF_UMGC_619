#!/usr/bin/env bash
set -euo pipefail

# run the conda_env_setup
#bash conda_env_setup.bash


BASE_DIR=$(pwd)
PROJ_DIR="${BASE_DIR}/groupone"
RAW_DATA="${PROJ_DIR}/rawdata/raw"
SRA_LIST="${PROJ_DIR}/sra.tsv"
# get raw data using xargs
touch ${PROJ_DIR}/sraToAdd.txt
touch "${PROJ_DIR}/srr.txt"
awk '{print $1}' $SRA_LIST >> ${PROJ_DIR}/srr.txt
SRR_LIST="${PROJ_DIR}/srr.txt"
SRX_LIST="${PROJ_DIR}/sraToAdd.txt"

while read LINE; do
    if [ ! -d "${RAW_DATA}/${LINE}" ]; then
        echo "${LINE} is not downloaded, adding to textfile for download"
        awk -v line="$LINE" '$1 == line {print $1}' "$SRA_LIST" >> $SRX_LIST
    else
        echo "${LINE} is already downloaded in ${RAW_DATA}"
    fi
done < $SRR_LIST
# clean up
# $SRX_LIST
rm $SRR_LIST

# calculate number of concurrent operations needed
# add data now with $SRX_LIST using xargs
# enable excution privelges
RAW_DATA_SCRIPT="${PROJ_DIR}/scripts/get_rawdata.bash"
chmod -x "${RAW_DATA_SCRIPT}"
xargs -a "${SRX_LIST}" -P 4 -I{} bash "$RAW_DATA_SCRIPT" {}
rm $SRX_LIST 