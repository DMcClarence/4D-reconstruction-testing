"""Fetch public files from the pinned WHAM fetch_demo_data.sh; never fetch SMPL."""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import tarfile
import tempfile
import time

CHECKPOINTS = {
    "wham_vit_bedlam_w_3dpw.pth.tar": "19qkI-a6xuwob9_RFNSPWf1yWErwVVlks",
    "hmr2a.ckpt": "1J6l8teyZrL0zFzHhzkC7efRhU0ZJ5G9Y",
    "dpvo.pth": "1kXTV4EYb-BI3H7J-bkR3Bc4gT9zfnHGT",
    "yolov8x.pt": "1zJ0KP23tXD42D47cw1Gs7zE2BA_V_ERo",
    "vitpose-h-multi-coco.pth": "1xyF7F3I7lWtdq82xmEPVQ5zl4HaasBso",
}
AUXILIARY_ID = "1pbmzRbWGgae6noDIyQOnohzaVnX_csUZ"
REQUIRED_AUXILIARY = (
    "J_regressor_wham.npy", "J_regressor_h36m.npy", "J_regressor_feet.npy",
    "smpl_mean_params.npz", "coco_aug_dict.pth",
)


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def download(file_id, target):
    import gdown
    temporary = target.with_name(target.name + ".part")
    for attempt in range(3):
        try:
            result = gdown.download(id=file_id, output=str(temporary), quiet=False)
            if not result or temporary.stat().st_size < 1024:
                raise RuntimeError("Empty or incomplete download")
            with temporary.open("rb") as stream:
                head = stream.read(512).lower().lstrip()
            if head.startswith((b"<!doctype html", b"<html")):
                raise RuntimeError("Google Drive returned an HTML page instead of an asset")
            temporary.replace(target)
            return
        except Exception:
            if attempt == 2:
                raise
            time.sleep(2 ** attempt)


def extract_auxiliary(archive, target):
    """Accept only regular auxiliary files under body_models, excluding SMPL."""
    with tarfile.open(archive, "r:gz") as bundle:
        for member in bundle.getmembers():
            parts = PurePosixPath(member.name).parts
            if not parts or parts[0] != "body_models" or ".." in parts:
                raise ValueError(f"Unexpected auxiliary archive path: {member.name}")
            if member.issym() or member.islnk() or member.isdev():
                raise ValueError(f"Unsupported auxiliary archive member: {member.name}")
            relative = parts[1:]
            if not relative or relative[0].lower() == "smpl" or member.isdir():
                continue
            if not member.isfile():
                raise ValueError(f"Unsupported archive member: {member.name}")
            destination = target.joinpath(*relative)
            destination.parent.mkdir(parents=True, exist_ok=True)
            with bundle.extractfile(member) as source, destination.open("wb") as out:
                shutil.copyfileobj(source, out)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--refresh", action="store_true")
    args = parser.parse_args()
    root = Path(os.environ["WHAM_ROOT"])
    checkpoint_dir = root / "checkpoints"
    body_dir = root / "dataset/body_models"
    checkpoint_dir.mkdir(parents=True, exist_ok=True)
    body_dir.mkdir(parents=True, exist_ok=True)
    manifest_path = checkpoint_dir / "public-assets.sha256.json"
    previous = json.loads(manifest_path.read_text()) if manifest_path.exists() else {}
    for name, file_id in CHECKPOINTS.items():
        target = checkpoint_dir / name
        cached = target.is_file() and target.stat().st_size > 1024
        expected = previous.get(name)
        if cached and expected and sha256(target) != expected:
            cached = False
        if args.refresh or not cached:
            download(file_id, target)
    ready = body_dir / ".public-auxiliary.sha256.json"
    auxiliary_valid = ready.exists() and all((body_dir / name).is_file() for name in REQUIRED_AUXILIARY)
    if auxiliary_valid:
        auxiliary_valid = all((body_dir / name).is_file() and sha256(body_dir / name) == digest
                              for name, digest in json.loads(ready.read_text()).items())
    if args.refresh or not auxiliary_valid:
        with tempfile.TemporaryDirectory() as scratch:
            archive = Path(scratch) / "body_models.tar.gz"
            download(AUXILIARY_ID, archive)
            extracted = Path(scratch) / "extracted"
            extracted.mkdir()
            extract_auxiliary(archive, extracted)
            missing = [name for name in REQUIRED_AUXILIARY if not (extracted / name).is_file()]
            if missing:
                raise RuntimeError(f"Auxiliary bundle is missing: {missing}")
            hashes = {}
            for source in extracted.rglob("*"):
                if source.is_file():
                    relative = source.relative_to(extracted)
                    destination = body_dir / relative
                    destination.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(source, destination)
                    hashes[relative.as_posix()] = sha256(destination)
            ready.write_text(json.dumps(hashes, indent=2) + "\n")
    manifest_path.write_text(json.dumps({name: sha256(checkpoint_dir / name)
                                        for name in CHECKPOINTS}, indent=2) + "\n")
    print("Public assets ready. SMPL remains user-supplied.")


if __name__ == "__main__":
    main()
