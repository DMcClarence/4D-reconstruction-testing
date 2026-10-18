"""Check the pinned stack, native extensions, GPU execution, and WHAM assets."""
import argparse
import importlib
import os
import platform
from pathlib import Path
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", action="store_true", help="Skip GPU and mounted assets")
    args = parser.parse_args()
    import torch
    import numpy as np
    import cv2
    expected = {"Python": (platform.python_version(), "3.11.13"),
                "PyTorch": (torch.__version__, "2.7.1+cu128"),
                "CUDA": (torch.version.cuda, "12.8"),
                "NumPy": (np.__version__, "1.26.4"),
                "OpenCV": (cv2.__version__, "4.10.0")}
    for name, (actual, required) in expected.items():
        if actual != required:
            raise RuntimeError(f"{name}: expected {required}, got {actual}")
        print(f"{name}: {actual}")
    for compiler in (os.environ["CC"], os.environ["CXX"]):
        actual = subprocess.check_output([compiler, "-dumpfullversion"], text=True).strip()
        if actual != "11.4.0":
            raise RuntimeError(f"Unexpected {compiler}: {actual}")
    for module in ("cuda_corr", "cuda_ba", "lietorch_backends", "torch_scatter",
                   "pytorch3d._C", "mmpose", "mmcv", "chumpy"):
        importlib.import_module(module)
        print(f"Import OK: {module}")
    if args.build:
        return
    if not torch.cuda.is_available():
        raise RuntimeError("Docker cannot access an NVIDIA GPU. Check Docker/WSL GPU support.")
    capability = torch.cuda.get_device_capability()
    print(f"GPU: {torch.cuda.get_device_name()} (compute {capability[0]}.{capability[1]})")
    if capability < (7, 5):
        raise RuntimeError("Default build requires compute capability 7.5 or newer.")
    from torch_scatter import scatter_sum
    source = torch.ones(4, device="cuda")
    result = scatter_sum(source, torch.zeros(4, device="cuda", dtype=torch.long))
    if result.item() != 4:
        raise RuntimeError("torch-scatter GPU kernel returned an unexpected result")
    from pytorch3d.ops import knn_points
    points = torch.zeros(1, 2, 3, device="cuda")
    knn_points(points, points, K=1)
    from dpvo.lietorch import SE3
    SE3.Identity(1, device="cuda").inv()
    from lib.vis.renderer import Renderer
    from lib.models.preproc.slam import SLAMModel
    from lib.models.preproc.extractor import FeatureExtractor
    from download_assets import CHECKPOINTS, REQUIRED_AUXILIARY
    for filename in CHECKPOINTS:
        path = Path(os.environ["WHAM_ROOT"]) / "checkpoints" / filename
        if not path.is_file() or path.stat().st_size < 1024:
            raise RuntimeError(f"Missing checkpoint: {path}. Run setup.ps1.")
    for filename in (*REQUIRED_AUXILIARY, "smpl/SMPL_NEUTRAL.pkl"):
        path = Path(os.environ["WHAM_ROOT"]) / "dataset/body_models" / filename
        if not path.is_file() or path.stat().st_size < 1024:
            raise RuntimeError(f"Missing body model asset: {path}. Run setup.ps1.")
    from configs.config import get_cfg_defaults
    from lib.models import build_body_model, build_network
    cfg = get_cfg_defaults()
    cfg.merge_from_file("configs/yamls/demo.yaml")
    smpl = build_body_model(cfg.DEVICE)
    if smpl.get_num_verts() != 6890:
        raise RuntimeError("Unexpected SMPL vertex count")
    build_network(cfg, smpl).eval()
    torch.cuda.synchronize()
    print("GPU kernels, SMPL (6,890 vertices), and WHAM checkpoint verified.")


if __name__ == "__main__":
    main()
