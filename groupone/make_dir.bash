set -eou pipefail
path=$(pwd)
echo "${path}"

# set directory
# Create a project directory from inside group one
mkdir -p {data/{raw,reference,index},results/{qc,trimmed,sorted,aligned,counts,de,figures}}
