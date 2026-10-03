#!/bin/bash

MAIN_PATH="/mnt/4d-reconstruction-testing/"
REPO_PATH="${MAIN_PATH}4DAnyone/"

cd ${REPO_PATH}

eval "$(conda shell.bash hook)"

conda create -y -n 4danyone python=3.10
conda activate 4danyone

pip install -r requirements.txt
