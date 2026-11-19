#!/usr/bin/env python3
"""Pack MASS-02 generated art into Godot sprite folders + portraits."""
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
    "morvex",
    "grimzor",
    "draxel",
    "vespira",
    "aurix",
    "selestra",
    "voltario",
    "orionex",
]

# Generated combat that kept facing LEFT — flop so on-disk source_facing=RIGHT.
FORCE_FLOP_RIGHT = {"grimzor", "draxel", "orionex"}


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


def flood_magenta(path: Path) -> None:
    MAGENTA = (255, 0, 255)

    def near(c, ref, tol=55):
        return all(abs(int(c[i]) - ref[i]) <= tol for i in range(3))

    im = Image.open(path).convert("RGBA")
    w, h = im.size
    px = im.load()
    vis = [[False] * h for _ in range(w)]
    stack = []
    for x in range(w):
        stack += [(x, 0), (x, h - 1)]
    for y in range(h):
        stack += [(0, y), (w - 1, y)]
    while stack:
        x, y = stack.pop()
        if x < 0 or y < 0 or x >= w or y >= h or vis[x][y]:
            continue
        vis[x][y] = True
        r, g, b, a = px[x, y]
        if a < 8 or near((r, g, b), MAGENTA) or (g > 140 and g > r + 40 and g > b + 40):
            px[x, y] = (0, 0, 0, 0)
            stack += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    im.save(path)


def main() -> None:
    for slug in HEROES:
        out_dir = SPRITES / slug
        out_dir.mkdir(parents=True, exist_ok=True)
        authored = out_dir / "_authored_right"
        authored.mkdir(exist_ok=True)

        port = find_src(slug, "portrait")
        if port:
            run_process(port, PORTRAITS / f"{slug}.jpg", "portrait")

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
            flood_magenta(dst)
            processed[key] = dst

        if "idle" not in processed:
            raise SystemExit(f"No idle for {slug}")

        idle = processed["idle"]
        attack = processed.get("attack", idle)
        walk = processed.get("walk", idle)
        hit = processed.get("hit", idle)
        ult = processed.get("ultimate", attack)

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

        print(f"PACKED {slug}: {len(list(out_dir.glob('*.png')))} frames")


if __name__ == "__main__":
    main()
