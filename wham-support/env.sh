#!/usr/bin/env bash
# Source after conda activate wham; affects only that shell/environment.
[[ -n "${CONDA_PREFIX:-}" ]] || { echo 'Activate the wham Conda environment first.' >&2; return 1; }
export CUDA_HOME="$CONDA_PREFIX"
export CC="$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-gcc"
export CXX="$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-g++"
export CUDAHOSTCXX="$CXX"
export CPATH="$CONDA_PREFIX/targets/x86_64-linux/include:$CONDA_PREFIX/include${CPATH:+:$CPATH}"
export LIBRARY_PATH="$CONDA_PREFIX/targets/x86_64-linux/lib:$CONDA_PREFIX/lib${LIBRARY_PATH:+:$LIBRARY_PATH}"
export LD_LIBRARY_PATH="$CONDA_PREFIX/targets/x86_64-linux/lib:$CONDA_PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export MAX_JOBS="${MAX_JOBS:-2}"
export TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST:-7.5;8.0;8.6;8.9;9.0;12.0+PTX}"
export FORCE_CUDA=1
export TORCH_FORCE_NO_WEIGHTS_ONLY_LOAD=1
export MPLBACKEND=Agg
export PYTHONUNBUFFERED=1
export PYTHONPATH="$WHAM_ROOT:$WHAM_ROOT/third-party/ViTPose:$WHAM_ROOT/third-party/DPVO:$WHAM_SUPPORT${PYTHONPATH:+:$PYTHONPATH}"
