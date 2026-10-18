#!/usr/bin/env bash
set -euo pipefail
MAIN_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export WHAM_ROOT="$MAIN_PATH/WHAM"
export WHAM_SUPPORT="$MAIN_PATH/wham-support"
[[ $# -ge 1 ]] || { echo 'Usage: bash wham.sh <video-relative-to-inputs> [--no-visualize] [--local-only]' >&2; exit 2; }
video="$1"
shift
visualize=true
local_only=false
for option in "$@"; do
    case "$option" in
        --no-visualize) visualize=false ;;
        --local-only) local_only=true ;;
        *) echo "Unknown option: $option" >&2; exit 2 ;;
    esac
done
if [[ "$video" != /* ]]; then
    if [[ -f "$MAIN_PATH/$video" ]]; then video="$MAIN_PATH/$video"; else video="$MAIN_PATH/inputs/$video"; fi
fi
[[ -f "$video" ]] || { echo "Video not found: $video" >&2; exit 1; }
video="$(realpath -- "$video")"
set +u
eval "$(conda shell.bash hook)"
conda activate wham
set -u
source "$WHAM_SUPPORT/env.sh"
cd -- "$WHAM_ROOT"
python "$WHAM_SUPPORT/check_assets.py"
OUTPUTS_PATH="$MAIN_PATH/outputs/WHAM/$(date +%Y%m%d-%H%M%S)-$$-$RANDOM"
mkdir -p "$OUTPUTS_PATH"
args=(--video "$video" --output_pth "$OUTPUTS_PATH" --save_pkl)
if [[ "$visualize" == true ]]; then args+=(--visualize); fi
if [[ "$local_only" == true ]]; then args+=(--estimate_local_only); fi
python demo.py "${args[@]}"
echo "Results: $OUTPUTS_PATH"
