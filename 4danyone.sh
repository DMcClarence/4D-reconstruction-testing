#!/bin/bash

MAIN_PATH="/mnt/4d-reconstruction-testing/"
REPO_PATH="${MAIN_PATH}4DAnyone/"
INPUTS_PATH="${MAIN_PATH}inputs/"
OUTPUTS_PATH="${MAIN_PATH}outputs/4DAnyone/" 

cd ${REPO_PATH}

rm -rf ${OUTPUTS_PATH}$1
export PYTORCH_CUDA_ALLOC_CONF="backend:native,expandable_segments:False"
python ${REPO_PATH}inference.py --video_path "${INPUTS_PATH}$1" --output_dir "${OUTPUTS_PATH}$1" --views_per_layer 6

cd ..