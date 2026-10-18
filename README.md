# 4D-reconstruction-testing

## Clone the Repository
1. `git clone https://github.com/DMcClarence/4D-reconstruction-testing.git`
2. `cd 4D-reconstruction-testing`
3. `git submodule update --init GVHMR`
4. `git submodule update --init 4DAnyone`
5. `cd 4DAnyone`
6. `git submodule update --init third_party/GVHMR`
7. `cd ..`
8. For WHAM: `git submodule update --init --recursive WHAM`

## Build the Image
1. `nvidia-smi` in terminal to find Cuda Version for GPU.
2. Find NVIDIA Cuda Toolkit Version at https://developer.nvidia.com/cuda-toolkit-archive
3. `cd cuda-miniconda`
4. `docker build --build-arg CUDA_VERSION=**CUDA_VERSION** -t cuda-miniconda:cuda-**CUDA_VERSION** .`

## Create and Run the Container
1. `docker volume create conda-envs`
2. From main repo directory: `docker run -it --gpus all --mount type=bind,src=./,dst=/mnt/4d-reconstruction-testing -v conda-envs:/opt/conda/envs cuda-miniconda:cuda-**CUDA_VERSION** /bin/bash`

## Run Existing Container
1. `docker start **CONTAINER_NAME_OR_ID**`
2. `docker exec -it **CONTAINER_NAME_OR_ID** /bin/bash`

## Set up Conda Environments
1. `cd /mnt/4d-reconstruction-testing`
2. For 4DAnyone: `./4danyone_init.sh` or GVHMR: `./gvhmr_init.sh`
3. For WHAM: supply your licensed `SMPL_NEUTRAL.pkl` at `WHAM/dataset/body_models/smpl/SMPL_NEUTRAL.pkl`, then run `bash wham_init.sh`. Alternatively: `bash wham_init.sh /path/inside/container/to/SMPL_NEUTRAL.pkl`.

## Run Inference
1. `conda activate **CONDA_ENV_NAME**`
2. For 4DAnyone: `./4danyone.sh` or GVHMR: `./gvhmr.sh`
3. For WHAM: `bash wham.sh video.mp4`, using a video path relative to `inputs`. The script activates its environment automatically.
4. WHAM results: `outputs/WHAM/<unique-run>/<video-name>/` on the host, containing `output.mp4` and `wham_output.pkl`.

## WHAM Notes
1. Requires a compatible NVIDIA GPU and driver. The licensed SMPL model is user-supplied; setup downloads public assets automatically.
2. WHAM uses pinned upstream source and compatibility patches. Exact versions are recorded in `wham-support/versions.txt`.
3. Optional: `bash wham.sh video.mp4 --no-visualize` skips rendering; `bash wham.sh video.mp4 --local-only` estimates local motion only.
