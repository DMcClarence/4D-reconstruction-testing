#!/bin/bash

MAIN_PATH="/mnt/4d-reconstruction-testing/"
REPO_PATH="${MAIN_PATH}GVHMR/"

cd ${REPO_PATH}

eval "$(conda shell.bash hook)"

conda create -y -n gvhmr python=3.10
conda activate gvhmr

pip install numpy==1.23.5 && \
pip install -r requirements.txt && \
pip install -e .
