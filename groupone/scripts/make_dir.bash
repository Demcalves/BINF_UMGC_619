set -eou pipefail
path=$(pwd)
echo "${path}"

# set directory
# Create a project directory
if [ ! -d "groupone" ]; then
    mkdir -p groupone/{rawdata/{raw,reference},results/{qc,trimmed,aligned,counts,de,figures},scripts}
fi