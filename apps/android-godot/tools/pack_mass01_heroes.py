#!/usr/bin/env python3
"""Pack MASS-01 generated art into Godot sprite folders + portraits."""
from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageOps

ROOT = Path("/workspace")
ART = Path("/opt/cursor/artifacts/assets")
SPRITES = ROOT / "apps/android-godot/assets/sprites"
PORTRAITS = ROOT / "apps/android-godot/assets/ui/portraits"
PROCESS = ROOT / "apps/android-godot/tools/process_hero_sprite.py"

HEROES = [
    "velkor",
    "tarvex",
    "xorin",
    "elvirax",
    "liorel",
    "firnax",
    "mossar",
    "zefriel",
]

# Heroes whose generated combat still faced LEFT — flop so on-disk source_facing=RIGHT.
FORCE_FLOP_RIGHT = {"mossar"}


def find_src(slug: str, kind: str) -> Path | None:
    for ext in (".jpg", ".png", ".jpeg", ".webp"):
        p = ART / f"{slug}_{kind}{ext}"
        if p.exists():
            return p
    return None


def run_process(src: Path, dst: Path, kind: str) -> None:
    subprocess.check_call(
        [sys.executable, str(PROCESS), "--src", str(src), "--dst", str(dst), "--kind", kind],
    )


def flop_rgba(path: Path) -> None:
    im = Image.open(path).convert("RGBA")
    ImageOps.mirror(im).save(path)


def main() -> None:
    for slug in HEROES:
        out_dir = SPRITES / slug
        out_dir.mkdir(parents=True, exist_ok=True)
        authored = out_dir / "_authored_right"
        authored.mkdir(exist_ok=True)

        # Portraits
        port = find_src(slug, "portrait")
        if port:
            run_process(port, PORTRAITS / f"{slug}.jpg", "portrait")

        # Combat keyframes
        mapping_src = {
            "idle": "idle",
            "attack": "attack",
            "walk": "walk",
            "hit": "hit",
            "ultimate": "ult",
        }
        processed: dict[str, Path] = {}
        for key, kind in mapping_src.items():
            src = find_src(slug, kind)
            if not src:
                print(f"WARN missing {slug}_{kind}")
                continue
            dst = authored / f"{key}.png"
            run_process(src, dst, "combat")
            if slug in FORCE_FLOP_RIGHT:
                flop_rgba(dst)
            processed[key] = dst

        if "idle" not in processed:
            raise SystemExit(f"No idle for {slug}")

        idle = processed["idle"]
        attack = processed.get("attack", idle)
        walk = processed.get("walk", idle)
        hit = processed.get("hit", idle)
        ult = processed.get("ultimate", attack)

        # Expand to Fighter._build_frames contract filenames
        copies = {
            "idle.png": idle,
            "walk_0.png": idle,
            "walk_1.png": walk,
            "walk_1b.png": walk,
            "walk_2.png": idle,
            "dash.png": walk,
            "attack.png": attack,
            "attack_0.png": idle,
            "attack_1.png": attack,
            "attack_1b.png": attack,
            "attack_2.png": attack,
            "attack_2b.png": ult,
            "attack_3.png": idle,
            "block.png": idle,
            "hit.png": hit,
            "stagger.png": hit,
            "ultimate_0.png": ult,
            "ultimate_1.png": attack,
            "ultimate_2.png": ult,
            "victory.png": ult,
            "personality.png": idle,
        }
        for name, src_path in copies.items():
            dst = out_dir / name
            if src_path.resolve() != dst.resolve():
                shutil.copy2(src_path, dst)
            authored_dst = authored / name
            if src_path.resolve() != authored_dst.resolve():
                shutil.copy2(src_path, authored_dst)

        print(f"PACKED {slug}: {len([p for p in out_dir.glob('*.png')])} frames")


if __name__ == "__main__":
    main()
