#!/usr/bin/env bash
set -eou pipefail

# this is a helper script to trim down addage in the main script
LIST=$1 # this input is the Working directory such as data or 
COUNT=$2
if [ $(grep -v -E "^\s*$" $LIST | wc -l) -eq $COUNT ]; then
    echo "" > $LIST # overwrite the list if the work count equals the workflow list depth (all samples have been downloaded or process)
    echo "All fastq files in ${SRA_LIST} have been processed and can be found in ${PROJ_DIR}/results/qc"
    WORK_COUNT=0 # reset workcount variable
fi