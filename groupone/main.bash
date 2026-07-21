#!/usr/bin/env bash
set -euo pipefail

# run the conda_env_setup
#bash conda_env_setup.bash


PROJ_DIR=$(pwd)
#PROJ_DIR="${BASE_DIR}/groupone"
RAW_DATA="${PROJ_DIR}/rawdata/raw"
SRA_LIST="${PROJ_DIR}/sra.txt"
# get raw data using xargs
touch ${PROJ_DIR}/sraToAdd.txt
touch ${PROJ_DIR}/srr.txt

DWND_LIST="${PROJ_DIR}/sraToAdd.txt" # Download list, temporary file

while read LINE; do
    if [ ! -d "${RAW_DATA}/${LINE}" ]; then
        echo "${LINE} is not downloaded, adding to textfile for download"
        cat $LINE >> $DWND_LIST
    else
        echo "${LINE} is already downloaded in ${RAW_DATA}"
    fi
done < $SRA_LIST


# calculate number of concurrent operations needed
# add data now with $DWND_LIST using xargs
# enable excution privelges
if [ $(grep -v "\s+$" $DWND_LIST) > 0 ]; then

    RAW_DATA_SCRIPT="${PROJ_DIR}/scripts/00_get_rawdata.bash"
    chmod -x "${RAW_DATA_SCRIPT}"
    # this runs the get raw data script
    xargs -a "${DWND_LIST}" -P 4 -I{} bash "$RAW_DATA_SCRIPT" {}
fi
# clean up step
rm $DWND_LIST 


touch ${PROJ_DIR}/fastqc_list.txt
FASTQC_LIST="${PROJ_DIR}/fastqc_list.txt"

# Run FastQC on Gathered files in rawdata/raw
# Run FastQC on both files
while read LINE; do
    echo $LINE
    if [ ! -f "$PROJ_DIR/results/qc/${LINE}_1_fastqc.html" ]; then
        
        echo "FASTQC for ${LINE} is not complete! Adding to ${FASTQC_LIST} for FASTQC"
        cat $LINE >> $FASTQC_LIST
        
    fi
done < $SRA_LIST

if [ $(grep -v "\s+$" $FASTQC_LIST) > 0 ]; then
    echo "Performing fastqc..."
    FASTQC_SCRIPT="${PROJ_DIR}/scripts/01_run_fastqc.bash"
    chmod -x "${FASTQC_SCRIPT}"
    # this runs the get raw data script
    xargs -a "${FASTQC_LIST}" -P 4 -I{} bash "$FASTQC_SCRIPT" {}
fi

echo "FastQC complete for all test articles! Reports:"
ls "$PROJ_DIR/results/qc"/*.html

