#!/usr/bin/env python3
"""Process generated hero art into Godot combat sprites (480x512 RGBA).

- Flood-fill chroma (magenta preferred; also near-green/white corners)
- Fit character into 480x512 with feet near bottom
- Writes to apps/android-godot/assets/sprites/<slug>/
"""
from __future__ import annotations

import argparse
import os
from pathlib import Path

from PIL import Image

OUT_W, OUT_H = 480, 512
MAGENTA = (255, 0, 255)


def near(c, ref, tol=42):
    return all(abs(int(c[i]) - ref[i]) <= tol for i in range(3))


def is_chroma(px, mode="auto"):
    r, g, b, a = px
    if a < 8:
        return True
    if near((r, g, b), MAGENTA, 55):
        return True
    if mode in ("auto", "green") and g > 140 and g > r + 40 and g > b + 40:
        return True
    if mode in ("auto", "white") and r > 245 and g > 245 and b > 245:
        return True
    return False


def flood_chroma(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    visited = [[False] * h for _ in range(w)]
    stack = []
    for x in range(w):
        stack.append((x, 0))
        stack.append((x, h - 1))
    for y in range(h):
        stack.append((0, y))
        stack.append((w - 1, y))
    while stack:
        x, y = stack.pop()
        if x < 0 or y < 0 or x >= w or y >= h or visited[x][y]:
            continue
        visited[x][y] = True
        if not is_chroma(px[x, y]):
            continue
        px[x, y] = (0, 0, 0, 0)
        stack.extend([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)])
    return im


def bbox_opaque(im: Image.Image):
    a = im.split()[-1]
    return a.getbbox()


def fit_canvas(im: Image.Image) -> Image.Image:
    im = flood_chroma(im)
    box = bbox_opaque(im)
    if not box:
        canvas = Image.new("RGBA", (OUT_W, OUT_H), (0, 0, 0, 0))
        return canvas
    cropped = im.crop(box)
    cw, ch = cropped.size
    # Leave ~6% margin; bias feet to bottom
    scale = min((OUT_W * 0.90) / cw, (OUT_H * 0.92) / ch)
    nw, nh = max(1, int(cw * scale)), max(1, int(ch * scale))
    resized = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (OUT_W, OUT_H), (0, 0, 0, 0))
    x = (OUT_W - nw) // 2
    y = OUT_H - nh - int(OUT_H * 0.03)
    canvas.paste(resized, (x, y), resized)
    return canvas


def process_portrait(im: Image.Image, size=512) -> Image.Image:
    im = im.convert("RGB")
    # center-crop square
    w, h = im.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    im = im.crop((left, top, left + side, top + side))
    return im.resize((size, size), Image.Resampling.LANCZOS)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True)
    ap.add_argument("--dst", required=True)
    ap.add_argument("--kind", choices=["combat", "portrait", "fullbody"], default="combat")
    args = ap.parse_args()
    src = Path(args.src)
    dst = Path(args.dst)
    dst.parent.mkdir(parents=True, exist_ok=True)
    im = Image.open(src)
    if args.kind == "portrait":
        out = process_portrait(im)
        out.save(dst, quality=92)
    elif args.kind == "fullbody":
        out = im.convert("RGB")
        out.save(dst, quality=92)
    else:
        out = fit_canvas(im)
        out.save(dst)
    print(f"OK {args.kind}: {dst} {out.size}")


if __name__ == "__main__":
    main()
