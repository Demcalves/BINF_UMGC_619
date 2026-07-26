set -eou pipefail
PROJ_DIR=$(pwd)

# set directory
# Create a project directory from inside group one
mkdir -p {figures,data/{raw,reference,index,annotations},results/{qc,trimmed,aligned,counts}}
