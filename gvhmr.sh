#!/bin/bash

MAIN_PATH="/mnt/4d-reconstruction-testing/"
REPO_PATH="${MAIN_PATH}GVHMR/"
INPUTS_PATH="${MAIN_PATH}inputs/"
OUTPUTS_PATH="${MAIN_PATH}outputs/GVHMR/" 

cd ${REPO_PATH}
python ${REPO_PATH}tools/demo/demo.py --video=${INPUTS_PATH}$1 --output_root=${OUTPUTS_PATH} -s