# 4D-reconstruction-testing

## Clone the Repository
1. `git clone https://github.com/DMcClarence/4D-reconstruction-testing.git`
2. `cd 4D-reconstruction-testing`
3. `git submodule update --init GVHMR`
4. `git submodule update --init 4DAnyone`
5. `cd 4DAnyone`
6. `git submodule update --init third_party/GVHMR`
7. `cd ..`

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
