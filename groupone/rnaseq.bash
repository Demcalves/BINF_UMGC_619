#!/usr/bin/env bash
set -euo pipefail



############## Step 0: Handling Arguments and Input ##############
# the main bash script is implemented with a system argument, a list of SRAs from sra.txt
SRA_LIST=$1

PROJ_DIR=$(pwd) # run within the groupone directory

if [ ! -d "data" ]; then
    bash ${PROJ_DIR}/scripts/00_make_dir.bash
fi
RAWDATA_DIR="${PROJ_DIR}/data/raw"
REF_DIR="${PROJ_DIR}/data/reference"
# Error handling for the mandatory argument
if [ -z "$SRA_LIST" ]; then
    echo "Error: No SRA list file provided."
    echo "Usage: $0 <sra_list_file> [output_label]"
    exit 1
fi

if [ ! -f "$SRA_LIST" ]; then
    echo "Error: File '$SRA_LIST' does not exist or is not a regular file."
    exit 1
fi

if [ ! -s "$SRA_LIST" ]; then
    echo "Error: File '$SRA_LIST' is empty."
    exit 1
fi

# get the number of entries in SRA_LIST
SRA_DEPTH=$(grep -v -E "^\s*$" $SRA_LIST | wc -l)

# handle the optional argument ... the user can provide an appropriate name for their output directory of the ran job
SRA_BASENAME=$(basename "$SRA_LIST")
SRA_BASENAME="${SRA_BASENAME%.*}"
DEFAULT_LABEL="${SRA_BASENAME}_$(date +%Y%m%d)"

OUTPUT_LABEL="${2:-$DEFAULT_LABEL}"
OUTPUT_LABEL=$(echo "$OUTPUT_LABEL" | tr -cd '[:alnum:]_-')

if [ -z "$OUTPUT_LABEL" ]; then
    echo "Error: output label is empty after sanitization."
    exit 1
fi

OUTPUT_DIR="${PROJ_DIR}/${OUTPUT_LABEL}"
mkdir -p "$OUTPUT_DIR"

echo "Output directory: $OUTPUT_DIR"

############## Step 1: Getting Data, References and Building Indexes ##############
# Make directories !!
# It is naively assumed that if the user does not have the data directory, 
# then the other directories are likely to be missing or not valid.


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

############## Step 2: Quality Control Processing ##############

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

