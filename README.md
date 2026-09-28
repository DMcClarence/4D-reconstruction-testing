# 4D-reconstruction-testing

## Clone the Repository
1. `git clone https://github.com/DMcClarence/4D-reconstruction-testing.git`
2. `cd 4D-reconstruction-testing`
3. `git submodule init --recursive 4DAnyone`
4. `git submodule init GVHMR`
5. `git submodule init MocapAnything`

## Build the Image
1. `nvidia-smi` in terminal to find Cuda Version for GPU.
2. Find NVIDIA Cuda Toolkit Version at https://developer.nvidia.com/cuda-toolkit-archive
3. `cd cuda-miniconda`
4. `docker build --build-arg CUDA_VERSION=[**CUDA_VERSION**] -t cuda-miniconda:[**CUDA_VERSION**] .`

## Create and Run the Container
1. `docker volume create conda-envs`
2. `docker run -it --gpus all --mount type=bind,source=../4DAnyone,target=/mnt/4DAnyone --mount type=bind,source=../GVHMR,target=/mnt/GVHMR --mount type=bind,source=../MocapAnything,target=/mnt/MocapAnything -v conda-envs:/opt/conda/envs -v "${PWD}:/workspace" cuda-miniconda:[**CUDA_VERSION**] /bin/bash`

## Run Existing Container
1. `docker start [**CONTAINER_NAME_OR_ID**]`
2. `docker exec -it [**CONTAINER_NAME_OR_ID**] /bin/bash`
