#!/bin/bash

# Initialize pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

eval "$(pyenv init -)"

# Activate the desired Python version
pyenv shell insiders-clustering

# Timestamp
dateTimeExecution=$(date +'%Y%m%d_%H%M%S')

# Project root
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Execute Papermill
papermill \
    "$ROOT_DIR/src/models/c10_lr_deploy.ipynb" \
    "$ROOT_DIR/reports/c10_lr_deploy_${dateTimeExecution}.ipynb"