#!/usr/bin/env bash
set -euo pipefail
MAIN_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export WHAM_ROOT="$MAIN_PATH/WHAM"
export WHAM_SUPPORT="$MAIN_PATH/wham-support"
source "$WHAM_SUPPORT/versions.txt"
[[ $# -le 1 ]] || { echo 'Usage: bash wham_init.sh [path-to-licensed-SMPL_NEUTRAL.pkl]' >&2; exit 2; }
command -v conda >/dev/null || { echo 'Run inside the existing cuda-miniconda container.' >&2; exit 1; }
command -v git >/dev/null || { echo 'Git is required in the container.' >&2; exit 1; }
command -v ffmpeg >/dev/null || {
    [[ $EUID == 0 ]] || { echo 'Install ffmpeg, libgl1 and libglib2.0-0 in the container.' >&2; exit 1; }
    apt-get update
    apt-get install -y --no-install-recommends ffmpeg libgl1 libglib2.0-0
}

# The parent repo records the source revision as a real Git submodule gitlink.
git -C "$MAIN_PATH" submodule update --init WHAM
[[ "$(git -C "$WHAM_ROOT" rev-parse HEAD)" == "$WHAM_COMMIT" ]] || {
    echo "WHAM must be pinned to $WHAM_COMMIT in the parent repo. Apply the integration first." >&2
    exit 1
}
git -C "$WHAM_ROOT" submodule update --init --recursive
for entry in "third-party/DPVO:$DPVO_COMMIT" "third-party/ViTPose:$VITPOSE_COMMIT" "third-party/DPVO/Pangolin:$PANGOLIN_COMMIT"; do
    [[ "$(git -C "$WHAM_ROOT/${entry%%:*}" rev-parse HEAD)" == "${entry#*:}" ]] || { echo "Unexpected source revision: $entry" >&2; exit 1; }
done
mkdir -p "$WHAM_ROOT/dataset/body_models/smpl" "$WHAM_ROOT/checkpoints" "$MAIN_PATH/outputs/WHAM"
model="$WHAM_ROOT/dataset/body_models/smpl/SMPL_NEUTRAL.pkl"
if [[ $# -eq 1 ]]; then
    model_source="$(realpath -- "$1")"
    if [[ "$model_source" != "$model" ]]; then cp -- "$model_source" "$model"; fi
fi
[[ -s "$model" ]] || { echo "Place your licensed neutral SMPL model at $model, or pass its existing path to this script." >&2; exit 1; }

# Conda/compiler activation hooks may read unset variables. Keep errexit/pipefail,
# but suspend nounset while Conda manages the shell environment.
set +u
eval "$(conda shell.bash hook)"
if ! conda env list | grep -Eq '^wham[[:space:]]'; then
    conda create -y --override-channels --strict-channel-priority \
        -c nvidia/label/cuda-12.8.1 -c conda-forge -n wham \
        python=3.11.13 pip gcc_linux-64=11.4.0 gxx_linux-64=11.4.0 \
        gcc_impl_linux-64=11.4.0 gxx_impl_linux-64=11.4.0 \
        cuda-toolkit=12.8.1 cmake=3.31 ninja
fi
conda activate wham
set -u
source "$WHAM_SUPPORT/env.sh"
[[ "$(python -c 'import platform; print(platform.python_version())')" == "$PYTHON_VERSION" ]] || { echo 'Existing wham environment has the wrong Python version.' >&2; exit 1; }
[[ "$("$CC" -dumpfullversion)" == "$GCC_VERSION" && "$("$CXX" -dumpfullversion)" == "$GCC_VERSION" ]] || { echo 'Expected GCC/G++ 11.4.0 in the wham environment.' >&2; exit 1; }
"$CUDA_HOME/bin/nvcc" --version | grep -q 'release 12.8,' || { echo 'Expected the Conda CUDA 12.8 toolkit.' >&2; exit 1; }
python -m pip install pip==25.1.1 setuptools==75.8.0 wheel==0.45.1
python -m pip install torch==2.7.1 torchvision==0.22.1 torchaudio==2.7.1 --index-url https://download.pytorch.org/whl/cu128
export PIP_CONSTRAINT="$WHAM_SUPPORT/requirements.txt"
python -m pip install -r "$WHAM_SUPPORT/requirements.txt"
python -m pip install --no-build-isolation --no-deps \
    'chumpy @ git+https://github.com/mattloper/chumpy.git@580566eafc9ac68b2614b64d6f7aaa84eebb70da'
python -m pip install --no-build-isolation mmcv==1.3.9

apply_patch_once() {
    local directory="$1" patch_file="$2"
    if git -C "$directory" apply --check "$patch_file" 2>/dev/null; then
        git -C "$directory" apply "$patch_file"
    elif git -C "$directory" apply --reverse --check "$patch_file" 2>/dev/null; then
        echo "Already applied: $(basename -- "$patch_file")"
    else
        echo "Patch conflicts with local changes: $patch_file. No files were reset." >&2
        return 1
    fi
}
apply_patch_once "$WHAM_ROOT" "$WHAM_SUPPORT/patches/wham-modern.patch"
apply_patch_once "$WHAM_ROOT/third-party/DPVO" "$WHAM_SUPPORT/patches/dpvo-modern.patch"

python -m pip install --no-build-isolation --no-deps --no-binary=torch-scatter torch-scatter==2.1.2
eigen_dir="$WHAM_ROOT/third-party/DPVO/thirdparty"
if [[ ! -f "$eigen_dir/eigen-3.4.0/Eigen/Core" ]]; then
    archive="$(mktemp --suffix=.tar.gz)"
    trap 'rm -f -- "$archive"' EXIT
    curl -fL --retry 3 https://gitlab.com/libeigen/eigen/-/archive/3.4.0/eigen-3.4.0.tar.gz -o "$archive"
    mkdir -p "$eigen_dir"
    tar -xzf "$archive" -C "$eigen_dir"
    rm -f -- "$archive"
    trap - EXIT
fi
python -m pip install --no-build-isolation --no-deps "$WHAM_ROOT/third-party/DPVO"
pytorch3d="$WHAM_SUPPORT/src/pytorch3d"
if [[ ! -d "$pytorch3d/.git" ]]; then
    mkdir -p "$WHAM_SUPPORT/src"
    git init "$pytorch3d"
    git -C "$pytorch3d" remote add origin https://github.com/facebookresearch/pytorch3d.git
    git -C "$pytorch3d" fetch --depth 1 origin "$PYTORCH3D_COMMIT"
    git -C "$pytorch3d" checkout --detach FETCH_HEAD
fi
[[ "$(git -C "$pytorch3d" rev-parse HEAD)" == "$PYTORCH3D_COMMIT" ]] || { echo 'Existing PyTorch3D checkout has the wrong revision.' >&2; exit 1; }
python -m pip install --no-build-isolation --no-deps "$pytorch3d"
python -m pip check
cd -- "$WHAM_ROOT"
python "$WHAM_SUPPORT/download_assets.py"
python "$WHAM_SUPPORT/verify.py"
echo 'WHAM setup complete. Run: bash wham.sh path/relative/to/inputs/video.mp4'
