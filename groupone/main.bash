set -euo pipefail

# run the conda_env_setup
#bash conda_env_setup.bash


PROJ_DIR=$(pwd)
#PROJ_DIR="${BASE_DIR}/groupone"
RAW_DATA="${PROJ_DIR}/rawdata/raw"
SRA_LIST="${PROJ_DIR}/sra.txt"
# get raw data using xargs
touch ${PROJ_DIR}/sraToAdd.txt

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

    RAW_DATA_SCRIPT="${PROJ_DIR}/scripts/get_rawdata.bash"
    chmod -x "${RAW_DATA_SCRIPT}"
    # this runs the get raw data script
    xargs -a "${DWND_LIST}" -P 4 -I{} bash "$RAW_DATA_SCRIPT" {}
fi
# clean up step
rm $DWND_LIST 

# Run FastQC on Gathered files in rawdata/raw
# Run FastQC on both files
while read LINE; do
    if [ ! -f "$PROJ_DIR/results/qc/${LINE}_1_fastqc.html" ]; then
        echo "Performing fastqc..."
        fastqc "$RAW_DATA/${LINE}_1.fastq" "$RAW_DATA/${LINE}_2.fastq" \
            -o "$PROJ_DIR/results/qc" -t 2
        echo "FastQC complete! Reports:"
        ls "$PROJ_DIR/results/qc"/*.html
    fi
done < $SRA_LIST
