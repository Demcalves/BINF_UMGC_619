#!/usr/bin/env bash
set -euo pipefail

# run the conda_env_setup
#bash conda_env_setup.bash

PROJ_DIR=$(pwd) # run within the groupone directory
#PROJ_DIR="${BASE_DIR}/groupone"
RAWDATA_DIR="${PROJ_DIR}/data/raw"
REF_DIR="${PROJ_DIR}/data/reference"
SRA_LIST="${PROJ_DIR}/sra.txt"
SRA_DEPTH=$(grep -v -E "^\s*$" $SRA_LIST | wc -l)

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
DWND_COUNT=0
while read LINE; do
    if [ ! -f "${RAWDATA_DIR}/${LINE}_1.fastq" ]; then
        echo "Raw Data files for ${LINE} could not be found, adding to textfile for download"
        if [ $(grep -v "\s+$" $DWND_LIST | wc -l) -gt 0 ]; then

            echo "${LINE}" >> $DWND_LIST # append to list
        else
            echo "${LINE}" > $DWND_LIST # overwrite list
        fi
    else
        echo "Raw Data files for ${LINE} is already downloaded in ${RAWDATA_DIR}"
        DWND_COUNT=$(($DWND_COUNT + 1))
    fi
done < $SRA_LIST

if [ $DWND_COUNT -eq $SRA_DEPTH ]; then
    echo "all samples have been downloaded already! moving onto the next step"
    echo "" > $DWND_LIST # reset the file in case crash
else
    # DWND_COUNT and DWND_DEPTH do not equal each other, thus there are exist some lines in DWND_DEPTH that have not been processed
    # calculate number of concurrent operations needed
    # add data now with $DWND_LIST using xargs
    # enable excution privelges
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
WORK_COUNT=0 

# figure out which FASTQC files, if ran once are done
while read LINE; do
    echo $LINE
    if [ ! -f "$PROJ_DIR/results/qc/${LINE}_1_fastqc.html" ]; then
        
        echo "FASTQC for ${LINE} is not complete! Adding to ${WORKFLOW_LIST} for FASTQC"
        if [ $(grep -v -E "^\s*$" $WORKFLOW_LIST | wc -l) -gt 0 ]; then

            echo "${LINE}" >> $WORKFLOW_LIST # append to list
        else
            echo "${LINE}" > $WORKFLOW_LIST # overwrite the previous list if there were errors just in case
        fi
    else
        # increment WORK_COUNT for each line downloaded 
        echo "FASTQC for ${LINE} is complete! Incrementing count tracker for FASTQC"
        WORK_COUNT=$(($WORK_COUNT + 1))
    fi
done < $SRA_LIST

# decide if FASTQC is needed
if [ $WORK_COUNT -eq $SRA_DEPTH ]; then
    echo "All fastq files in ${SRA_LIST} have been processed and can be found in ${PROJ_DIR}/results/qc"
    echo "" > $WORKFLOW_LIST # overwrite the list if the work count equals the workflow list depth (all samples have been downloaded or process)
    WORK_COUNT=0 # reset workcount variable

else
    echo "Performing fastqc..."
    FASTQC_SCRIPT="${PROJ_DIR}/scripts/01_run_fastqc.bash"
    chmod -x "${FASTQC_SCRIPT}"
    # this runs the get raw data script
    xargs -a "${WORKFLOW_LIST}" -P 4 -I{} bash "$FASTQC_SCRIPT" {}

    echo "FastQC complete for all test articles! Reports:"
    ls "$PROJ_DIR/results/qc"/*.html

fi

# Fastp logic, similar logic as above
while read LINE; do
    echo $LINE
    if [ ! -f "$PROJ_DIR/results/trimmed/${LINE}_trimmed_R1.fastq" ]; then

        echo "FASTP for ${LINE} is not complete! Adding to ${WORKFLOW_LIST} for FASTQC"
        if [ $(grep -v -E "^\s*$" $WORKFLOW_LIST | wc -l) -gt 0 ]; then

            echo "${LINE}" >> $WORKFLOW_LIST # append to list
        else
            echo "${LINE}" > $WORKFLOW_LIST # overwrite the previous list if there were errors just in case
        fi
    else
        # increment WORK_COUNT for each line downloaded 
        echo "FASTP for ${LINE} is complete! Incrementing count tracker for FASTQC"
        WORK_COUNT=$(($WORK_COUNT + 1))
    fi
done < $SRA_LIST

# Control block for running FASTP Script

if [ $WORK_COUNT -eq $SRA_DEPTH ]; then
    echo "All FASTP files in ${SRA_LIST} have been processed and can be found in ${PROJ_DIR}/results/trimmed"
    echo "" > $WORKFLOW_LIST # overwrite the list if the work count equals the workflow list depth (all samples have been downloaded or process)
    WORK_COUNT=0 # reset workcount variable

# execute the script if the work_count does not equal the workflow_depth list
else 
    # Moving on to read trims, using fastp
    echo "Performing fastp trimming ..."
    FASTP_SCRIPT="${PROJ_DIR}/scripts/02_run_fastp.bash"
    chmod -x "${FASTP_SCRIPT}"
    # this runs the get raw data script
    xargs -a "${WORKFLOW_LIST}" -P 4 -I{} bash "$FASTP_SCRIPT" {}
    echo "FastQC complete for all test articles! Reports:"
    ls "$PROJ_DIR/results/trimmed"/*.html
fi

# sortmerna logic 
while read LINE; do
    echo $LINE
    if [ ! -f "$PROJ_DIR/results/sorted/${LINE}_trimmed_sorted_r1.fastq" ]; then

        echo "SortMeRNA for ${LINE} is not complete! Adding to ${WORKFLOW_LIST} for SortMeRNA"
        if [ $(grep -v -E "^\s*$" $WORKFLOW_LIST | wc -l) -gt 0 ]; then

            echo "${LINE}" >> $WORKFLOW_LIST # append to list
        else
            echo "${LINE}" > $WORKFLOW_LIST # overwrite the previous list if there were errors just in case
        fi
    else
        # increment WORK_COUNT for each line downloaded 
        echo "SortMeRNA for ${LINE} is complete! Incrementing count tracker for SortMeRNA"
        WORK_COUNT=$(($WORK_COUNT + 1))
    fi
done < $SRA_LIST

if [ $WORK_COUNT -eq $SRA_DEPTH ]; then
    echo "All SortMeRNA files in ${SRA_LIST} have been processed and can be found in ${PROJ_DIR}/results/sorted"
    echo "" > $WORKFLOW_LIST # overwrite the list if the work count equals the workflow list depth (all samples have been downloaded or process)
    WORK_COUNT=0 # reset workcount variable

# execute the script if the work_count does not equal the workflow_depth list
else 
    # move onto rna filtering with sortmerna
    echo "sorting rna reads with SortMeRNA"
    SORTRNA_SCRIPT="${PROJ_DIR}/scripts/02_run_sortmerna.bash"
    chmod -x "${SORTRNA_SCRIPT}"
    # this runs the get raw data script
    xargs -a "${WORKFLOW_LIST}" -P 4 -I{} bash "$SORTRNA_SCRIPT" {}
    echo "SortMeRNA complete for all test articles! Reports:"
    ls "$PROJ_DIR/results/sorted"/*.html
fi

rm $WORKFLOW_LIST