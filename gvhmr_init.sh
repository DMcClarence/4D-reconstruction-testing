#!/bin/bash

MAIN_PATH="/mnt/4d-reconstruction-testing/"
REPO_PATH="${MAIN_PATH}GVHMR/"

cd ${REPO_PATH}

eval "$(conda shell.bash hook)"

conda create -y -n gvhmr python=3.10
conda activate gvhmr

apt-get update && \
apt install -y -qq aria2 && \
aria2c --console-log-level=error -c -x 16 -s 16 \
    -k 1M https://huggingface.co/camenduru/SMPLer-X/resolve/main/SMPL_NEUTRAL.pkl \
    -d ${REPO_PATH}inputs/checkpoints/body_models/smpl -o SMPL_NEUTRAL.pkl && \
aria2c --console-log-level=error -c -x 16 -s 16 \
    -k 1M https://huggingface.co/camenduru/SMPLer-X/resolve/main/SMPLX_NEUTRAL.npz \
    -d ${REPO_PATH}inputs/checkpoints/body_models/smplx -o SMPLX_NEUTRAL.npz && \
aria2c --console-log-level=error -c -x 16 -s 16 \
    -k 1M https://huggingface.co/camenduru/GVHMR/resolve/main/dpvo/dpvo.pth \
    -d ${REPO_PATH}inputs/checkpoints/dpvo -o dpvo.pth && \
aria2c --console-log-level=error -c -x 16 -s 16 \
    -k 1M https://huggingface.co/camenduru/GVHMR/resolve/main/gvhmr/gvhmr_siga24_release.ckpt \
    -d ${REPO_PATH}inputs/checkpoints/gvhmr -o gvhmr_siga24_release.ckpt && \
aria2c --console-log-level=error -c -x 16 -s 16 \
    -k 1M https://huggingface.co/camenduru/GVHMR/resolve/main/hmr2/epoch%3D10-step%3D25000.ckpt \
    -d ${REPO_PATH}inputs/checkpoints/hmr2 -o epoch=10-step=25000.ckpt && \
aria2c --console-log-level=error -c -x 16 -s 16 \
    -k 1M https://huggingface.co/camenduru/GVHMR/resolve/main/vitpose/vitpose-h-multi-coco.pth \
    -d ${REPO_PATH}inputs/checkpoints/vitpose -o vitpose-h-multi-coco.pth && \
aria2c --console-log-level=error -c -x 16 -s 16 \
    -k 1M https://huggingface.co/camenduru/GVHMR/resolve/main/yolo/yolov8x.pt \
    -d ${REPO_PATH}inputs/checkpoints/yolo -o yolov8x.pt

pip install numpy==1.23.5 && \
pip install -r requirements.txt && \
pip install -e .
