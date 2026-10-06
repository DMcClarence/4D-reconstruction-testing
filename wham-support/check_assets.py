"""Stop before inference if setup has not provided the required model files."""
import os
from pathlib import Path
from download_assets import CHECKPOINTS, REQUIRED_AUXILIARY

root = Path(os.environ["WHAM_ROOT"])
required = [root / "checkpoints" / name for name in CHECKPOINTS]
required += [root / "dataset/body_models" / name
             for name in (*REQUIRED_AUXILIARY, "smpl/SMPL_NEUTRAL.pkl")]
missing = [str(path) for path in required if not path.is_file() or path.stat().st_size < 1024]
if missing:
    raise SystemExit("Run wham_init.sh first. Missing assets: " + ", ".join(missing))
