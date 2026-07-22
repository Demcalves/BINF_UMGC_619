#!/usr/bin/env bash
set -eou pipefail

PROJ_DIR=$(pwd)

SRA=$1
# set directory

RESULTS="${PROJ_DIR}/results"
RAW_DATA="${PROJ_DIR}/data/raw"
FASTP_LIST="${PROJ_DIR}/workflow_list.txt" # list of samples to run fastqc on, used for allocating resources for running multiple fastqc
# get length of entries in SRX_LIST
FASTP_DEPTH=$(grep -v "\s*$" $FASTP_LIST | wc -l)
# calculate number of available threads for concurrent download
MAX_THREAD=8
THREAD_COUNT=$(($MAX_THREAD / $FASTP_DEPTH))
# gather raw_data read
echo "Performing trimming and filtering of ${SRA}..."
fastp \
    -i "$RESULTS/qc/${SRA}_1.fastq" \
    -I "$RESULTS/qc/${SRA}_2.fastq" \
    -o "$RESULTS/trimmed/${SRA}_trimmed_R1.fastq" \
    -O "$RESULTS/trimmed/${SRA}_trimmed_R2.fastq" \
    --qualified_quality_phred 20 \
    --length_required 100 \
    --detect_adapter_for_pe \
    --thread $THREAD_COUNT \
    --html "$RESULTS/trimmed/${SRA}_fastp_report.html" \
    --json "$RESULTS/trimmed/${SRA}_fastp_report.json"

echo "fastp exit code: $?"
# quick comparison to visualize while in the command line
echo "Before: $(( $(wc -l < "$RAW_DATA/${SRA}_1.fastq") / 4 )) read pairs"
echo "After: $(( $(wc -l < "$RESULTS/trimmed/${SRA}_trimmed_R1.fastq") / 4 )) read pairs"
