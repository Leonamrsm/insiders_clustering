# variable
dateTimeExecution=$(date +'%Y%m%d_%H%M%S')

# path# Find project root (directory containing this script)
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

papermill \
    "$ROOT_DIR/src/models/c10_lr_deploy.ipynb" \
    "$ROOT_DIR/reports/c10_lr_deploy_${dateTimeExecution}.ipynb"
