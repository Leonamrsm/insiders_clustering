#!/bin/bash

# Timestamp
dateTimeExecution=$(date +'%Y%m%d_%H%M%S')

# Project paths
ROOT_DIR="/home/ubuntu/insiders_clustering"
PYENV_BIN="/home/ubuntu/.pyenv/versions/3.11.14/envs/insiders-clustering/bin"

# Set project working directory
cd "$ROOT_DIR"

echo "Pipeline started at $(date)"

"$PYENV_BIN/papermill" \
    "$ROOT_DIR/src/models/c10_lr_deploy.ipynb" \
    "$ROOT_DIR/reports/c10_lr_deploy_${dateTimeExecution}.ipynb"

echo "Pipeline finished successfully at $(date)"