############## Step 2.1 : FASTQC ##############

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
    # this runs the get fastqc script
    xargs -a "${WORKFLOW_LIST}" -P 4 -I{} bash "$FASTQC_SCRIPT" {}

    echo "FastQC complete for all test articles! Reports:"
    ls "$PROJ_DIR/results/qc"/*.html

fi

# Aggregate FASTQC reports
if [ ! -d "${PROJ_DIR}/results/multiqc/pretrim" ]; then
    # run multiqc if the directory not detected
    multiqc $PROJ_DIR/results/qc/ -o $PROJ_DIR/results/multiqc/pretrim --export
    if [ ! -d "$OUTPUT_DIR/pre_multiqc_plots" ]; then
            mkdir $OUTPUT_DIR/pre_multiqc_plots
            cp $PROJ_DIR/results/multiqc/pretrim/multiqc_plots/png/* $OUTPUT_DIR/pre_multiqc_plots
            echo "Copying PNG of multi-qc plots to $OUTPUT_DIR/pre_multiqc_plots"
    fi
else
    echo "Multi-QC reports for FastQC can be found in ${PROJ_DIR}/results/multiqc/pretrim"
    echo "PNG files for multi-qc plots are accessible from $OUTPUT_DIR/pre_multiqc_plots"
fi

# generate a Multi-QC dataframe using Pandas showing total sequences and percent duplicates for each SRR pair read
python3 scripts/01_get_fastqc_table.py $OUTPUT_DIR

############## Step 2.2 : FASTP trimming ##############
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
    # this runs the fastp script
    xargs -a "${WORKFLOW_LIST}" -P 4 -I{} bash "$FASTP_SCRIPT" {}
    echo "FastQC complete for all test articles! Reports:"
    ls "$PROJ_DIR/results/trimmed"/*.html
fi

# Summarize all Fastp reports into a FASTP_Aggregate Summary
> $OUTPUT_DIR/fastp_aggregate_summary.txt
while read line; do
    head -34 $PROJ_DIR/results/trimmed/${line}_fastp_report.json | \
    sed 's/{//g' | sed 's/}//g' | sed 's/,//g' | sed 's/\s//g' | \
    sed "s/\"summary\"/\"${line} summary\"/g" \
    >> $OUTPUT_DIR/fastp_aggregate_summary.txt
done < $SRA_LIST

# Aggregate all FastP reports from earlier using MultiQc
if [ ! -d "$PROJ_DIR/results/multiqc/posttrim" ]; then

    multiqc $PROJ_DIR/results/trimmed/ -o $PROJ_DIR/results/multiqc/posttrim --export
    if [ ! -d "$OUTPUT_DIR/post_multiqc_plots" ]; then
        # save all exported pngs to post_multiqc_plots
        mkdir $OUTPUT_DIR/post_multiqc_plots
        cp $PROJ_DIR/results/multiqc/posttrim/multiqc_plots/png/* $OUTPUT_DIR/post_multiqc_plots
        echo "Copying PNG of multi-qc plots to $OUTPUT_DIR/post_multiqc_plots"
    fi

else
    echo "Multi-QC reports for FastP can be found in ${PROJ_DIR}/results/multiqc/posttrim"
    echo "PNG files for multi-qc plots are accessible from $PROJ_DIR/$OUTPUT_DIR/post_multiqc_plots"
fi
# open the html link to the html 
# generate a report using get_multiqc_graphs
python3 scripts/02_get_multiqc_graphs.py $SRA_LIST $OUTPUT_DIR
############### Step 3: Alignment and Quantification with Salmon ##############
# Regardless of computational prowess, will default to running one alignment at a time

while read LINE; do
    echo $LINE
    if [ ! -d "$PROJ_DIR/results/counts/${LINE}" ]; then
        
        echo "Salmon Quant for ${LINE} is not complete! Adding to ${WORKFLOW_LIST} for Salmon Quant"
        if [ $(grep -v -E "^\s*$" $WORKFLOW_LIST | wc -l) -gt 0 ]; then

            echo "${LINE}" >> $WORKFLOW_LIST # append to list
        else
            echo "${LINE}" > $WORKFLOW_LIST # overwrite the previous list if there were errors just in case
        fi
    else
        # increment WORK_COUNT for each line downloaded 
        echo "Salmon Quant for ${LINE} is complete! Moving On"
    fi
done < $SRA_LIST

while read line; do
    if [ ! -d "${PROJ_DIR}/results/counts/${line}" ]; then
        echo "count information for ${line} not found, running Salmon Quant script"
        SALMON_SCRIPT="${PROJ_DIR}/scripts/03_run_salmon.bash"
        chmod -x "${SALMON_SCRIPT}"
        # these runs are serialized to increase performance
        bash ${SALMON_SCRIPT} ${line}   
    fi
done < $WORKFLOW_LIST

############### Step 4: Generate Visualization with Python ##############

# this python script will get the top genes for each SRA file in results/counts
# Then aggregate all of the values into one library that gets the top 20 
# total and top 10 total as a tsv and txt file respectively for reporting
# finally it makes a plot
TOPGENES_SCRIPT="${PROJ_DIR}/scripts/04_get_topgenes.py"
python3 ${TOPGENES_SCRIPT} ${SRA_LIST} ${OUTPUT_DIR}
# broke down the final statement below
echo "All SRA genes have been quantified. Top Genes have been aggregated"
echo "and tallied and stored in ${PROJ_DIR}/results as topgenes_aggregate.txt"
# after iterating through this create a new file using the annotations/bsub_gff_cds.txt file
> ${OUTPUT_DIR}/topgenes_aggregate_20_reference.txt
awk 'NR>1 {print $1}' ${OUTPUT_DIR}/topgenes_aggregate_20.txt | while read line; do
    grep "$line" ${PROJ_DIR}/data/annotations/bsub_gff_cds.txt >> ${OUTPUT_DIR}/topgenes_aggregate_20_reference.txt
done 

rm $WORKFLOW_LIST
