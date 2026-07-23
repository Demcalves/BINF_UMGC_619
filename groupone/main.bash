#!/usr/bin/env bash
set -euo pipefail

# run the conda_env_setup
#bash conda_env_setup.bash

PROJ_DIR=$(pwd) # run within the groupone directory
#PROJ_DIR="${BASE_DIR}/groupone"
RAWDATA_DIR="${PROJ_DIR}/data/raw"
REF_DIR="${PROJ_DIR}/data/reference"
SRA_LIST="${PROJ_DIR}/sra.txt"

# Make directories !!
# It is naively assumed that if the user does not have the data directory, 
# then the other directories are likely to be missing or not valid.
if [ ! -d "data" ]; then
    bash ${PROJ_DIR}/make_dir.bash
fi

# get the reference genome using the following script, storing in groupone/data/reference
bash "scripts/00_get_reference.bash"

# get raw data using xargs
touch ${PROJ_DIR}/sraToAdd.txt

DWND_LIST="${PROJ_DIR}/sraToAdd.txt" # Download list, temporary file

while read LINE; do
    if [ ! -d "${RAWDATA_DIR}/${LINE}" ]; then
        echo "${LINE} is not downloaded, adding to textfile for download"
        if [ $(grep -v "\s+$" $DWND_LIST | wc -l) > 0 ]; then

            echo "${LINE}" >> $DWND_LIST
        else
            echo "${LINE}" > $DWND_LIST
        fi
    else
        echo "${LINE} is already downloaded in ${RAWDATA_DIR}"
    fi
done < $SRA_LIST

# calculate number of concurrent operations needed
# add data now with $DWND_LIST using xargs
# enable excution privelges
if [ $(grep -v -E "^\s*$" $DWND_LIST | wc -l) -gt 0 ]; then

    echo "downloading raw data"
    RAW_DATA_SCRIPT="${PROJ_DIR}/scripts/00_get_rawdata.bash"
    chmod -x "${RAW_DATA_SCRIPT}"
    # this runs the get raw data script
    xargs -a "${DWND_LIST}" -P 4 -I{} bash "$RAW_DATA_SCRIPT" {}
fi
# clean up step
rm $DWND_LIST 

# with the reference data collected, use GFF read to create the 
#transcriptome, which will also reside in the reference subdirectory
# calling this script to build the transcriptome and index with Salmon
bash "scripts/01_build_index.bash"

# For the rest of the workflow, it is naively assumed that if the FASTQC step below 
# for an expected result has not been performed, that the subsequent steps of trimming, 
# aligning and differential expression have also not been performed. The WORKFLOW_LIST
# will now hold all lines of SRR identifiers to manipulate the raw data pulled above.
# nevertheless, each step in this RNA-Seq workflow will be isolated from other steps
# so that they are at least checked to have been performed.

touch ${PROJ_DIR}/workflow_list.txt
WORKFLOW_LIST="${PROJ_DIR}/workflow_list.txt"

# Run FastQC on Gathered files in rawdata/raw
# Run FastQC on both files

while read LINE; do
    echo $LINE
    if [ ! -f "$PROJ_DIR/results/qc/${LINE}_1_fastqc.html" ]; then
        
        echo "FASTQC for ${LINE} is not complete! Adding to ${WORKFLOW_LIST} for FASTQC"
        echo $LINE >> $WORKFLOW_LIST
        
    fi
done < $SRA_LIST

if [ $(grep -v -E "^\s*$" $WORKFLOW_LIST | wc -l) -gt 0 ]; then
    
    echo "Performing fastqc..."
    FASTQC_SCRIPT="${PROJ_DIR}/scripts/01_run_fastqc.bash"
    chmod -x "${FASTQC_SCRIPT}"
    # this runs the get raw data script
    xargs -a "${WORKFLOW_LIST}" -P 4 -I{} bash "$FASTQC_SCRIPT" {}

    echo "FastQC complete for all test articles! Reports:"
    ls "$PROJ_DIR/results/qc"/*.html

fi

# separating trimming and RNA sorting steps
if [ $(grep -v -E "^\s*$" $WORKFLOW_LIST | wc -l) -gt 0 ]; then

    # Moving on to read trims, using fastp
    echo "Performing fastp trimming ..."
    FASTP_SCRIPT="${PROJ_DIR}/scripts/02_run_fastp.bash"
    chmod -x "${FASTP_SCRIPT}"
    # this runs the get raw data script
    xargs -a "${WORKFLOW_LIST}" -P 4 -I{} bash "$FASTP_SCRIPT" {}
    echo "FastQC complete for all test articles! Reports:"
    ls "$PROJ_DIR/results/trimmed"/*.html

    # move onto rna filtering with sortmerna
    echo "sorting rna reads with SortMeRNA"
    SORTRNA_SCRIPT="${PROJ_DIR}/scripts/02_run_sortmerna.bash"
    chmod -x "${SORTRNA_SCRIPT}"
    # this runs the get raw data script
    xargs -a "${WORKFLOW_LIST}" -P 4 -I{} bash "$SORTRNA_SCRIPT" {}
    echo "SortMeRNA complete for all test articles! Reports:"
    ls "$PROJ_DIR/results/sorted"/*.html
fi
