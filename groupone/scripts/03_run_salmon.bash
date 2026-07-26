set -eou pipefail

PROJ_DIR=$(pwd)
IDX_DIR="${PROJ_DIR}/data/index"
RESULTS_DIR="${PROJ_DIR}/results"

SRA=$1
echo "Running Salmon Alignment and Quant"


# Check if the sortmerna file is present, if not default to trimmed fastp reads
# check if the output directory already exists. 
if [ ! -d "${RESULTS_DIR}/counts/${SRA}" ]; then
    if [ -f "${RESULTS_DIR}/sorted/${SRA}_trimmed_R1_sorted.fastq" ]; then
        echo "RNA sorted trimmed reads for ${SRA} were found. Using these files for Salmon Quant"
        salmon quant --index $IDX_DIR/bsub_transcripts_index \
                    -1 $RESULTS_DIR/sorted/${SRA}_trimmed_R1_sorted.fastq \
                    -2 $RESULTS_DIR/sorted/${SRA}_trimmed_R2_sorted.fastq \
                    -o $RESULTS_DIR/counts/${SRA}

    elif [ -f "${RESULTS_DIR}/trimmed/${SRA}_trimmed_R1.fastq" ]; then
        echo "RNA sorted trimmed reads for ${SRA} were not found..."
        echo "Falling back to using ${SRA} trimmed reads for Salmon Quant"
        salmon quant --index $IDX_DIR/bsub_transcripts_index \
                    -1 $RESULTS_DIR/trimmed/${SRA}_trimmed_R1.fastq \
                    -2 $RESULTS_DIR/trimmed/${SRA}_trimmed_R2.fastq \
                    -o $RESULTS_DIR/counts/${SRA}

    else # failsafe incase sortmerna and fastp files not found

        echo "Both trimmed and sorted trimmed reads for ${SRA} were not found. Aborting Salmon Quant for ${SRA}"
    fi
else
    echo "Salmon Quant Output directory detected for ${SRA} at ${RESULTS_DIR}/count/${SRA}_transcripts_quant"
fi

# run this line to extract the BSU and tmp values from quant.sf
grep 'gene-BSU_' ${RESULTS_DIR}/counts/${SRA}/quant.sf | awk '{print $1, $4}' > "${RESULTS_DIR}/counts/${SRA}/${SRA}_cds_quant.txt"