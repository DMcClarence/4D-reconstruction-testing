# 4D-reconstruction-testing

## Build the Image
1. `nvidia-smi` in terminal to find Cuda Version for GPU.
2. Find NVIDIA Cuda Toolkit Version at https://developer.nvidia.com/cuda-toolkit-archive
3. `docker build --build-arg CUDA_VERSION=[**CUDA_VERSION**] -t cuda-miniconda:[**CUDA_VERSION**] .`

## Create and Run the Container
1. `docker volume create conda-envs`
2. `docker run -it --gpus all -v conda-envs:/opt/conda/envs -v "${PWD}:/workspace" cuda-miniconda:[**CUDA_VERSION**] /bin/bash`

## Run Existing Container
1. `docker start [**CONTAINER_NAME_OR_ID**]`
2. `docker exec -it [**CONTAINER_NAME_OR_ID**] /bin/bash`
